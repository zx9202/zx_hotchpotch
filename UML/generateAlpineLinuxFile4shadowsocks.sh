#! /bin/bash
#======================================================================#
# 注意: 脚本需要以 UTF-8 编码, 并以 LF 结尾.
# yum -y install curl wget
#======================================================================#
# 此脚本是根据"OpenVZ下开启BBR拥塞控制"翻写的.
# 网址: https://www.fanyueciyuan.info/jsxj/OpenVZ_BBR_UML_Alpine_Linux.html
#======================================================================#

wget -q -O- http://www.gov.cn/ > /dev/null  &&  curl -s http://www.gov.cn/ > /dev/null
if [ $? -ne 0 ]; then
    echo "[ERROR]:${LINENO}, Please install wget,curl software." 1>&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR]:${LINENO}, You must run the script with root privileges." 1>&2
    exit 1
fi

WORK_DIR="${HOME}/alpine_linux_tmp"
if [ -d ${WORK_DIR} ] || [ -f ${WORK_DIR} ]; then
    echo "[ERROR]:${LINENO}, Working directory already exists." 1>&2
    exit 1
fi

FILE_SIZE=500
FILE_NAME="${WORK_DIR}/alpine_file"
MOUNT_DIR="${WORK_DIR}/alpine_entry"
TMPRY_DIR="${WORK_DIR}/tmp"
LABELNAME="ALPINE_ENTRY"

mkdir ${WORK_DIR}
cd    ${WORK_DIR}  # 假如脚本在当前目录生成了临时文件, 那么可以遗留在${WORK_DIR}里面.
mkdir ${MOUNT_DIR}
mkdir ${TMPRY_DIR}


# 创建一个空镜像, 并打上${LABELNAME}的标签(方便写/etc/fstab文件)
function CreateFileSystem(){
    # 创建一个空文件, 文件名为${FILE_NAME}, 文件大小为${FILE_SIZE}MB
    dd  if=/dev/zero  of=${FILE_NAME}  bs=1M  count=${FILE_SIZE}

    # 在${FILE_NAME}上创建ext4格式的文件系统, 并将文件系统的volume标签设置为${LABELNAME}
    mkfs.ext4  -L ${LABELNAME}  ${FILE_NAME}
}
CreateFileSystem


# 将文件${FILE_NAME}映射到"loop"设备上, 再将这个"loop"设备挂载到${MOUNT_DIR}
mount  -o loop  ${FILE_NAME}  ${MOUNT_DIR}


# 计算${LATEST_STABLE}和${SPECIFIC_REPO}和${APK_T__S__URL}的URL.
function CalcRepoAndApkToolsStaticUrl(){
    local REL="v3.7"
    local ARCH=$(uname -m)
    
    LATEST_STABLE="http://dl-cdn.alpinelinux.org/alpine/latest-stable/main"
    SPECIFIC_REPO="http://dl-cdn.alpinelinux.org/alpine/${REL}/main"
    COMMUNITYREPO="http://dl-cdn.alpinelinux.org/alpine/${REL}/community"

    local APK_INDEX_URL="${SPECIFIC_REPO}/${ARCH}/APKINDEX.tar.gz"
    local APKV=$(curl -s ${APK_INDEX_URL} | tar -Oxz | grep -a '^P:apk-tools-static$' -A1 | tail -n1 | cut -d: -f2)
    APK_T__S__URL="${SPECIFIC_REPO}/${ARCH}/apk-tools-static-${APKV}.apk"
}
CalcRepoAndApkToolsStaticUrl


# 下载相应的"apk tool", 然后通过它, 把基本的系统写入到空镜像中
function WriteBasicDataToImage(){
    # 将压缩包里的"sbin/apk.static"解压到${TMPRY_DIR}下,(解压归档的"某个子文件/子文件夹"到指定目录)
    curl -s ${APK_T__S__URL} | tar -xz -C ${TMPRY_DIR} sbin/apk.static
    
    # apk.static 是 Alpine Linux 的包管理工具, 你可以 ./apk.static -h 查看帮助
    # --repository REPO   Use packages from REPO
    # --update-cache      Update the repository cache
    # --allow-untrusted   Install packages with untrusted signature or no signature
    # --root DIR          Install packages to DIR
    # --initdb            没有找到它的说明, 猜测为第一作者写错了, 同时我没有去掉它.
    # add                 Add PACKAGEs to 'world' and install (or upgrade) them, while ensuring that all dependencies are met
    ${TMPRY_DIR}/sbin/apk.static  --repository ${SPECIFIC_REPO}  --update-cache  --allow-untrusted  --root ${MOUNT_DIR} --initdb add alpine-base
    
    # 好像是,设置版本库的URL.
    printf  '%s\n' ${LATEST_STABLE}  >   ${MOUNT_DIR}/etc/apk/repositories
    printf  '%s\n' ${SPECIFIC_REPO}  >>  ${MOUNT_DIR}/etc/apk/repositories
    printf  '%s\n' ${COMMUNITYREPO}  >>  ${MOUNT_DIR}/etc/apk/repositories
}
WriteBasicDataToImage


# 往镜像里写入分区表
cat > ${MOUNT_DIR}/etc/fstab <<-EOF
#
# /etc/fstab: static file system information
#
# <file system>      <dir>   <type>   <options>   <dump>   <pass>
LABEL=${LABELNAME}   /       auto     defaults    1        1
EOF


