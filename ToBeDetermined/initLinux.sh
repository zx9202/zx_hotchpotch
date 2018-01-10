#!/bin/sh
########################################################len=64##
UserName="u1"
UserPassword="u1pwd"
GidGroup=""
UserdelPermission=1  # 如果用户存在,允许删除这个用户.
SshPorts="22 22222"  # 所有想开启的SSH端口,以空格间隔.
ZoneInfoFilePath="/usr/share/zoneinfo/Asia/Shanghai"
################################################################

# 检查依赖和其他条件(无依赖).
CheckDependenciesAndSoOn()
{
    local checkVal=0

    if [[ $EUID -ne 0 ]]; then checkVal=1; echo "need root privileges" 1>&2; fi

    visudo --version >/dev/null 2>&1
    if [ $? -ne 0 ]; then checkVal=1; echo "please install sudo"; fi

    return ${checkVal}
}

# 增加一个用户,并且更新这个用户的密码(无依赖).
AddUserAndUpdatePassword()
{
    local functionName="AddUserAndUpdatePassword"
    echo "========================================"
    echo "=> ${functionName}, begin..."

    local userName="$1"
    local userPassword="$2"
    local gidGroup="$3"
    local userdelPermission="$4"
    
    if [ -z "${userName}" ] || [ -z "${userPassword}" ]; then
        echo "userName(${userName}) and/or userPassword(${userPassword}) is empty, will terminate."
        return 1
    fi
    
    id ${userName} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "userName(${userName}) already exists."
        if [ ! "${userdelPermission}" -eq 1 ]; then
            echo "have no permission to delete userName, will terminate."
            return 1
        fi
        
        userdel -r ${userName}
        if [ $? -ne 0 ]; then
            echo "userName(${userName}) was deleted failed. will terminate."
            return 1
        else
            echo "userName(${userName}) was deleted successfully."
        fi
    fi
    
    local cmd=
    if [ -n "${gidGroup}" ]; then    # 执行"man test"可知, -n STRING  the length of STRING is nonzero
        cmd="useradd ${userName} -g ${gidGroup}"
    else
        cmd="useradd ${userName}"
    fi
    ${cmd}
    if [ $? -ne 0 ]; then
        echo "cmd=(${cmd}) failed, will terminate."
        return 1
    fi
    
    echo "${userPassword}" | passwd --stdin ${userName} > /dev/null
    if [ $? -ne 0 ]; then
        echo "update userName(${userName})'s password fail. will terminate."
        return 1
    fi
    echo "SUCCESS. userName(${userName}), gidGroup(${gidGroup}), userdelPermission(${userdelPermission})."

    echo "=> ${functionName}, end."
    return 0
}

# 用visudo校验sudoers的合法性(无依赖).
VisudoCheck()
{
    # 执行"man visudo"然后在"FILES"部分可以看到它涉及的文件.
    visudo -c > /dev/null 2>&1
    if [ $? -ne 0 ]; then return 1; fi

    # 将校验结果转成小写的字符串,然后检索字符串.
    # 找不到"error",找不到"warn",并且能找到"parsed OK",就认为校验绝对成功.
    local msgLowercase=
    declare -l msgLowercase  # 转小写,只需要将变量名字"declare -l"/"typeset -l"后,再给变量赋值,变量的内容即为小写.
    local msgOrigin=$(visudo -c 2>&1)
    msgLowercase=${msgOrigin}
    
    expr match "${msgLowercase}" "^.*error.*$"     > /dev/null
    if [ $? -eq 0 ]; then return 2; fi
    
    expr match "${msgLowercase}" "^.*warn.*$"      > /dev/null
    if [ $? -eq 0 ]; then return 3; fi
    
    expr match "${msgOrigin}"    "^.*parsed OK$"   > /dev/null
    if [ $? -ne 0 ]; then return 4; fi
    
    return 0
}

