@rem Script to build Lua under "Visual Studio .NET Command Prompt".
@rem It creates luabind_static.lib in src.
@rem 根据 lua-5.1.4\etc\luavs.bat 进行了改写.
@rem .(当前目录)
@rem ├─lua-5.1.4
@rem └─luabind-0.9.1
@rem 请修改 DIR_BOOST 并将文件夹匹配到上面的目录.

@set DIR_BOOST=D:\boost\boost_1_63_0
@set DIR_LUABIND=%~dp0
@set DIR_LUA=%DIR_LUABIND%\..\lua-5.1.4\src

@setlocal
@set MYCOMPILE=cl /nologo /MD /O2 /W3 /c /D_CRT_SECURE_NO_DEPRECATE
@set MYLIB=lib /nologo

cd src
%MYCOMPILE%  /I%DIR_BOOST%  /I%DIR_LUABIND%  /I%DIR_LUA%  *.cpp
echo ======[%errorlevel%]======
%MYLIB%  /out:luabind_static.lib  *.obj
echo ======[%errorlevel%]======
del *.obj
cd ..
