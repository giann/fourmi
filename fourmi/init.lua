---
-- Main fourmi module
-- @module fourmi
-- @author Benoit Giannangeli
-- @license MIT
-- @copyright Benoit Giannangeli 2019

local colors = require "term.colors"

local fourmi = {
    task     = require "fourmi.task",
    plan     = require "fourmi.plan",
    builtins = require "fourmi.builtins"
}

---
-- Create a task that runs a single shell command
-- @tparam string command
-- @tparam string ...
-- @treturn task
fourmi.builtins.shtask = function(command, ...)
    local args = {...}

    return fourmi.task("$ " .. command .. " ", table.concat(args, " "))
        :perform(function(tsk)
            local ok, message = fourmi.builtins.sh(command, table.unpack(args))

            if ok then
                print(colors.yellow(tsk.options.successMessage or command .. " succeeded"))
            elseif not tsk.options.ignoreError then
                error(colors.yellow(tsk.options.failureMessage or command .. " failed: " .. message))
            else
                print(colors.yellow(tsk.options.failureMessage or command .. " failed"))
            end

            return ok, message
        end)
end

return fourmi
