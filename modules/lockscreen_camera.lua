------------------------------------------------------------
-- lockscreen_camera.lua
--
-- 功能：
--
-- Mac 已锁屏
--     ↓
-- 显示器进入黑屏 / Sleep
--     ↓
-- 鼠标 / 键盘重新唤醒显示器
--     ↓
-- 如果仍然处于锁屏状态
--     ↓
-- 摄像头拍照
--     ↓
-- 保存到 ~/Downloads/异常解锁
--     ↓
-- 通过 msmtp + QQ 邮箱发送照片附件
--
------------------------------------------------------------

local M = {}

------------------------------------------------------------
-- 配置
------------------------------------------------------------

-- 照片保存目录
local PHOTO_DIR =
    os.getenv("HOME")
    .. "/Downloads/异常解锁"


------------------------------------------------------------
-- 邮件配置
------------------------------------------------------------

-- QQ 发件邮箱
-- 改成你自己的 QQ 邮箱
local EMAIL_FROM = "2468080401@qq.com"

-- 收件邮箱
-- 可以和发件邮箱相同，也可以是其他邮箱
local EMAIL_TO = "469753862@qq.com"

-- 收件人看到的发件人名称
local EMAIL_FROM_NAME =
    "MacBook Pro 21 M1 Pro"

-- 邮件主题
local EMAIL_SUBJECT =
    "MacBook Pro 21 M1 Pro - 锁屏异常唤醒"


------------------------------------------------------------
-- 摄像头配置
------------------------------------------------------------

-- ImageSnap 摄像头预热时间
-- 0.5 秒通常比较合适
local CAMERA_WARMUP = "0.5"

-- 屏幕 Wake 后多久开始启动摄像头
local TRIGGER_DELAY = 0.10

-- 防止短时间内重复 Wake 造成重复邮件
local WAKE_COOLDOWN = 5


------------------------------------------------------------
-- 状态
------------------------------------------------------------

local watcher = nil

-- 当前是否锁屏
local locked = false

-- 显示器之前是否真正进入过 Sleep
local displaySleeping = false

-- 摄像头是否忙
local cameraBusy = false

-- 邮件是否正在发送
local emailBusy = false

-- 上一次拍照时间
local lastWakeShot = 0


------------------------------------------------------------
-- 日志
------------------------------------------------------------

local function log(message)

    print(
        "[LockscreenCamera] "
        .. os.date("%Y-%m-%d %H:%M:%S")
        .. " "
        .. tostring(message)
    )
end


------------------------------------------------------------
-- 查找可执行文件
------------------------------------------------------------

local function findExecutable(paths)

    for _, path in ipairs(paths) do

        if hs.fs.attributes(path) then
            return path
        end
    end

    return nil
end


------------------------------------------------------------
-- 查找 imagesnap
------------------------------------------------------------

local function findImageSnap()

    return findExecutable({

        -- Apple Silicon Homebrew
        "/opt/homebrew/bin/imagesnap",

        -- Intel Homebrew
        "/usr/local/bin/imagesnap",

    })
end


------------------------------------------------------------
-- 查找 msmtp
------------------------------------------------------------

local function findMsmtp()

    return findExecutable({

        -- Apple Silicon Homebrew
        "/opt/homebrew/bin/msmtp",

        -- Intel Homebrew
        "/usr/local/bin/msmtp",

    })
end


------------------------------------------------------------
-- 读取二进制文件
------------------------------------------------------------

local function readBinaryFile(filename)

    local file, err =
        io.open(filename, "rb")

    if not file then

        log(
            "Cannot open attachment: "
            .. tostring(err)
        )

        return nil
    end

    local data =
        file:read("*all")

    file:close()

    return data
end


------------------------------------------------------------
-- 邮件 Header 编码
--
-- 用于中文 Subject
------------------------------------------------------------

local function encodeMailHeader(text)

    return
        "=?UTF-8?B?"
        .. hs.base64.encode(text)
        .. "?="
end


------------------------------------------------------------
-- 获取附件文件名
------------------------------------------------------------

local function basename(path)

    return
        path:match("([^/]+)$")
        or path
end


------------------------------------------------------------
-- 构造 MIME 邮件
------------------------------------------------------------

