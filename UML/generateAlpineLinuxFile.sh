#! /bin/bash
#=================================================================#
# 注意: 脚本需要以 UTF-8 编码, 并以 LF 结尾.                      #
# yum install  curl
#=================================================================#
# 此脚本是根据"OpenVZ下开启BBR拥塞控制"翻写的.
# 网址: https://www.fanyueciyuan.info/jsxj/OpenVZ_BBR_UML_Alpine_Linux.html/comment-page-1
#=================================================================#


if [[ $EUID -ne 0 ]]; then
   echo "[ERROR]:${LINENO}, You must run it as root." 1>&2
   exit 1
fi

WORK_DIR="${HOME}/alpine_linux_tmp"
if [ -d ${WORK_DIR} ] || [ -f ${WORK_DIR} ]; then
   echo "[ERROR]:${LINENO}, ${WORK_DIR} already exists." 1>&2
   exit 1
fi

FILE_SIZE=150
FILE_NAME="${WORK_DIR}/alpine_file"
MOUNT_DIR="${WORK_DIR}/alpine_entry"
TMPRY_DIR="${WORK_DIR}/tmp"
LABELNAME="ALPINE_ENTRY"

mkdir ${WORK_DIR}
cd    ${WORK_DIR}  # 假如脚本在当前目录生成了临时文件, 那么可以遗留在脚本的工作目录.
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


function RepoAndApkToolsStaticUrl(){
    local REL="v3.5"
    local ARCH=$(uname -m)
    REPO="http://nl.alpinelinux.org/alpine/${REL}/main"
    local APK_INDEX_URL="${REPO}/${ARCH}/APKINDEX.tar.gz"
    local APKV=$(curl -s ${APK_INDEX_URL} | tar -Oxz | grep -a '^P:apk-tools-static$' -A1 | tail -n1 | cut -d: -f2)
    APK_T__S__URL="${REPO}/${ARCH}/apk-tools-static-${APKV}.apk"
}
RepoAndApkToolsStaticUrl


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
    ${TMPRY_DIR}/sbin/apk.static  --repository ${REPO}  --update-cache  --allow-untrusted  --root ${MOUNT_DIR} --initdb add alpine-base
    
    # 好像是,设置版本库的URL.
    printf '%s\n' ${REPO} > ${MOUNT_DIR}/etc/apk/repositories
}
WriteBasicDataToImage


# 往镜像里写入分区表
cat > ${MOUNT_DIR}/etc/fstab<<-EOF
#
# /etc/fstab: static file system information
#
# <file system>      <dir>   <type>   <options>   <dump>   <pass>
LABEL=${LABELNAME}   /       auto     defaults    1        1
EOF


# 卸载镜像
umount ${MOUNT_DIR}

echo "#====================================#"
echo "#         FINISH, ALL DONE           #"
echo "#====================================#"
