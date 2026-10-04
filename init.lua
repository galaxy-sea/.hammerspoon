------------------------------------------------------------
-- Hammerspoon init.lua
------------------------------------------------------------

require("modules.window_resize").start()
require("modules.lockscreen_camera").start()
require("modules.close_last_window_hide").start()

hs.alert.show("Hammerspoon 配置已加载")