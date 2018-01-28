@setlocal

@REM 请指定代理端口号(代理端口号一般是1080).
@set ProxyPort=1080

@set                 http_proxy=http://127.0.0.1:%ProxyPort%
@git config --global http.proxy http://127.0.0.1:%ProxyPort%

@echo 请输入 exit 退出这个窗口，这样脚本才可以执行清理操作。
@call %comspec% /K

@set http_proxy=
@git config --global --unset http.proxy
@git config --get-regexp        .*proxy

@echo.
@echo 复位git的http.proxy完毕.
@echo.

@pause
