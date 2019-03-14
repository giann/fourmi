---
-- Common helpers and basic tasks
-- @module fourmi.builtins
-- @author Benoit Giannangeli
-- @license MIT
-- @copyright Benoit Giannangeli 2019

local task    = require "fourmi.task"
local log     = require "fourmi.log"
local colors  = require "term.colors"
local lfs     = require "lfs"
local utils   = require "fourmi.utils"
local __      = utils.__

local builtins = {
    __ = __
}

---
-- Runs a command captures stderr and returns it as error message
-- @tparam string program command to run
-- @tparam string ... program arguments If an arguments contains spaces it'll be quoted
-- @treturn[1] boolean true if command succeded
-- @treturn[2] string message in case of failure
function builtins.sh(program, ...)
    program = __(program)

    local arguments = {...}
    for i, arg in ipairs(arguments) do
        local sarg = __(tostring(arg))

        arguments[i] = sarg
            -- sarg:match "[^%s]%s+[^%s]"
            --     and string.format("%q", sarg)
            --     or sarg
    end

    arguments = table.concat(arguments, " ")

    local command =
        program .. " " .. arguments

    local stderr = os.tmpname()

    log.sys("$ " .. colors.bright(colors.magenta(program)) .. " " .. colors.magenta(arguments))

    -- spawn program and yield when waitpid returns
    local ok, exit, status = os.execute(
        command .. " 2> " .. stderr,
        "r"
    )

    if ok and exit == "exit" and status == 0 then
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
function builtins.outdated(original, target)
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

---
-- Set a fourmi variable
-- @tparam string|table key or table of (key, value)
-- @tparam string|number|boolean value
function builtins.var(key, value)
    if type(key) ~= "table" then
        _G.__fourmi.vars[key] = type(value) == "string"
            and __(value)
            or value
    else
        for k, v in pairs(key) do
            _G.__fourmi.vars[k] = type(v) == "string"
                and __(v)
                or v
        end
    end
end

function builtins.getvar(key)
    return _G.__fourmi.vars[key]
end

--- Builtin tasks
builtins.task = {}

---
-- Create a task that runs a single shell command
-- @tparam string command
-- @tparam string ...
-- @treturn task
builtins.task.sh = function(command, ...)
    local args = {...}

    return task("$ " .. command .. " ", table.concat(args, " "))
        :perform(function(tsk)
            local ok, message = builtins.sh(command, table.unpack(args))

            if ok then
                log.warn(tsk.properties.successMessage or command .. " succeeded")
            elseif not tsk.properties.ignoreError then
                error(colors.yellow(tsk.properties.failureMessage or command .. " failed: " .. message))
            else
                log.warn(tsk.properties.failureMessage or command .. " failed")
            end

            return ok, message
        end)
end

--- A task that list files
builtins.task.ls = task "ls"
    :description "List files in a directory"
    :perform(function(self)
        local dir = __(self.options[1])

        local items = {}

        for item in lfs.dir(dir) do
            if not self.options[2]
                or item:match(self.options[2]) then
                table.insert(items, dir .. "/" .. item)
            end
        end

        return table.unpack(items)
    end)

-- A task that moves a file
builtins.task.mv = task "mv"
    :description "Move a file"
    :perform(function(self, file)
        file = __(file)
        local dest = __(self.options[1]) .. "/" .. file:match "([^/]*)$"

        local ok, err = os.rename(file, dest)

        if ok then
            log.warn("Moved `" .. file .. "` to `" .. dest .. "`")
            return dest
        else
            error("Could not move `" .. file .. "` to `" .. dest .. "`: " .. err)
        end
    end)

--- Empty files of a directory
builtins.task.empty = task "empty"
    :description "Empty files of a directory"
    :perform(function(self)
        local dir = __(self.options[1])
        local kind = lfs.attributes(dir).mode

        if kind == "directory" then
            local count = 0
            for file in lfs.dir(dir) do
                file = dir .. "/" .. file
                if (lfs.attributes(file) or {}).mode == "file" then
                    local ok, err = os.remove(file)

                    if ok then
                        log.warn("\t`" .. file .. "` removed")
                        count = count + 1
                    else
                        log.err("\tCould not remove `" .. file .. "`: " .. err)
                    end
                end
            end

            if count > 0 then
                log.warn("Removed " .. count .. " files in `" .. dir .. "`")
            else
                log.success("Nothing to remove")
            end
        else
            error("`" .. dir .. "` is not a directory")
        end
    end)

--- Filter out up-to-date files
builtins.task.outdated = task "outdated"
    :description "Filter out up-to-date files"
    :property("quiet", true)
    :perform(function(self, original)
        original = original or self.options[1]
        local dest = original and self.options[1] or self.options[2]

        dest = dest and __(dest, {
            original = original:match "([^/]*)$"
        })

        if builtins.outdated(original or dest, original and dest or nil) then
            return original
        end
    end)

--- A task that returns true if original outdated with one of deps
builtins.task.outdated = task "outdated"
    :description "Returns true if a file must be updated"
    :property("quiet", true)
    :perform(function(self)
        local originals = type(self.options[1]) ~= "table" and { self.options[1] } or self.options[1]
        local targets   = type(self.options[2]) ~= "table" and { self.options[2] } or self.options[2]

        for _, original in ipairs(originals) do
            for _, target in ipairs(targets) do
                if builtins.outdated(original, target) then
                    return original, target
                end
            end
        end

        return false
    end)

return builtins
