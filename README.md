此内容为 https://github.com/lstprjct/IDM-Activation-Script/blob/main/README.md 的中文翻译

---

**IDM 激活脚本**

**激活：**

此脚本使用注册表锁定方法来激活Internet Download Manager (IDM)。

此方法在激活时需要互联网连接。

可以直接安装 IDM 更新，而无需重新激活。

激活后，如果在某些情况下，IDM 开始显示激活提示屏幕，那么只需再次运行激活选项即可。

**重置 IDM 激活/试用：**

Internet Download Manager 提供30天的试用期，您可以使用此脚本随时重置此激活/试用期。

如果 IDM 报告假冒的序列号和其他类似的错误，也可以使用此选项来恢复状态。

操作系统要求：Windows 7, 8, 8.1, 10 & 11

**如何使用？**

PowerShell
在Windows 10/11上，右键单击Windows开始菜单，选择 PowerShell 或 Terminal。

复制粘贴下面的代码并按回车键：

    iex(irm is.gd/idm_reset)
  
或

    iwr -useb https://raw.githubusercontent.com/lstprjct/IDM-Activation-Script/main/IAS.ps1 | iex

您将看到激活选项，并按照屏幕上的指示操作。

就是这样。

该项目仅支持 Windows 7/8/8.1/10/11 及其服务器等效版本。

**高级信息：**

要在 IDM 许可信息中添加自定义名称，请编辑脚本文件中的第5行。
要在无人值守模式下激活，请使用 /act 参数运行脚本。
要在无人值守模式下重置，请使用 /res 参数运行脚本。
要在上述两种方法中启用静默模式，请使用 /s 参数运行脚本。
可能接受的值，

    "IAS_xxxxxxxx.cmd" /act "IAS_xxxxxxxx.cmd" /res "IAS_xxxxxxxx.cmd" /act /s "IAS_xxxxxxxx.cmd" /res /s

**故障排除步骤：**

如果之前使用其他激活器激活 IDM，请确保使用相同的激活器正确卸载它（如果有这个选项），特别是如果之前使用了任何注册表/防火墙阻止方法。

从控制面板卸载 IDM。

确保使用最新的原始 IDM 设置进行安装，您可以从 https://www.internetdownloadmanager.com/download.html 下载。

现在安装 IDM 并使用此脚本中的激活选项，如果失败则，

使用脚本选项禁用 Windows 防火墙，这有助于处理先前使用的激活器留下的条目（某些文件修补方法也创建防火墙条目）。

一些安全程序可能会阻止此脚本，这是误报，只要您从原始帖子（此页面下面提到）下载了文件，临时挂起防病毒实时保护，或从扫描中排除下载的文件/提取的文件夹。

如果您仍然遇到任何问题，请与我联系（此页面下面提到）。

**致谢：**

@Dukun Cabul - 此 IDM 试用重置和激活逻辑的原始研究者，为这些方法制作了一个 Autoit 工具，IDM-AIO_2020_Final nsaneforums.com/topic/371047--/?do=findComment&comment=1632062

@WindowsAddict - 将上述 Autoit 工具移植到批处理脚本

@AveYo aka @BAU - 设置注册表所有权和权限的代码片段 pastebin.com/XTPt0JSC

@abbodi1406 - 出色的批处理脚本技巧和帮助

@dbenham - 独立于窗口高度设置缓冲区高度 stackoverflow.com/a/13351373

@ModByPiash (我) - 添加并修复一些缺失的功能。

@vavavr00m - 更改设置名称以提示名称

IDM 激活脚本

Telegram: https://t.me/ModByPiash

论坛: https://www.nsaneforums.com/topic/371047--/?do=findComment^&comment=1578647

---

请注意，这只是一个简单的翻译，可能不太准确或不够流畅。如果您对某些翻译内容有疑问或需要进一步的修改，请告诉我。