local function buildEmail(filename)

    --------------------------------------------------------
    -- 读取照片
    --------------------------------------------------------

    local imageData =
        readBinaryFile(filename)

    if not imageData then
        return nil
    end


    --------------------------------------------------------
    -- Base64 编码附件
    --
    -- MIME 推荐每行 76 字符
    --------------------------------------------------------

    local attachmentBase64 =
        hs.base64.encode(
            imageData,
            76
        )


    --------------------------------------------------------
    -- MIME Boundary
    --------------------------------------------------------

    local boundary =
        "----HammerspoonBoundary"
        .. os.date("%Y%m%d%H%M%S")
        .. tostring(
            math.random(
                100000,
                999999
            )
        )


    --------------------------------------------------------
    -- 当前时间
    --------------------------------------------------------

    local eventTime =
        os.date(
            "%Y-%m-%d %H:%M:%S"
        )


    --------------------------------------------------------
    -- 邮件正文
    --------------------------------------------------------

    local body =
        "检测到 MacBook 在锁屏状态下，"
        .. "显示器从黑屏状态被重新唤醒。\n\n"
        .. "设备："
        .. EMAIL_FROM_NAME
        .. "\n"
        .. "时间："
        .. eventTime
        .. "\n\n"
        .. "已自动拍摄现场照片，"
        .. "请查看邮件附件。\n"


    --------------------------------------------------------
    -- 附件名称
    --------------------------------------------------------

    local attachmentName =
        basename(filename)


    --------------------------------------------------------
    -- 邮件
    --------------------------------------------------------

    local message = {}

    table.insert(
        message,
        'From: "'
        .. EMAIL_FROM_NAME
        .. '" <'
        .. EMAIL_FROM
        .. ">"
    )

    table.insert(
        message,
        "To: "
        .. EMAIL_TO
    )

    table.insert(
        message,
        "Subject: "
        .. encodeMailHeader(
            EMAIL_SUBJECT
        )
    )

    table.insert(
        message,
        "MIME-Version: 1.0"
    )

    table.insert(
        message,
        'Content-Type: multipart/mixed; boundary="'
        .. boundary
        .. '"'
    )

    table.insert(
        message,
        ""
    )


    --------------------------------------------------------
    -- 正文部分
    --------------------------------------------------------

    table.insert(
        message,
        "--"
        .. boundary
    )

    table.insert(
        message,
        'Content-Type: text/plain; charset="UTF-8"'
    )

    table.insert(
        message,
        "Content-Transfer-Encoding: base64"
    )

    table.insert(
        message,
        ""
    )

    table.insert(
        message,
        hs.base64.encode(
            body,
            76
        )
    )


    --------------------------------------------------------
    -- JPG 附件
    --------------------------------------------------------

    table.insert(
        message,
        "--"
        .. boundary
    )

    table.insert(
        message,
        'Content-Type: image/jpeg; name="'
        .. attachmentName
        .. '"'
    )

    table.insert(
        message,
        "Content-Transfer-Encoding: base64"
    )

    table.insert(
        message,
        'Content-Disposition: attachment; filename="'
        .. attachmentName
        .. '"'
    )

    table.insert(
        message,
        ""
    )

    table.insert(
        message,
        attachmentBase64
    )


    --------------------------------------------------------
    -- MIME 结束
    --------------------------------------------------------

    table.insert(
        message,
        "--"
        .. boundary
        .. "--"
    )

    table.insert(
        message,
        ""
    )


    return
        table.concat(
            message,
            "\r\n"
        )
end


------------------------------------------------------------
-- 发送邮件
------------------------------------------------------------

