---
-- Main fourmi module
-- @module fourmi
-- @author Benoit Giannangeli
-- @license MIT
-- @copyright Benoit Giannangeli 2019

local colors = require "term.colors"
local lfs    = require "lfs"

local fourmi = {
    task = require "fourmi.task",
    plan = require "fourmi.plan",
}

---
-- Runs a command captures stderr and returns it as error message
-- @tparam string program command to run
-- @tparam string ... program arguments
-- @treturn[1] boolean true if command succeded
-- @treturn[2] string message in case of failure
function fourmi.sh(program, ...)
    local arguments = {...}
    for i, arg in ipairs(arguments) do
        local sarg = tostring(arg)

        arguments[i] = sarg:match "[^%s]%s+[^%s]"
            and string.format("%q", sarg)
            or sarg
    end

    local command =
        "/usr/bin/env "
        .. program
        .. " " .. table.concat(arguments, " ")

    local stderr = os.tmpname()

    print(colors.magenta("🐢 " .. command))

    -- spawn program and yield when waitpid returns
    local ok, _, status = os.execute(
        command .. " 2> " .. stderr,
        "r"
    )

    if ok then
        return true
    else
        local err = io.open(stderr, "r")
        local failure = err:read "*a"

        err:close()
        os.remove(stderr)

        return false,
            "Command `" .. command .. "` failed with status code, " .. status .. ": " .. failure
    end
end

---
-- Returns true if a file is outdated
-- @tparam string original If alone checks that it exists
-- @tparam string target Outdated if not present or older than original
function fourmi.outdated(original, target)
    if original and target then
        local originalAttr = lfs.attributes(original)
        local targetAttr = lfs.attributes(target)

        return not targetAttr or originalAttr.change > targetAttr.change,
            target .. " already present and up-to-date"
    elseif original then
        return not lfs.attributes(original),
            original .. " already present"
    end
end

return fourmi
