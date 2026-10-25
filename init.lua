------------------------------------------------------------
-- Hammerspoon init.lua
------------------------------------------------------------

-- 快捷键统一在这里配置，由各模块负责绑定或监听。
-- mods 使用 ctrl / alt（Option）/ cmd / shift。
-- bind = false 跳过绑定或监听；true 或省略时启用。
require("modules.window_resize").start({
    mods = { "ctrl", "cmd", "shift" },
    key = "5",
})

require("modules.lockscreen_camera").start()

-- 监听应用的关闭窗口快捷键，不拦截原始按键。
require("modules.close_last_window_hide").start({
    mods = { "cmd" },
    key = "W",
})

-- 测试快捷键默认不绑定，定时提醒照常启动；测试时将 bind 改为 true。
require("modules.blink_reminder").start({
    mods = { "ctrl", "alt", "cmd" },
    key = "B",
    bind = false,
})

hs.alert.show("Hammerspoon 配置已加载")
