local colors = require "term.colors"

local logColors = {
    info    = colors.white,
    warn    = colors.yellow,
    err     = colors.red,
    debug   = colors.blue,
    sys     = colors.magenta,
    success = colors.green,
}

---
-- Log something
-- @todo conf should say how much timestamp to show
-- @tparam string channel
-- @tparam string msg
local function put(_, channel, msg)
    local tm = os.date "*t"
    tm = "["
    -- .. string.format("%04d", tm.year)
    -- .. "-" .. string.format("%02d", tm.month)
    -- .. "-" .. string.format("%02d", tm.day)
    -- .. " "
    .. string.format("%02d", tm.hour)
    .. ":"
    .. string.format("%02d", tm.min)
    .. ":"
    .. string.format("%02d", tm.sec)
    .. "]  "

    local leading = msg:match "^(\n*)"
    msg = msg:gsub("^(\n*)", "")
    msg = msg:gsub("\n", "\n" .. tm)

    print(
        leading ..
        colors.dim(colors.cyan(
            tm
        ))
        .. logColors[channel](msg)
    )
end

local log = setmetatable({}, {
    __call = put
})

for channel, _ in pairs(logColors) do
    log[channel] = function(msg)
        log(channel, msg)
    end
end

return log