# 修改时区, China Standard Time (CST) is 8 hours ahead of Coordinated Universal Time (UTC).
sed -i '1i export TZ=CST-8'  ${MOUNT_DIR}/etc/profile


# 往镜像里写入dns配置文件
cat > ${MOUNT_DIR}/etc/resolv.conf <<-EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 114.114.114.114
EOF


# 往镜像里写入网卡配置文件
cat > ${MOUNT_DIR}/etc/network/interfaces <<-EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
#============================================================#
# ========== set dynamic IP
# auto eth0               # identify physical interface, to be brought up when system boot.
# iface eth0 inet dhcp    # Dynamic Host Configuration Protocol
# ========== set static IP
# auto eth0
# iface eth0 inet static
#         address 192.168.255.254
#         netmask 255.255.255.0
#         gateway 192.168.255.1
# in this case, (address & netmask) => (192.168.255.254 & 255.255.255.0) => 192.168.255.0
#============================================================#

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF


# 为 shadowsocks 定制系统, 如果你不想定制它, 不调用该函数即可
function CustomizeSystemForShadowsocks(){
    # 指定网卡的信息
    cat > ${MOUNT_DIR}/etc/network/interfaces <<-EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
auto  lo
iface lo inet loopback
auto  eth0
iface eth0 inet static
        address 192.168.255.254
        netmask 255.255.255.0
        gateway 192.168.255.1
EOF
    # 准备 shadowsocks-go
    SS_URL="https://github.com/shadowsocks/shadowsocks-go/releases/download/1.2.1/shadowsocks-server.tar.gz"
    mkdir                                  ${MOUNT_DIR}/etc/shadowsocks-go
    wget -c -q -O- ${SS_URL} | tar -zx  -C ${MOUNT_DIR}/etc/shadowsocks-go/  shadowsocks-server
    if [ $? -ne 0 ]; then echo "[ERROR] Failed when dealing with shadowsocks-go !!!" 1>&2 ; fi
    # 准备 shadowsocks.json
    cat                                  > ${MOUNT_DIR}/etc/shadowsocks-go/shadowsocks.json <<-EOF
{
    "server":"0.0.0.0",
    "server_port":65535,
    "password":"shadowsocks-go",
    "method":"rc4-md5",
    "timeout":300
}
EOF
    # 创建一定大小的交换文件
    dd if=/dev/zero of=${MOUNT_DIR}/swapfile bs=1M count=64
    chmod 600          ${MOUNT_DIR}/swapfile
    # 开机自启动脚本
    # 命令 rc-update add local default 相当于 ln -s  /etc/init.d/local  /etc/runlevels/default/
    # 打开 /etc/init.d/local 文件, 可以知道, 它会执行所有的 /etc/local.d/*.start 文件
    # (不建议) 我们把 /etc/init.d/local 拷贝到 /etc/runlevels/default/ 下面 (不建议)
    # (不建议) 然后在 /etc/local.d/ 下面放置要开机启动的脚本, 也可以产生相同的作用
    cp -p  ${MOUNT_DIR}/etc/init.d/local  ${MOUNT_DIR}/etc/runlevels/default/
    cat >  ${MOUNT_DIR}/etc/local.d/shadowsocks.start <<-EOF
# swap on
/sbin/mkswap /swapfile
/sbin/swapon /swapfile
# fix net and start ss by another script
/etc/local.d/shadowsocks.sh &
EOF
    chmod +x ${MOUNT_DIR}/etc/local.d/shadowsocks.start
    # 系统启动后, 此脚本用于重置网络并启动程序
    cat    > ${MOUNT_DIR}/etc/local.d/shadowsocks.sh <<-EOF
LOG_FILE=/log.log
cat /dev/null  >  \${LOG_FILE}
for IDX in \$(seq 10); do
    /etc/init.d/networking restart > /dev/null 2>&1
    DRC=\$(ip route show exact 0/0 | grep -E "^default.* dev [^ ]+" -c)
    echo "PID=\$\$, IDX=\${IDX}, \$(date), DRC=\${DRC}" >> \${LOG_FILE}
    if [ \${DRC} -gt 0 ]; then
        for NUM in \$(pidof shadowsocks-server); do kill -9 \${NUM}; done
        /usr/bin/nohup /etc/shadowsocks-go/shadowsocks-server -c /etc/shadowsocks-go/shadowsocks.json > /dev/null 2>&1 &
        break
    else
        sleep 2
    fi
done
echo "PID=\$\$, IDX=\${IDX}, \$(date), DRC=\${DRC}, will exit..." >> \${LOG_FILE}
EOF
    chmod +x ${MOUNT_DIR}/etc/local.d/shadowsocks.sh
    # 为 shadowsocks 优化系统配置
    cat > ${MOUNT_DIR}/etc/sysctl.conf <<-EOF
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096
# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1
# BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
}
CustomizeSystemForShadowsocks


# 卸载镜像
umount ${MOUNT_DIR}

echo "#===============================================================#"
echo "#  FINISH, ALL DONE                                             #"
echo "#  If there is no error, then the file is ready for normal use  #"
echo "#===============================================================#"