# 给一个用户增加最高的sudo权限(依赖其他函数).
AddSudoPermission()
{
    local functionName="AddSudoPermission"
    echo "========================================"
    echo "=> ${functionName}, begin..."
    
    local userName="$1"

    local fileName="/etc/sudoers"
    local rootExactPattern='^[ \t]*root[ \t]+ALL=\(ALL\)[ \t]+ALL[ \t]*$'
    local userExactPattern="^[ \t]*${userName}[ \t]+ALL=\(ALL\)[ \t]+ALL[ \t]*$"
    local userFuzzyPattern="^[ \t]*${userName}[ \t]+.*$"
    local newLineWilAppend="${userName}\tALL=(ALL)\tALL"
    
    # TODO: visudo校验的文件如果和输入的文件名不是同一个文件,就太搞笑了.
    VisudoCheck
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi
    
    # TODO: 如果sed命令直接失败的话,我们是不知道的,此时返回的结果仅仅是wc命令的结果.
    local  cntRoot=$(sed -n -r "s/${rootExactPattern}/&/p" "${fileName}" | wc -l)
    if [ ${cntRoot} -ne 1 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi
    
    # 模糊匹配只有可能比精确匹配多,如果多了,说明此文件可能被高度自定义,这个时候就不要用脚本修改啦.
    local cntExact=$(sed -n -r  "/${userExactPattern}/p"   "${fileName}" | wc -l)
    local cntFuzzy=$(sed -n -r  "/${userFuzzyPattern}/p"   "${fileName}" | wc -l)
    if [ ${cntExact} -ne ${cntFuzzy} ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    chmod u+w "${fileName}"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    sed -i -r -e "/${userExactPattern}/d" -e "/${rootExactPattern}/a ${newLineWilAppend}"  "${fileName}"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    chmod u-w "${fileName}"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    VisudoCheck
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    echo "=> ${functionName}, end"
    return 0
}

# 修改sshd配置文件(无依赖).
ModifySshdConfig()
{
    local functionName="ModifySshdConfig"
    echo "========================================"
    echo "=> ${functionName}, begin..."

    local sshPorts="$1"

    local fileName="/etc/ssh/sshd_config"
    if [ ! -f ${fileName} ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    # 不允许root用户远程登录.
    local srcPermitRootLogin="^[# \t]*PermitRootLogin[ \t]+(yes|no)[ \t#]*.*$"
    local dstPermitRootLogin="PermitRootLogin no"
    sed -i -r "/${srcPermitRootLogin}/{x;//D;g;s//${dstPermitRootLogin}/g}"  "${fileName}"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    # 单次连接的最大尝试次数
    local srcMaxAuthTries="^[# \t]*MaxAuthTries[ \t]+[0-9]+[ \t#]*.*$"
    local dstMaxAuthTries="MaxAuthTries 6"
    sed -i -r "/${srcMaxAuthTries}/{x;//D;g;s//${dstMaxAuthTries}/g}"  "${fileName}"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    # 设置ssh端口
    if [ -n "${sshPorts}" ]; then
        local srcStrPort="^[# \t]*Port[ \t]+[0-9]+[ \t#]*.*$"
        local dstStrPort=""
        local portArr=(${sshPorts})
        local portNum=
        for portNum in ${portArr[@]}; do
            if [ -z "${dstStrPort}" ]; then 
                dstStrPort="Port ${portNum}"
            else
                dstStrPort="${dstStrPort}\nPort ${portNum}"
            fi
        done

        sed -i -r "/${srcStrPort}/{x;//D;g;s//${dstStrPort}/g}"  "${fileName}"
        if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

        echo -e "\033[49;27m #################### \033[0m"
        echo -e "\033[49;27m # Modified SSH port(${portArr[@]}) \033[0m"
        echo -e "\033[49;27m # You may need add Firewall Policy: \033[0m"
        echo -e "\033[46;31m # iptables -I INPUT -p tcp --dport 22 -j ACCEPT \033[0m"
        echo -e "\033[46;31m # service iptables save \033[0m"
        echo -e "\033[49;27m #################### \033[0m"
    fi

    service sshd restart
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi

    echo "=> ${functionName}, end."
    return 0
}

# 修改时区(无依赖).
ChangeTimeZone()
{
    local functionName="ChangeTimeZone"
    echo "========================================"
    echo "=> ${functionName}, begin..."

    local zoneInfoFilePath="$1"
    # cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    \cp -p -f "${zoneInfoFilePath}" "/etc/localtime"
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}" 1>&2; return 1; fi
    
    echo "=> ${functionName}, end."
    return 0
}

################################################################

if [ "${UserName}" = "u1" ]; then
    echo    "[WARN] Perhaps the current configuration is the default configuration."
    echo    "[WARN] configuration: ${UserName}, ${UserPassword}, ${GidGroup}, ${UserdelPermission}, ${SshPorts}"
    read -p "[WARN] press [Y] to continue: "  inputData
    if [ "${inputData}" != 'Y' ] && [ "${inputData}" != 'y' ]; then
        echo "INPUT FAULT. will exit."
        exit 1
    fi
fi

CheckDependenciesAndSoOn
[ $? -eq 0 ] && AddUserAndUpdatePassword "${UserName}" "${UserPassword}" "${GidGroup}" "${UserdelPermission}"
[ $? -eq 0 ] && AddSudoPermission "${UserName}"
[ $? -eq 0 ] && ModifySshdConfig  "${SshPorts}"
[ $? -eq 0 ] && ChangeTimeZone "${ZoneInfoFilePath}"

################################################################
