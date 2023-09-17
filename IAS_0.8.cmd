@setlocal DisableDelayedExpansion
@echo off

:: 在 IDM 许可信息中添加自定义名称，建议在等号后面的下一行使用英文和/或数字写入。
set name=




::========================================================================================================================================

:: 如果脚本是由 x86 进程在 x64 位 Windows 上启动的，则使用 x64 进程重新启动脚本。
:: 或者，如果脚本是由 x86/ARM32 进程在 ARM64 Windows 上启动的，则使用 ARM64 进程。

if exist %SystemRoot%\Sysnative\cmd.exe (
set "_cmdf=%~f0"
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

:: 如果在 ARM64 Windows 上由 x64 进程启动，则使用 ARM32 进程重新启动脚本。

if exist %SystemRoot%\Windows\SyChpe32\kernel32.dll if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 (
set "_cmdf=%~f0"
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

::  设置 Path 变量，如果系统中配置错误，此设置会有所帮助。

set "SysPath=%SystemRoot%\System32"
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"

::========================================================================================================================================

cls
color 07

set _args=
set _elev=
set reset=
set Silent=
set activate=

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"  set _elev=1
if /i "%%A"=="/res" set Unattended=1&set activate=&set reset=1
if /i "%%A"=="/act" set Unattended=1&set activate=1&set reset=
if /i "%%A"=="/s"   set Unattended=1&set Silent=1
)
)

::========================================================================================================================================

set "nul=>nul 2>&1"
set "_psc=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
call :_colorprep
set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "line=________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

if defined Silent if not defined activate if not defined reset exit /b
if defined Silent call :begin %nul% & exit /b

:begin

::========================================================================================================================================

if not exist "%_psc%" (
%nceline%
echo Powershell 没有安装在这台电脑上。
echo 正在中止操作...
goto done2
)

if %winbuild% LSS 7600 (
%nceline%
echo 检测到不支持的操作系统版本。
echo 该项目仅支持 Windows 7/8/8.1/10/11 及其服务器版本。
goto done2
)


::========================================================================================================================================

::  修复路径名中的特殊字符限制问题
::  感谢 @abbodi1406

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_appdata=%appdata%"
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\DownloadManager" /v ExePath 2^>nul') do call set "IDMan=%%b"

setlocal EnableDelayedExpansion

::========================================================================================================================================

::  以管理员身份提升脚本并传递参数以及防止循环
::  感谢 @abbodi1406 提供的 PowerShell 方法以及解决文件路径名称中的特殊字符问题。

%nul% reg query HKU\S-1-5-19 || (
if not defined _elev %nul% %_psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%nceline%
echo 此脚本需要管理员权限。
echo 为此，请右键点击此脚本并选择'以管理员身份运行'。
goto done2
)


::========================================================================================================================================

:: 下面的代码也适用于 ARM64 Windows 10（包括 x64 位模拟）

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" /v "Identifier" | find /i "x86" 1>nul && set arch=x86|| set arch=x64

if not exist "!IDMan!" (
if %arch%==x64 set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
if %arch%==x86 set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

if "%arch%"=="x86" (
set "CLSID=HKCU\Software\Classes\CLSID"
set "HKLM=HKLM\Software\Internet Download Manager"
set "_tok=5"
) else (
set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
set "_tok=6"
)

set _temp=%SystemRoot%\Temp
set regdata=%SystemRoot%\Temp\regdata.txt
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" >nul"

::========================================================================================================================================

if defined Unattended (
if defined reset goto _reset
if defined activate goto _activate
)

:MainMenu
chcp 65001
cls
title  IDM Activation Script
mode 65, 25

:: 检查防火墙状态

set /a _ena=0
set /a _dis=0
for %%# in (DomainProfile PublicProfile StandardProfile) do (
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
if /i %%b equ 0x1 (set /a _ena+=1) else (set /a _dis+=1)
)
)

if %_ena%==3 (
set _status=Enabled
set _col=%_Green%
)

if %_dis%==3 (
set _status=Disabled
set _col=%_Red%
)

if not %_ena%==3 if not %_dis%==3 (
set _status=Status_Unclear
set _col=%_Yellow%
)
		

