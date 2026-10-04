# .hammerspoon

Hammerspoon 脚本集合。`init.lua` 加载并启动以下模块，配置加载完成后显示提示。

| 脚本名称 | 功能 | 绑定（监听）快捷键 / 事件 |
| --- | --- | --- |
| [init.lua](init.lua) | 配置入口，启动全部功能模块。 | 无快捷键；加载或重新加载配置时执行。 |
| [window_resize.lua](modules/window_resize.lua) | 打开尺寸选择器，将触发快捷键时的聚焦窗口调整为预置或自定义尺寸，并在当前屏幕的可用区域居中；按屏幕缩放比例将像素转换为 points。 | **绑定**：`Ctrl + Cmd + Shift + 5`。 |
| [lockscreen_camera.lua](modules/lockscreen_camera.lua) | 显示器从休眠状态唤醒且仍处于锁屏状态时，调用 ImageSnap 拍照，保存到 `~/Downloads/异常解锁`，再通过 msmtp 发送照片附件邮件。 | **监听系统事件**：锁屏、解锁、显示器休眠和唤醒（`screensDidLock`、`screensDidUnlock`、`screensDidSleep`、`screensDidWake`）；无已启用的快捷键。 |
| [close_last_window_hide.lua](modules/close_last_window_hide.lua) | 关闭窗口后，若应用已无窗口则自动隐藏应用；Finder 会排除桌面窗口。 | **监听**：`Cmd + W`，不拦截应用原有的关闭窗口操作；不处理同时按下 `Shift`、`Option` 或 `Ctrl` 的组合。 |

窗口尺寸支持预置 `1200 × 760`、`1280 × 800`、`640 × 400`（单位：px），也支持输入 `1280x720`、`1280×720`、`1280 720` 或 `1280,720`，按回车应用。没有聚焦窗口或窗口处于全屏状态时不执行。

锁屏拍照模块需要安装 `imagesnap` 和 `msmtp`，配置 msmtp 的 SMTP 账户，并在脚本中设置发件邮箱、收件邮箱、设备名称及邮件主题。唤醒后延迟 0.1 秒触发拍照，期间若已解锁则取消；唤醒拍照触发间隔至少为 5 秒。脚本中的手动测试快捷键 `Ctrl + Option + Cmd + P`（拍照并发送邮件）已被注释，默认未启用。

关闭窗口后隐藏应用的模块会在 `Cmd + W` 按下约 0.15 秒后检查原前台应用是否仍有窗口。