local function sendEmail(
    msmtpPath,
    filename
)

    --------------------------------------------------------
    -- 防止同时发送多封
    --------------------------------------------------------

    if emailBusy then

        log(
            "Email busy, skip"
        )

        return
    end


    --------------------------------------------------------
    -- 构造邮件
    --------------------------------------------------------

    local email =
        buildEmail(filename)

    if not email then

        log(
            "Failed to build email"
        )

        return
    end


    emailBusy = true

    log(
        "Sending email to: "
        .. EMAIL_TO
    )


    --------------------------------------------------------
    -- msmtp
    --
    -- -t：
    -- 从 To Header 自动读取收件地址
    --------------------------------------------------------

    local task =
        hs.task.new(

            msmtpPath,

            function(
                exitCode,
                stdout,
                stderr
            )

                emailBusy = false


                --------------------------------------------
                -- 成功
                --------------------------------------------

                if exitCode == 0 then

                    log(
                        "Email sent successfully"
                    )

                    return
                end


                --------------------------------------------
                -- 失败
                --------------------------------------------

                log(
                    "Email failed, exit code="
                    .. tostring(exitCode)
                )

                if stdout
                    and stdout ~= ""
                then

                    log(
                        "msmtp stdout: "
                        .. stdout
                    )
                end

                if stderr
                    and stderr ~= ""
                then

                    log(
                        "msmtp stderr: "
                        .. stderr
                    )
                end
            end,

            {
                "-t"
            }
        )


    --------------------------------------------------------
    -- Task 创建失败
    --------------------------------------------------------

    if not task then

        emailBusy = false

        log(
            "Failed to create msmtp task"
        )

        return
    end


    --------------------------------------------------------
    -- 将完整邮件放入 msmtp stdin
    --------------------------------------------------------

    task:setInput(email)


    --------------------------------------------------------
    -- 开始发送
    --------------------------------------------------------

    local result =
        task:start()

    if not result then

        emailBusy = false

        log(
            "Failed to start msmtp"
        )
    end
end


------------------------------------------------------------
-- 拍照
------------------------------------------------------------

local function takePhoto(
    imageSnapPath,
    msmtpPath,
    reason
)

    --------------------------------------------------------
    -- 防止重复启动摄像头
    --------------------------------------------------------

    if cameraBusy then

        log(
            "Camera busy, skip"
        )

        return
    end

    cameraBusy = true


    --------------------------------------------------------
    -- 照片文件名
    --------------------------------------------------------

    local timestamp =
        os.date(
            "%Y-%m-%d_%H-%M-%S"
        )

    local filename =
        PHOTO_DIR
        .. "/wake_"
        .. timestamp
        .. ".jpg"


    log(
        "Taking photo: "
        .. filename
    )

    log(
        "Reason: "
        .. tostring(reason)
    )


    --------------------------------------------------------
    -- ImageSnap
    --------------------------------------------------------

    local task =
        hs.task.new(

            imageSnapPath,

            function(
                exitCode,
                stdout,
                stderr
            )

                cameraBusy = false


                --------------------------------------------
                -- 拍照成功
                --------------------------------------------

                if exitCode == 0 then

                    log(
                        "Photo saved: "
                        .. filename
                    )


                    ----------------------------------------
                    -- 拍照成功后发邮件
                    ----------------------------------------

                    sendEmail(
                        msmtpPath,
                        filename
                    )

                    return
                end


                --------------------------------------------
                -- 拍照失败
                --------------------------------------------

                log(
                    "Photo failed, exit code="
                    .. tostring(exitCode)
                )

                if stdout
                    and stdout ~= ""
                then

                    log(
                        "imagesnap stdout: "
                        .. stdout
                    )
                end

                if stderr
                    and stderr ~= ""
                then

                    log(
                        "imagesnap stderr: "
                        .. stderr
                    )
                end
            end,

            {
                "-q",

                "-w",
                CAMERA_WARMUP,

                filename,
            }
        )


    --------------------------------------------------------
    -- 创建任务失败
    --------------------------------------------------------

    if not task then

        cameraBusy = false

        log(
            "Failed to create imagesnap task"
        )

        return
    end


    --------------------------------------------------------
    -- 开始拍照
    --------------------------------------------------------

    local result =
        task:start()

    if not result then

        cameraBusy = false

        log(
            "Failed to start imagesnap"
        )
    end
end


------------------------------------------------------------
-- 初始化
------------------------------------------------------------

