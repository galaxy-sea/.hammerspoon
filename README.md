# .hammerspoon

Hammerspoon 脚本集合。`init.lua` 加载并启动以下模块，并集中配置当前启用的快捷键，配置加载完成后显示提示。

| 脚本名称 | 功能 | 绑定（监听）快捷键 / 事件 |
| --- | --- | --- |
| [init.lua](init.lua) | 配置入口，统一配置快捷键并启动全部功能模块。 | 加载或重新加载配置时执行。 |
| [window_resize.lua](modules/window_resize.lua) | 打开尺寸选择器，将触发快捷键时的聚焦窗口调整为预置或自定义尺寸，并在当前屏幕的可用区域居中；按屏幕缩放比例将像素转换为 points。 | **绑定**：`Ctrl + Cmd + Shift + 5`。 |
| [lockscreen_camera.lua](modules/lockscreen_camera.lua) | 锁屏显示器唤醒后每 5 秒拍一张，解锁或再次黑屏时结束并合并发信。解锁 30 秒后开始独立拍摄，每 30 秒一张，共 10 张；失败也通知，邮件持久化重试。同一轮锁屏期间和解锁后的照片共用 `~/Downloads/异常解锁/日期时间/` 文件夹，文件夹精确到秒、不带随机数；照片命名为 `日期时间-锁屏.jpg` 或 `日期时间-解锁后.jpg`，精确到秒、不带递增序号。两个阶段分别发信；同秒目录复用，同名照片跳过并记录日志。 | **监听系统事件**：锁屏、解锁、显示器休眠和唤醒（`screensDidLock`、`screensDidUnlock`、`screensDidSleep`、`screensDidWake`）；无快捷键。 |
| [close_last_window_hide.lua](modules/close_last_window_hide.lua) | 关闭窗口后，若应用已无窗口则自动隐藏应用；Finder 会排除桌面窗口。 | **监听**：`Cmd + W`，不拦截应用原有的关闭窗口操作；不处理同时按下 `Shift`、`Option` 或 `Ctrl` 的组合。 |
| [blink_reminder.lua](modules/blink_reminder.lua) | 每 20 分钟提醒一次，可延后 1 / 5 / 10 分钟；关闭提醒需经过两次确认，各阶段的随机位置按钮均需连续悬停 10 秒后才能点击。 | **测试快捷键（默认不绑定）**：`Ctrl + Option + Cmd + B`，启用后可立即显示提醒。 |

同一轮锁屏、解锁后及超限分封邮件通过 `In-Reply-To` 和 `References` 引用本轮第一封邮件，方便邮箱按会话合并。每封邮件保留唯一 `Message-ID`，仅同一封邮件重试时复用；会话引用随报告保存，重载后继续使用。不同轮次使用各自的会话引用，实际显示方式取决于邮箱客户端。

修改快捷键时，在 `init.lua` 中调整对应模块的 `start()` 参数即可，例如：
