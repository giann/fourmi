local colors = require "term.colors"

local function banner()
    print(
        "🐜  Fourmi 0.0.1 (C) 2019 Benoit Giannangeli\n"
    )
end

local function sh(program, ...)
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

    local stdout, stderr = os.tmpname(), os.tmpname()

    print(colors.magenta("🐢 " .. command))

    -- spawn program and yield when waitpid returns
    local ok, _, status = os.execute(
        command
        .. " > " .. stdout .. " 2> " .. stderr,
        "r"
    )

    if ok then
        local out = io.open(stdout, "r")
        local result = out:read "*a"

        out:close()
        os.remove(stdout)

        return result
    else
        local err = io.open(stderr, "r")
        local failure = err:read "*a"

        err:close()
        os.remove(stderr)

        error("Command `" .. command .. "` failed with status code, " .. status .. ": " .. failure)
    end

    return stdout
end

local function parallel(functions, ...)
    error "NYI"
end

local taskMt

local function task(name, run)
    return setmetatable({
        name = name,
        run = run,
        options = {}
    }, taskMt)
end

taskMt = {
    -- t1 / t2: t1 in parallel of t2
    __div = function(task1, task2)
        return task(
            "(" .. task1.name .. " / " .. task2.name .. ")",
            function(self, ...)
                return parallel({task1.run, task2.run}, ...)
            end
        ):option("quiet", true)
    end,

    -- t1 .. t2: t1 then t2
    __concat = function(task1, task2)
        return task(
            "(" .. task1.name .. " .. " .. task2.name .. ")",
            function(self, ...)
                return task1(...),
                    task2(...)
            end
        ):option("quiet", true)
    end,

    -- t1 & t2: t2 if t1 succeeds
    __band = function(task1, task2)
        return task(
            "(" .. task1.name .. " & " .. task2.name .. ")",
            function(self, ...)
                local result1 = task1(...)

                if result1 then
                    return result1, task2(...)
                end
            end
        ):option("quiet", true)
    end,

    -- t1 | t2: t2 only if t1 fails
    __bor = function(task1, task2)
        return task(
            "(" .. task1.name .. " | " .. task2.name .. ")",
            function(self, ...)
                return task1(...) or task2(...)
            end
        ):option("quiet", true)
    end,

    -- t1 >> t2: t1 output to t2 input
    __shr = function(task1, task2)
        return task(
            "(" .. task1.name .. " >> " .. task2.name .. ")",
            function(self, ...)
                return task2(task1(...))
            end
        ):option("quiet", true)
    end,

    -- t2 << t1: same
    __shl = function(task2, task1)
        return task2 >> task1
    end,

    -- t1 ~ t2: if t1 has output, give it to t2
    __bxor = function(task1, task2)
        return task(
            "(" .. task1.name .. " ~ " .. task2.name .. ")",
            function(self, ...)
                local t1Res = {task1(...)}

                return #t1Res > 0 and task2(table.unpack(t1Res))
            end
        ):option("quiet", true)
    end,

    -- t1 * t2: do t2 for all output of t1
    -- t1 should return an iterator
    __mul = function(task1, task2)
        return task(
            "(" .. task1.name .. " * " .. task2.name .. ")",
            function(self, ...)
                local results = {}

                for result in task1(...) do
                    local t2Res = task2(result)

                    if t2Res ~= nil then
                        table.insert(
                            results,
                            t2Res
                        )
                    end
                end

                return table.unpack(results)
            end
        ):option("quiet", true)
    end,

    -- Run the task
    __call = function(self, ...)
        if not self.options.quiet then
            print(
                colors.green("🐜 Running task `" .. self.name .. "` for " .. table.concat({...}, ", "))
            )
        end

        local results = {self:run(...)}

        if not self.options.quiet then
            print(
                "Task `" .. self.name .. "` over with "
                .. colors.yellow(#results) .. " result" .. (#results > 1 and "s" or "")
            )
        end

        return table.unpack(results)
    end,

    __index = {
        description = function(self, description)
            self.description = description

            return self
        end,

        perform = function(self, fn)
            self.run = fn

            return self
        end,

        option = function(self, name, value)
            local options = type(name) == "table"
                and name or {[name] = value}

            for n, v in pairs(options) do
                self.options[n] = v
            end

            return self
        end,

        -- Aliases
        opt = function(self, ...)
            return self:option(...)
        end,

        perf = function(self, ...)
            return self:perform(...)
        end,

        desc = function(self, ...)
            return self:description(...)
        end,
    },

    __tostring = function(self)
        return "Task " .. self.name
    end
}

return {
    task = task,
    sh   = sh,
    banner = banner
}
