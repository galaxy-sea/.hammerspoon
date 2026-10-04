local M = {}

local watcher = nil

-- 判断应用是否还有“真正的窗口”
local function hasRealWindows(app)
    if not app then
        return false
    end

    local windows = app:allWindows()

    -- Finder 特殊处理
    -- Finder 的 Desktop 也会被 Hammerspoon 当作一个窗口返回，
    -- 但它不是普通 Finder 窗口，所以需要过滤。
    if app:bundleID() == "com.apple.finder" then
        for _, win in ipairs(windows) do
            if win:role() == "AXWindow" then
                return true
            end
        end

        return false
    end

    -- 普通应用：
    -- 只要还有窗口存在，就认为不能隐藏
    return #windows > 0
end

function M.start()
    -- 防止重复启动
    if watcher then
        return
    end

    watcher = hs.eventtap.new(
        {
            hs.eventtap.event.types.keyDown
        },
        function(event)
            local flags = event:getFlags()
            local keyCode = event:getKeyCode()

            -- 只监听纯 Command + W
            --
            -- 不处理：
            -- Command + Shift + W
            -- Command + Option + W
            -- Command + Control + W
            if keyCode == hs.keycodes.map.w
                and flags.cmd
                and not flags.shift
                and not flags.alt
                and not flags.ctrl
            then
                -- 记录按下 Command + W 时的前台应用
                local app = hs.application.frontmostApplication()

                if app then
                    -- 使用 PID 标识这一次运行的应用实例
                    local pid = app:pid()

                    -- 给应用一点时间处理原始 Command + W
                    hs.timer.doAfter(0.15, function()
                        -- 通过 PID 重新取得刚才的应用
                        local targetApp =
                            hs.application.applicationForPID(pid)

                        -- 应用可能已经退出
                        if not targetApp then
                            return
                        end

                        -- 如果应用已经没有真正的窗口，则隐藏它
                        if not hasRealWindows(targetApp) then
                            targetApp:hide()
                        end
                    end)
                end
            end

            -- false：
            -- 不拦截原始 Command + W，
            -- 继续让当前应用正常处理关闭窗口操作
            return false
        end
    )

    watcher:start()
end

function M.stop()
    if watcher then
        watcher:stop()
        watcher = nil
    end
end

return M