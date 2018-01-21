# 此文件夹的说明  

* go-shadowsocks2.tar.xz  
根据`https://github.com/shadowsocks/go-shadowsocks2`的代码编译而成。  
编译过程如下：  
```shell
yum -y install golang
yum -y install git
go get -u -v github.com/shadowsocks/go-shadowsocks2
find / -iname "*go-shadowsocks2*"
cd  ~/go/src/github.com/shadowsocks/go-shadowsocks2/
CGO_ENABLED=0 go build -a -installsuffix cgo .
```
参考链接：  
[Alpine里的go应用，你猜他能有多小？](https://studygolang.com/articles/6002)  
[go build](http://wiki.jikexueyuan.com/project/go-command-tutorial/0.1.html)  

解释`CGO_ENABLED=0 go build -a -installsuffix cgo .`：  
CGO_ENABLED=0 是一个编译标志，会让构建系统忽略cgo并且静态链接所有依赖；  
-a 会强制重新编译，即使所有包都是由最新代码编译的；  
-installsuffix cgo 会为新编译的包目录添加一个后缀，这样可以把编译的输出与默认的路径分离。  
-installsuffix(说实话我没有搞懂这个参数的具体含义-_-!)  
为了使当前的输出目录与默认的编译输出目录分离，可以使用这个标记。  
此标记的值会作为结果文件的父目录名称的后缀。  
其实，如果使用了-race标记，这个标记会被自动追加且其值会为race。  
如果我们同时使用了-race标记和-installsuffix，那么在-installsuffix标记的值的后面会再被追加_race，并以此来作为实际使用的后缀。  