function M.start()

    --------------------------------------------------------
    -- 查找 ImageSnap
    --------------------------------------------------------

    local imageSnapPath =
        findImageSnap()

    if not imageSnapPath then

        hs.alert.show(
            "找不到 imagesnap\n"
            .. "请执行：brew install imagesnap"
        )

        log(
            "ERROR: imagesnap not found"
        )

        return
    end


    --------------------------------------------------------
    -- 查找 msmtp
    --------------------------------------------------------

    local msmtpPath =
        findMsmtp()

    if not msmtpPath then

        hs.alert.show(
            "找不到 msmtp\n"
            .. "请执行：brew install msmtp"
        )

        log(
            "ERROR: msmtp not found"
        )

        return
    end


    log(
        "ImageSnap: "
        .. imageSnapPath
    )

    log(
        "msmtp: "
        .. msmtpPath
    )


    --------------------------------------------------------
    -- 创建照片目录
    --------------------------------------------------------

    hs.execute(
        '/bin/mkdir -p "'
        .. PHOTO_DIR
        .. '"'
    )

    log(
        "Photo directory: "
        .. PHOTO_DIR
    )


    --------------------------------------------------------
    -- 锁屏 / 显示器监听
    --------------------------------------------------------

    watcher =
        hs.caffeinate.watcher.new(

            function(event)

                ------------------------------------------------
                -- Mac 进入锁屏
                --
                -- 这里只记录状态，不拍照
                ------------------------------------------------

                if event
                    == hs.caffeinate.watcher.screensDidLock
                then

                    locked = true

                    log(
                        "SCREEN LOCKED"
                    )

                    return
                end


                ------------------------------------------------
                -- Mac 解锁成功
                ------------------------------------------------

                if event
                    == hs.caffeinate.watcher.screensDidUnlock
                then

                    locked = false
                    displaySleeping = false

                    log(
                        "SCREEN UNLOCKED"
                    )

                    return
                end


                ------------------------------------------------
                -- 显示器进入黑屏 / Sleep
                ------------------------------------------------

                if event
                    == hs.caffeinate.watcher.screensDidSleep
                then

                    displaySleeping = true

                    log(
                        "DISPLAY SLEEP"
                        .. " locked="
                        .. tostring(locked)
                    )

                    return
                end


                ------------------------------------------------
                -- ★ 显示器重新被唤醒
                ------------------------------------------------

                if event
                    == hs.caffeinate.watcher.screensDidWake
                then

                    log(
                        "DISPLAY WAKE"
                        .. " locked="
                        .. tostring(locked)
                        .. " previousSleep="
                        .. tostring(displaySleeping)
                    )


                    --------------------------------------------
                    -- 必须之前真正黑屏过
                    --------------------------------------------

                    if not displaySleeping then

                        log(
                            "Display was not sleeping, skip"
                        )

                        return
                    end


                    --------------------------------------------
                    -- Wake 已经发生
                    --------------------------------------------

                    displaySleeping = false


                    --------------------------------------------
                    -- 必须仍然锁屏
                    --------------------------------------------

                    if not locked then

                        log(
                            "Screen woke while unlocked, skip"
                        )

                        return
                    end


                    --------------------------------------------
                    -- 防重复触发
                    --------------------------------------------

                    local now =
                        os.time()

                    if
                        now - lastWakeShot
                        < WAKE_COOLDOWN
                    then

                        log(
                            "Wake cooldown, skip"
                        )

                        return
                    end

                    lastWakeShot = now


                    --------------------------------------------
                    -- 稍微延迟启动摄像头
                    --------------------------------------------

                    hs.timer.doAfter(

                        TRIGGER_DELAY,

                        function()

                            ------------------------------------
                            -- 延迟期间如果已经成功解锁
                            -- 则取消拍照
                            ------------------------------------

                            if not locked then

                                log(
                                    "Already unlocked, skip photo"
                                )

                                return
                            end


                            ------------------------------------
                            -- 拍照 + 发邮件
                            ------------------------------------

                            takePhoto(
                                imageSnapPath,
                                msmtpPath,
                                "locked display woke"
                            )
                        end
                    )

                    return
                end
            end
        )


    --------------------------------------------------------
    -- 启动监听
    --------------------------------------------------------

    watcher:start()

    log(
        "Lockscreen camera started"
    )


    --------------------------------------------------------
    -- 手动测试
    --
    -- Ctrl + Option + Cmd + P
    --
    -- 功能：
    -- 立即拍一张照片，并发送邮件
    --------------------------------------------------------

    -- hs.hotkey.bind(

    --     {
    --         "ctrl",
    --         "alt",
    --         "cmd"
    --     },

    --     "P",

    --     function()

    --         hs.alert.show(
    --             "测试拍照 + 邮件"
    --         )

    --         log(
    --             "Manual photo/email test"
    --         )

    --         takePhoto(
    --             imageSnapPath,
    --             msmtpPath,
    --             "manual test"
    --         )
    --     end
    -- )
end


------------------------------------------------------------
-- 返回模块
------------------------------------------------------------

return M