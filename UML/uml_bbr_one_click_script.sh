#! /bin/bash
#======================================================================#
# 注意: 脚本需要以 UTF-8 编码, 并以 LF 结尾.
#======================================================================#
IFNAME="uml-tap"
IFADDR="192.168.255.1/24"
DEST_PORT="65500:65535"
DEST_ADDR="192.168.255.254"

APP_DIR="/root/UML_BBR_DIR"
SCREEN_NAME="uml_bbr_zx"



function fun_check(){
    wget --help  > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[ERROR]:${LINENO}, Please install wget software." 1>&2
        exit 1
    fi
    
    screen --help  > /dev/null 2>&1
    if [ $? -ne 1 ]; then
        echo "[ERROR]:${LINENO}, Please install screen software." 1>&2
        exit 1
    fi
    
    if [[ $EUID -ne 0 ]]; then
        echo "[ERROR]:${LINENO}, You must run the script with root privileges." 1>&2
        exit 1
    fi
}


function fun_stop() {
    echo "action [stop] BEG..."
    for NUM in $(pidof vmlinux); do kill -9 ${NUM}; done
    echo "action [stop] END."
    return 0
}


function fun_status(){
    screen -r $(screen -list | grep "${SCREEN_NAME}" | awk 'NR==1{print $1}')
}


function fun_start() {
    echo "action [start] BEG..."
    
    local APPLICATION_PATH="${APP_DIR}/vmlinux"        # APP的全路径
    local UML_BLOCK_DEVICE="${APP_DIR}/alpine_file"    # UML要使用的块设备
    local UML_CTRL_MEM_AMT="64M"                       # UML控制的物理内存
    # screen是一款虚拟终端软件. ( -dmS name     Start as daemon: Screen session in detached mode. )
    # "mem=128M" will give the UML 128 megabytes of "physical" memory. (将给 UML 128M 的"物理"内存)
    screen -dmS ${SCREEN_NAME} ${APPLICATION_PATH} ubda=${UML_BLOCK_DEVICE} rw eth0=tuntap,${IFNAME} mem=${UML_CTRL_MEM_AMT} con=pts con1=fd:0,fd:1
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    echo "action [start] END."
    return 0
}


function fun_uninstall(){
    echo "action [uninstall] BEG..."
    
    ip addr show ${IFNAME} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        ip tuntap del ${IFNAME} mode tap
        if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    fi
    
    ip addr show ${IFNAME} > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    if [ -d "${APP_DIR}" ]; then
        rm -rf ${APP_DIR}
        if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    fi
    
    D_I=$(ip route show exact 0/0 | sort -k 7 | head -n 1 | sed -n 's/^default.* dev \([^ ]*\).*/\1/p')
    if [ "${D_I}" == "" ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    iptables --delete FORWARD  --in-interface ${IFNAME} --jump ACCEPT
    iptables --delete FORWARD --out-interface ${IFNAME} --jump ACCEPT
    iptables --table nat --delete POSTROUTING --out-interface ${D_I} --jump MASQUERADE
    iptables --table nat --delete  PREROUTING  --in-interface ${D_I} --protocol tcp --dport ${DEST_PORT} --jump DNAT --to-destination ${DEST_ADDR}
    iptables --table nat --delete  PREROUTING  --in-interface ${D_I} --protocol udp --dport ${DEST_PORT} --jump DNAT --to-destination ${DEST_ADDR}
    
    echo "action [uninstall] END."
    return 0
}


function fun_install() {
    echo "action [install] BEG..."
    
    mkdir -p ${APP_DIR}
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    wget --directory-prefix=${APP_DIR} https://raw.githubusercontent.com/zx9202/zx_hotchpotch/master/UML/vmlinux.tar.xz      > /dev/null 2>&1
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    wget --directory-prefix=${APP_DIR} https://raw.githubusercontent.com/zx9202/zx_hotchpotch/master/UML/alpine_file.tar.xz  > /dev/null 2>&1
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    cd ${APP_DIR}
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    tar -xf vmlinux.tar.xz
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    tar -xf alpine_file.tar.xz
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # 猜测(未验证): 如果你的电脑是双网卡, 每个网卡都接入了网线, 都分配了IP地址, 那么应该会有两个default的路由.
    # 猜测: 找到默认路由的名字 (D_I => DefaultInterface ?) (0/0 => 0.0.0.0/0 ?)
    D_I=$(ip route show exact 0/0 | sort -k 7 | head -n 1 | sed -n 's/^default.* dev \([^ ]*\).*/\1/p')
    if [ "${D_I}" == "" ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # 增加一个名为${IFNAME}的模式为"tap"的设备
    ip tuntap add ${IFNAME} mode tap
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # 给名为${IFNAME}的设备设置一个IP地址
    ip address add ${IFADDR} dev ${IFNAME}
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # 启动名为${IFNAME}的设备
    ip link set ${IFNAME} up
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # 动态修改内核运行参数,允许数据包转发(等同于  echo 1 > /proc/sys/net/ipv4/ip_forward )
    sysctl -w net.ipv4.ip_forward=1  > /dev/null
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    # (表名)NAT:地址转换,用于网关路由器
    # (规则链)FORWARD:处理转发数据包
    # (规则链)POSTROUTING:用于源地址转换(SNAT)
    # (规则链) PREROUTING:用于目标地址转换(DNAT)
    # (动作)ACCEPT:接收数据包
    # (动作)MASQUERADE:IP伪装(NAT),用于ADSL
    # (动作)DNAT:目标地址转换
    iptables --policy FORWARD ACCEPT
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    iptables --insert FORWARD  --in-interface ${IFNAME} --jump ACCEPT
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    iptables --insert FORWARD --out-interface ${IFNAME} --jump ACCEPT
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    iptables --table nat --append POSTROUTING --out-interface ${D_I} --jump MASQUERADE
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    iptables --table nat --append  PREROUTING  --in-interface ${D_I} --protocol tcp --dport ${DEST_PORT} --jump DNAT --to-destination ${DEST_ADDR}
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    iptables --table nat --append  PREROUTING  --in-interface ${D_I} --protocol udp --dport ${DEST_PORT} --jump DNAT --to-destination ${DEST_ADDR}
    if [ $? -ne 0 ]; then echo "[ERROR]:${LINENO}"; return 1; fi
    
    echo "action [install] END."
    return 0
}


function func_run() {
    local   program=$1
    local   command=$2
    case "${command}" in
    'start')
        fun_stop  &&  fun_start
        ;;
    'stop')
        fun_stop
        ;;
    'restart')
        fun_stop  &&  fun_start
        ;;
    'status')
        fun_status
        ;;
    'install')
        fun_stop  &&  fun_uninstall  &&  fun_install
        ;;
    'uninstall')
        fun_stop  &&  fun_uninstall
        ;;
    'reinstall')
        fun_stop  &&  fun_uninstall  &&  fun_install
        ;;
    *)
        echo "Usage: ${program} { start | stop | restart | status | install | uninstall | reinstall }"
        ;;
    esac
}


fun_check
func_run $0 $1

retval=$?
echo "execute [$1] with retval=${retval}"
exit ${retval}
