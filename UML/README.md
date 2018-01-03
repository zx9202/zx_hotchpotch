# 此文件夹的说明  

* generateAlpineLinuxFile4shadowsocks.sh  
  此脚本最初是参考文章"OpenVZ下开启BBR拥塞控制"写出来的.  
  参考链接: https://www.fanyueciyuan.info/jsxj/OpenVZ_BBR_UML_Alpine_Linux.html  
  下载地址: https://raw.githubusercontent.com/zx9202/zx_hotchpotch/master/UML/generateAlpineLinuxFile4shadowsocks.sh  

- alpine_file.tar.xz  
  根据`generateAlpineLinuxFile4shadowsocks.sh`生成.  

+ vmlinux.tar.xz  
  根据`https://www.kernel.org/`的某版本的代码编译出来的`vmlinux`可执行文件.  
  编译过程: https://github.com/zx9202/zx9202.github.io/blob/my_blog/source/_posts/制作UML的可执行文件vmlinux.md  

* .config  
  编译`vmlinux`时的配置文件.  
