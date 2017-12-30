#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS ubuntu Debian                                    #
#   Description: One click Install lkl                #
#   原Author: 91yun <https://twitter.com/91yun>                     #
#   原Thanks: @allient neko                               #
#   原Intro:  https://www.91yun.org                                 #
#   我拷贝了一份脚本, 加点注释, 学习一下.
#=================================================================#


if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi


Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        release='CentOS'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        release='Debian'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        release='Ubuntu'
	else
        release='unknow'
    fi
    
}
Get_Dist_Name


function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}
ver=""
CentOSversion() {
    if [ "${release}" == "CentOS" ]; then
        local version="$(getversion)"
        local main_ver=${version%%.*}
		ver=$main_ver
    else
        ver="$(getversion)"
    fi
}
CentOSversion


Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        bit='x64'
    else
        bit='x32'
    fi
}
Get_OS_Bit


if [ "${release}" == "CentOS" ]; then
	yum install -y bc
else
	apt-get update
	apt-get install -y bc
fi


iddver=`ldd --version | grep ldd | awk '{print $NF}'`
dver=$(echo "$iddver < 2.14" | bc)
if [ $dver -eq 1 ]; then
	ldd --version
	echo "idd的版本低于2.14，系统不支持。请尝试Centos7，Debian8，Ubuntu16"
	exit 1
fi


if [ "$bit" -ne "x64" ]; then
	echo "脚本目前只支持64bit系统"
	exit 1
fi	


if [ "${release}" == "CentOS" ]; then
	yum install -y haproxy
elif [[ "${release}" == "Debian" && "$ver" == "7" ]]; then
	echo "deb http://ftp.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
	apt-get install debian-archive-keyring
	apt-key update
	apt-get update
	apt-get install -y haproxy
else
	apt-get update
	apt-get install -y haproxy
fi




mkdir /root/lkl
cd /root/lkl

cat > /root/lkl/haproxy.cfg<<-EOF
#=================================================================#
# 你可以去 http://www.haproxy.org/ 找它的文档.下面是一个(可能)可用的文档链接:
# https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#2
# 下面是一个偶然看到的第三方中文文档
# http://www.ttlsa.com/linux/haproxy-study-tutorial/
#=================================================================#



# 全局(global)部分
global



# 默认(defaults)部分
defaults

# 设置本实例的日志记录参数,使其与全局日志参数相同.
log global

# 实例将以纯TCP的模式进行工作,客户端和服务器之间将建立全双工连接,而且不会进行第7层面的检查,这是默认模式.
mode tcp

# 禁用空连接的日志记录.
option dontlognull

# 客户端连接到服务器端的超时时长(ms毫秒).
timeout connect 5000

# 设置客户端的最长不活动时间(ms毫秒).
timeout client 50000

# 设置服务器的最长不活动时间(ms毫秒).
timeout server 50000



# 前端(frontend)部分描述了一组监听socket,这些监听socket用于接受客户端的连接.
frontend proxy-in

# 在前端定义一个或多个监听地址和/或端口.
bind *:9000-9999

# 当"use_backend"规则找不到匹配的时候,指定要使用的后端.
default_backend proxy-out



# 后端(backend)部分描述了一组服务器,代理将会将对应客户端的请求转发至这些服务器.
backend proxy-out

# 在后端指定一个server,语法如下所示:
# server <name> <address>[:[port]] [param*]
server server1 10.0.0.1 maxconn 20480

EOF




# 目前(2017-12-30)文件还是91yun的, 我计划后面自己编译一个倒腾一下, 该计划尚未实施.
wget --no-check-certificate https://raw.githubusercontent.com/zx9202/zx_hotchpotch/master/LKL/liblkl-hijack.so

# LKL hijack library 的老式的、环境变量方式的配置
cat > /root/lkl/lkl.sh<<-EOF
LD_PRELOAD=/root/lkl/liblkl-hijack.so \
LKL_HIJACK_NET_QDISC="root|fq" \
LKL_HIJACK_SYSCTL="net.ipv4.tcp_congestion_control=bbr;net.ipv4.tcp_wmem=4096 16384 30000000" \
LKL_HIJACK_OFFLOAD="0x9983" \
LKL_HIJACK_NET_IFTYPE=tap \
LKL_HIJACK_NET_IFPARAMS=lkl-tap \
LKL_HIJACK_NET_IP=10.0.0.2 \
LKL_HIJACK_NET_NETMASK_LEN=24 \
LKL_HIJACK_NET_GATEWAY=10.0.0.1 \
haproxy -f /root/lkl/haproxy.cfg
EOF
# 我试图将其修改为 LKL hijack library 的新式的、json文件方式的配置，然后失败了，猜测为 liblkl-hijack.so 可能是定制的。




cat > /root/lkl/run.sh<<-EOF
# 增加一个名为lkl-tap的模式为tap的设备
ip tuntap add lkl-tap mode tap

# 给名为lkl-tap的设备设置一个IP地址
ip addr add 10.0.0.1/24 dev lkl-tap

# 启动名为lkl-tap的设备
ip link set lkl-tap up

# 动态修改内核运行参数,允许数据包转发
sysctl -w net.ipv4.ip_forward=1

# (表名)NAT:地址转换,用于网关路由器
# (规则链)FORWARD:处理转发数据包
# (规则链)POSTROUTING:用于源地址转换(SNAT)
# (规则链) PREROUTING:用于目标地址转换(DNAT)
# (动作)ACCEPT:接收数据包
# (动作)MASQUERADE:IP伪装(NAT),用于ADSL
# (动作)DNAT:目标地址转换
# 备注:venet0是openvz架构的VPS里绑定公网IP地址的网卡
iptables --policy FORWARD ACCEPT
iptables --table nat --append POSTROUTING --out-interface venet0 --jump MASQUERADE
iptables --table nat --append  PREROUTING  --in-interface venet0 --protocol tcp --dport 9000:9999 --jump DNAT --to-destination 10.0.0.2

nohup /root/lkl/lkl.sh &

p=\`ping 10.0.0.2 -c 3 | grep ttl\`
if [ \$? -ne 0 ]; then
	echo "success "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
else
	echo "fail "\$(date '+%Y-%m-%d %H:%M:%S') > /root/lkl/log.log
fi

EOF




chmod +x lkl.sh
chmod +x run.sh

#写入自动启动
#if [[ "$release" = "CentOS" && "$ver" = "7" ]]; then
#	echo "/root/lkl/run.sh" >> /etc/rc.d/rc.local
#	chmod +x /etc/rc.d/rc.local
#else
#	sed -i "s/exit 0/ /ig" /etc/rc.local
#	echo "/root/lkl/run.sh" >> /etc/rc.local
#fi


./run.sh

#判断是否启动
p=`ping 10.0.0.2 -c 3 | grep ttl`
if [ "$p" == "" ]; then
	echo "fail"
else
	echo "success"
fi