echo:           ─▀▀▌───────▐▀▀
echo:           ─▄▀░◌░░░░░░░▀▄        ◇────────────────────◇
echo:           ▐░░◌░▄▀██▄█░░░▌        	    IDM 激活脚本
echo:           ▐░░░▀████▀▄░░░▌       ◇────────────────────◇
echo:           ═▀▄▄▄▄▄▄▄▄▄▄▄▀═
echo:
call :_color2 %_White% "        " %_Green% "  Create By Piash"           
echo:          _____________________________________________  
echo:          
echo:          [1] 激活 IDM                               
echo:          [2] 重置 IDM 激活/试用状态
echo:          _____________________________________________   
echo:                                                          
call :_color2 %_White% "          [3] 切换 Windows 防火墙  " %_col% "[%_status%]"
echo:          _____________________________________________   
echo:                                                          
echo:          [4] 说明书                                      
echo:          [5] 主页                                    
echo:          [6] 退出                                        
echo:       ___________________________________________________
echo:   
call :_color2 %_White% "        " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,5,6]"
choice /C:123456 /N
set _erl=%errorlevel%

if %_erl%==5 exit /b
if %_erl%==4 goto homepage
if %_erl%==3 call :_tog_Firewall&goto MainMenu
if %_erl%==2 goto _reset
if %_erl%==1 goto _activate
goto :MainMenu

::========================================================================================================================================

:_tog_Firewall

if %_status%==Enabled (
netsh AdvFirewall Set AllProfiles State Off >nul
) else (
netsh AdvFirewall Set AllProfiles State On >nul
)
exit /b

::========================================================================================================================================

:readme

set "_ReadMe=%SystemRoot%\Temp\ReadMe.txt"
if exist "%_ReadMe%" del /f /q "%_ReadMe%" %nul%
call :export txt "%_ReadMe%"
start notepad "%_ReadMe%"
timeout /t 2 %nul%
del /f /q "%_ReadMe%"
exit /b


::  从批处理脚本中提取文本，无字符和文件编码问题
::  感谢 @abbodi1406

:export

%nul% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split \":%~1\:.*`r`n\"; [io.file]::WriteAllText('%~2',$f[1].Trim(),[System.Text.Encoding]::ASCII);"
exit/b

::========================================================================================================================================

:_reset

if not defined Unattended (
mode 93, 32
%nul% %_psc% "&%_buf%"
)

echo:
set _error=

reg query "HKCU\Software\DownloadManager" "/v" "Serial" %nul% && (
%idmcheck% && taskkill /f /im idman.exe
)

if exist "!_appdata!\DMCache\settings.bak" del /s /f /q "!_appdata!\DMCache\settings.bak"

set "_action=call :delete_key"
call :reset

echo:
echo %line%
echo:
if not defined _error (
call :_color %Green% "IDM Activation - Trial is successfully reset in the registry."
) else (
call :_color %Red% "Failed to completely reset IDM Activation - Trial."
)

goto done

::========================================================================================================================================

:_activate

if not defined Unattended (
mode 93, 32
%nul% %_psc% "&%_buf%"
)

echo:
set _error=

if not exist "!IDMan!" (
call :_color %Red% "IDM [Internet Download Manager] is not Installed."
echo 您可以从 https://www.internetdownloadmanager.com/download.html 下载它。
goto done
)

:: 通过对 internetdownloadmanager.com 的 ping 和端口 80 测试来检查互联网连接

ping -n 1 internetdownloadmanager.com >nul || (
%_psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i true 1>nul
)

if not [%errorlevel%]==[0] (
call :_color %Red% "无法连接到 internetdownloadmanager.com，正在中止..."
goto done
)

echo 互联网已连接。

%idmcheck% && taskkill /f /im idman.exe

if exist "!_appdata!\DMCache\settings.bak" del /s /f /q "!_appdata!\DMCache\settings.bak"

set "_action=call :delete_key"
call :reset

set "_action=call :count_key"
call :register_IDM

echo:
if defined _derror call :f_reset & goto done

set lockedkeys=
set "_action=call :lock_key"
echo Locking registry keys...
echo:
call :action

if not defined _error if [%lockedkeys%] GEQ [7] (
echo:
echo %line%
echo:
call :_color %Green% "IDM is successfully activated."
echo:
call :_color %Gray% "如果出现假序列号屏幕，再次运行激活选项，之后它就不会再出现."
goto done
)

call :f_reset

::========================================================================================================================================

:done

echo %line%
echo:
echo:
if defined Unattended (
timeout /t 3
exit /b
)

call :_color %_Yellow% "按任意键返回..."
pause >nul
goto MainMenu

:done2

if defined Unattended (
timeout /t 3
exit /b
)

echo Press any key to exit...
pause >nul
exit /b

::========================================================================================================================================

:homepage

cls
echo:
echo:
echo Going Home...
echo:
echo:
timeout /t 3

