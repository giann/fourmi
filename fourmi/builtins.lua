---
-- Common helpers and basic tasks
-- @module fourmi.builtins
-- @author Benoit Giannangeli
-- @license MIT
-- @copyright Benoit Giannangeli 2019

local task   = require "fourmi.task"
local colors = require "term.colors"
local lfs    = require "lfs"

local builtins = {}

---
-- Runs a command captures stderr and returns it as error message
-- @tparam string program command to run
-- @tparam string ... program arguments If an arguments contains spaces it'll be quoted
-- @treturn[1] boolean true if command succeded
-- @treturn[2] string message in case of failure
function builtins.sh(program, ...)
    local arguments = {...}
    for i, arg in ipairs(arguments) do
        local sarg = tostring(arg)

        arguments[i] = sarg:match "[^%s]%s+[^%s]"
            and string.format("%q", sarg)
            or sarg
    end

    local command =
        program
        .. " " .. table.concat(arguments, " ")

    local stderr = os.tmpname()

    print(colors.magenta("🐢 " .. command))

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
-- String interpolation helper
-- `${VARIABLE}` are interpolated with `os.getenv "VARIABLE"`, `#{variable}` are interpolated with
-- value named `variable` in `context` or caller locals or `_G`
-- @tparam string str String to interpolate
-- @tparam[opt] table context Table in which to search variables to interpolates
-- @treturn string
function builtins.__(str, context)
    -- Interpolate environment variables
    local env
    repeat
        env = str:match "%${([A-Za-z_]+[A-Za-z_0-9]*)}"

        str = env
            and str:gsub("%${" .. env .. "}", os.getenv(env) or "")
            or str
    until not env

    -- Interpolate variables

    -- No context provided, build one from caller locals
    if not context then
        context = {}
        local l = 1
        local key, value

        repeat
            key, value = debug.getlocal(2, l)
            l = l + 1

            if key ~= nil then
                context[key] = value
            end
        until not key
    end

    local var
    repeat
        var = str:match "#{([A-Za-z_]+[A-Za-z_0-9]*)}"

        str = var
            and str:gsub("#{" .. var .. "}", tostring(context[var] or _G[var]))
            or str
    until not var

    return str
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
                print(colors.yellow(tsk.options.successMessage or command .. " succeeded"))
            elseif not tsk.options.ignoreError then
                error(colors.yellow(tsk.options.failureMessage or command .. " failed: " .. message))
            else
                print(colors.yellow(tsk.options.failureMessage or command .. " failed"))
            end

            return ok, message
        end)
end

--- A task that list files
builtins.task.ls = task "ls"
    :description "List files in a directory"
    :perform(function(self)
        local dir = builtins.__(self.options[1])

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
        local dest = builtins.__(self.options[1]) .. "/" .. file:match "([^/]*)$"

        local ok, err = os.rename(file, dest)

        if ok then
            print(colors.yellow("Moved `" .. file .. "` to `" .. dest .. "`"))
            return dest
        else
            error(err)
        end
    end)

return builtins