start https://github.com/lstprjct/IDM-Activation-Script
goto MainMenu

::========================================================================================================================================

:f_reset

echo:
echo %line%
echo:
call :_color %Red% "发现错误，正在重置 IDM 激活..."
set "_action=call :delete_key"
call :reset
echo:
echo %line%
echo:
call :_color %Red% "IDM 激活失败。"
exit /b

::========================================================================================================================================

:reset

set take_permission=
call :delete_queue
set take_permission=1
call :action
call :add_key
exit /b

::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :_add_key
exit /b

:register_IDM

echo:
set /p name="您想要注册的名称是什么？"

echo:
echo 正在应用注册详情...
echo:

If not defined name set name=Piash

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%name%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d """ & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "info@tonec.com"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "FOX6H-3KWH4-7TSIN-Q4US7"" & call :_rcont

echo:
echo 触发一些下载以创建特定的注册表键，请稍等...

set "file=%_temp%\temp.png"
set _fileexist=
set _derror=

%idmcheck% && taskkill /f /im idman.exe

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download

:: 可能需要一些时间才能反映注册表键值。

timeout /t 3 >nul

set foundkeys=
call :action
if [%foundkeys%] GEQ [7] goto _skip

set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download
set link=https://www.internetdownloadmanager.com/languages/indian.png
call :download

timeout /t 3 >nul

set foundkeys=
call :action
if not [%foundkeys%] GEQ [7] set _derror=1

:_skip

echo:
if not defined _derror (
echo 所需的注册表键已成功创建。
) else (
if not defined _fileexist call :_color %Red% "无法使用IDM下载文件。"
call :_color %Red% "无法创建所需的注册表键。"
call :_color %Magenta% "请重试 - 使用脚本选项禁用Windows防火墙 - 查看说明文档。"
)

echo:
%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%"
exit /b

:download

set /a attempt=0
if exist "%file%" del /f /q "%file%"
start "" /B "!IDMan!" /n /d "%link%" /p "%_temp%" /f temp.png

:check_file

timeout /t 1 >nul
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 20 exit /b
goto :Check_file

::========================================================================================================================================

:delete_queue

echo:
echo Deleting registry keys...
echo:

for %%# in (
""HKCU\Software\DownloadManager" "/v" "FName""
""HKCU\Software\DownloadManager" "/v" "LName""
""HKCU\Software\DownloadManager" "/v" "Email""
""HKCU\Software\DownloadManager" "/v" "Serial""
""HKCU\Software\DownloadManager" "/v" "scansk""
""HKCU\Software\DownloadManager" "/v" "tvfrdt""
""HKCU\Software\DownloadManager" "/v" "radxcnt""
""HKCU\Software\DownloadManager" "/v" "LstCheck""
""HKCU\Software\DownloadManager" "/v" "ptrk_scdt""
""HKCU\Software\DownloadManager" "/v" "LastCheckQU""
"%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :delete_key
)

exit /b

::========================================================================================================================================

:add_key

echo:
echo Adding registry key...
echo:

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:_add_key

if [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo Added - !reg!
) else (
set _error=1
set "reg=%reg:"=%"
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline&echo  - !reg!
)
exit /b

::========================================================================================================================================

:action

if exist %regdata% del /f /q %regdata% %nul%

reg query %CLSID% > %regdata%

%nul% %_psc% "(gc %regdata%) -replace 'HKEY_CURRENT_USER', 'HKCU' | Out-File -encoding ASCII %regdata%"

for /f %%a in (%regdata%) do (
for /f "tokens=%_tok% delims=\" %%# in ("%%a") do (
echo %%#|findstr /r "{.*-.*-.*-.*-.*}" >nul && (set "reg=%%a" & call :scan_key)
)
)

if exist %regdata% del /f /q %regdata% %nul%

exit /b

::========================================================================================================================================

:scan_key

reg query %reg% 2>nul | findstr /i "LocalServer32 InProcServer32 InProcHandler32" >nul && exit /b

reg query %reg% 2>nul | find /i "H" 1>nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a|findstr /r /e "[^0-9]" >nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=3" %%a in ('reg query %reg%\Version /ve 2^>nul') do echo %%a|findstr /r "[^0-9]" >nul || (
%_action%
exit /b
)

for /f "skip=2 tokens=1" %%a in ('reg query %reg% 2^>nul') do echo %%a| findstr /i "MData Model scansk Therad" >nul && (
%_action%
exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a| find /i "+" >nul && (
%_action%
exit /b
)

exit/b

::========================================================================================================================================

:delete_key

reg delete %reg% /f %nul%

if not [%errorlevel%]==[0] if defined take_permission (
%nul% call :reg_own "%reg%" preserve S-1-1-0
reg delete %reg% /f %nul%
)

if [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo Deleted - !reg!
) else (
set "reg=%reg:"=%"
set _error=1
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline & echo  - !reg!
)

exit /b

::========================================================================================================================================

:lock_key

%nul% call :reg_own "%reg%" "" S-1-1-0 S-1-0-0 Deny "FullControl"

reg delete %reg% /f %nul%

if not [%errorlevel%]==[0] (
set "reg=%reg:"=%"
echo Locked - !reg!
set /a lockedkeys+=1
) else (
set _error=1
set "reg=%reg:"=%"
%_psc% write-host 'Failed' -fore 'white' -back 'DarkRed'  -NoNewline&echo  - !reg!
)

exit /b

::========================================================================================================================================

:count_key

set /a foundkeys+=1
exit /b

::========================================================================================================================================

::  一个简洁而高效的代码片段，用于递归地设置注册表的所有权和权限
::  由 @AveYo 编写，也称为 @BAU
::  pastebin.com/XTPt0JSC

:reg_own

%_psc% $A='%~1','%~2','%~3','%~4','%~5','%~6';iex(([io.file]::ReadAllText('!_batp!')-split':Own1\:.*')[1])&exit/b:Own1:
$D1=[uri].module.gettype('System.Diagnostics.Process')."GetM`ethods"(42) |where {$_.Name -eq 'SetPrivilege'} #`:no-ev-warn
'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege'|foreach {$D1.Invoke($null, @("$_",2))}
$path=$A[0]; $rk=$path-split'\\',2; $HK=gi -lit Registry::$($rk[0]) -fo; $s=$A[1]; $sps=[Security.Principal.SecurityIdentifier]
$u=($A[2],'S-1-5-32-544')[!$A[2]];$o=($A[3],$u)[!$A[3]];$w=$u,$o |% {new-object $sps($_)}; $old=!$A[3];$own=!$old; $y=$s-eq'all'
$rar=new-object Security.AccessControl.RegistryAccessRule( $w[0], ($A[5],'FullControl')[!$A[5]], 1, 0, ($A[4],'Allow')[!$A[4]] )
$x=$s-eq'none';function Own1($k){$t=$HK.OpenSubKey($k,2,'TakeOwnership');if($t){0,4|%{try{$o=$t.GetAccessControl($_)}catch{$old=0}
};if($old){$own=1;$w[1]=$o.GetOwner($sps)};$o.SetOwner($w[0]);$t.SetAccessControl($o); $c=$HK.OpenSubKey($k,2,'ChangePermissions')
$p=$c.GetAccessControl(2);if($y){$p.SetAccessRuleProtection(1,1)};$p.ResetAccessRule($rar);if($x){$p.RemoveAccessRuleAll($rar)}
$c.SetAccessControl($p);if($own){$o.SetOwner($w[1]);$t.SetAccessControl($o)};if($s){$subkeys=$HK.OpenSubKey($k).GetSubKeyNames()
foreach($n in $subkeys){Own1 "$k\$n"}}}};Own1 $rk[1];if($env:VO){get-acl Registry::$path|fl} #:Own1: lean & mean snippet by AveYo

::========================================================================================================================================

:_color

if %winbuild% GEQ 10586 (
echo %esc%[%~1%~2%esc%[0m
) else (
call :batcol %~1 "%~2"
)
exit /b

:_color2

if %winbuild% GEQ 10586 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
call :batcol %~1 "%~2" %~3 "%~4"
)
exit /b

::=======================================

:: 使用纯批处理方法的彩色文本
:: 感谢 @dbenham 和 @jeb
:: https://stackoverflow.com/a/10407642

:: 这里没有使用Powershell，因为它运行较慢

:batcol

pushd %_coltemp%
if not exist "'" (<nul >"'" set /p "=.")
setlocal
set "s=%~2"
set "t=%~4"
call :_batcol %1 s %3 t
del /f /q "'"
del /f /q "`.txt"
popd
exit /b

:_batcol

setlocal EnableDelayedExpansion
set "s=!%~2!"
set "t=!%~4!"
for /f delims^=^ eol^= %%i in ("!s!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~1 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
if "%~4"=="" echo(&exit /b
setlocal EnableDelayedExpansion
for /f delims^=^ eol^= %%i in ("!t!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~3 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
echo(
exit /b

::=======================================

:_colorprep

if %winbuild% GEQ 10586 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"

set     "Red="41;97m""
set    "Gray="100;97m""
set   "Black="30m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "Yellow="43;97m""
set "Magenta="45;97m""

set    "_Red="40;91m""
set  "_Green="40;92m""
set   "_Blue="40;94m""
set  "_White="40;37m""
set "_Yellow="40;93m""

exit /b
)

if not defined _BS for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"
set "_coltemp=%SystemRoot%\Temp"

set     "Red="CF""
set    "Gray="8F""
set   "Black="00""
set   "Green="2F""
set    "Blue="1F""
set  "Yellow="6F""
set "Magenta="5F""

set    "_Red="0C""
set  "_Green="0A""
set   "_Blue="09""
set  "_White="07""
set "_Yellow="0E""

exit /b

::========================================================================================================================================

:txt:
_________________________________

   激活:
_________________________________

 - 该脚本使用注册表锁定方法来激活 Internet Download Manager (IDM)。

 - 该方法在激活时需要互联网。

 - IDM 更新可以直接安装，无需重新激活。

 - 激活后，如果在某些情况下，IDM 开始显示激活提示屏幕，只需再次运行激活选项即可。

_________________________________

   重置 IDM 激活/试用:
_________________________________

 - Internet Download Manager 提供 30 天的试用期，您可以使用此脚本随时重置此激活/试用期。

 - 如果 IDM 报告了假的序列号或其他类似的错误，也可以使用此选项来恢复状态。

_________________________________

   操作系统要求:
_________________________________

 - 该项目仅支持 Windows 7/8/8.1/10/11 及其服务器版本。

_________________________________

 - 高级信息:
_________________________________

   - 要在 IDM 许可信息中添加自定义名称，请编辑脚本文件中的第5行。
   - 要在无人值守模式下激活，请带 /act 参数运行脚本。
   - 要在无人值守模式下重置，请带 /res 参数运行脚本。
   - 要与上述两种方法一起启用静默模式，请带 /s 参数运行脚本。

可能的接受值，

"IAS_xxxxxxxx.cmd" /act
"IAS_xxxxxxxx.cmd" /res
"IAS_xxxxxxxx.cmd" /act /s
"IAS_xxxxxxxx.cmd" /res /s

_________________________________

 - 故障排除步骤:
_________________________________

   - 如果之前使用其他激活器激活 IDM，请确保使用同一激活器正确卸载它（如果有此选项）。如果之前使用了任何注册表/防火墙阻止方法，这一点尤为重要。

   - 从控制面板卸载 IDM。

   - 确保用于安装的是最新的原始 IDM 设置，您可以从 https://www.internetdownloadmanager.com/download.html 下载。

   - 现在安装 IDM 并使用此脚本中的激活选项，如果失败，

     - 使用脚本选项禁用 Windows 防火墙，这有助于处理之前使用的激活器留下的条目（某些文件补丁方法也会创建防火墙条目）。

     - 一些安全程序可能会阻止此脚本，这是误报，只要您从原始帖子（此页面下方提到）下载了文件，暂时暂停实时防病毒保护，或从扫描中排除下载的文件/提取的文件夹。

     - 如果您仍然遇到任何问题，请与我联系（此页面下方提到）。

__________________________________________________________________________________________________

   致谢:
__________________________________________________________________________________________________

   @Dukun Cabul		- 此 IDM 试用重置和激活逻辑的原始研究者，为这些方法制作了一个 Autoit 工具，IDM-AIO_2020_Final
			  nsaneforums.com/topic/371047--/?do=findComment&comment=1632062
                         
   @WindowsAddict	- 将上述 Autoit 工具移植到批处理脚本

   @AveYo aka @BAU	- 设置注册表所有权和权限的代码片段 pastebin.com/XTPt0JSC

   @abbodi1406		- 出色的批处理脚本技巧和帮助

   @dbenham		- 独立于窗口高度设置缓冲区高度 stackoverflow.com/a/13351373

   @ModByPiash (Me)	- 添加并修复一些缺失的功能。

   @vavavr00m  		- 更改设置名称以提示名称

   @LazyDevv		- 在主菜单中添加了一个可爱的金鱼艺术品。
   
_________________________________

   IDM 激活脚本

   主页: https://github.com/lstprjct/IDM-Activation-Script

   Telegram: https://t.me/ModByPiash

__________________________________________________________________________________________________
:txt:

::========================================================================================================================================
