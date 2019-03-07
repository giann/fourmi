local colors = require "term.colors"

local function parallel(functions, ...)
    error "NYI"
end

local taskMt

local function task(name)
    return setmetatable({
        name = name,
        run = function() end,
        options = {}
    }, taskMt)
end

taskMt = {
    -- t1 / t2: t1 in parallel of t2
    __div = function(task1, task2)
        return task("(" .. task1.name .. " / " .. task2.name .. ")")
            :perform(function(self, ...)
                return parallel({task1.run, task2.run}, ...)
            end)
            :option("quiet", true)
    end,

    -- t1 .. t2: t1 then t2
    __concat = function(task1, task2)
        return task("(" .. task1.name .. " .. " .. task2.name .. ")")
            :perform(function(self, ...)
                return task1(...),
                    task2(...)
            end)
            :option("quiet", true)
    end,

    -- t1 & t2: t2 if t1 returns thruthy value
    __band = function(task1, task2)
        return task("(" .. task1.name .. " & " .. task2.name .. ")")
            :perform(function(self, ...)
                local result1 = task1(...)

                if result1 then
                    return result1, task2(...)
                end
            end)
            :option("quiet", true)
    end,

    -- t1 | t2: t2 only if t1 returns falsy value
    __bor = function(task1, task2)
        return task("(" .. task1.name .. " | " .. task2.name .. ")")
            :perform(function(self, ...)
                return task1(...) or task2(...)
            end)
            :option("quiet", true)
    end,

    -- t1 >> t2: t1 output to t2 input
    __shr = function(task1, task2)
        return task("(" .. task1.name .. " >> " .. task2.name .. ")")
            :perform(function(self, ...)
                return task2(task1(...))
            end)
            :option("quiet", true)
    end,

    -- t2 << t1: same
    __shl = function(task2, task1)
        return task2 >> task1
    end,

    -- t1 ~ t2: if t1 has output, give it to t2
    __bxor = function(task1, task2)
        return task("(" .. task1.name .. " ~ " .. task2.name .. ")")
            :perform(function(self, ...)
                local t1Res = {task1(...)}

                return #t1Res > 0 and task2(table.unpack(t1Res))
            end)
            :option("quiet", true)
    end,

    -- t1 * t2: do t2 for all output of t1
    __mul = function(task1, task2)
        return task("(" .. task1.name .. " * " .. task2.name .. ")")
            :perform(function(self, ...)
                local results = {}

                for _, result in ipairs {task1(...)} do
                    local t2Res = task2(result)

                    if t2Res ~= nil then
                        table.insert(
                            results,
                            t2Res
                        )
                    end
                end

                return table.unpack(results)
            end)
            :option("quiet", true)
    end,

    -- t1 ^ (condition): do t1 if condition (expression or function to be evaluated) is met
    __pow = function(task1, condition)
        return task(task1.name  .. "^(" .. tostring(condition) .. ")")
            :perform(function(self, ...)
                local ok, message

                if type(condition) == "function" then
                    ok, message = condition(...)
                else
                    ok = condition
                end

                if ok then
                    return task1(...)
                else
                    local args = {}
                    for _, arg in ipairs {...} do
                        table.insert(args, tostring(arg))
                    end

                    print(colors.yellow(table.concat(args, " ") .. " ignored: " .. message))
                end
            end)
            :option("quiet", true)
    end,

    -- Run the task
    __call = function(self, ...)
        local time = os.clock()

        if not self.options.quiet then
            print(
                colors.green("\n🌿 Running task "
                    .. colors.bright(colors.blue(self.name))
                    .. colors.green .. " for " .. colors.bright(colors.yellow(table.concat({...}, ", "))))
            )
        end

        local results = {self:run(...)}

        if not self.options.quiet then
            print(
                "\tTask " .. colors.bright(colors.blue(self.name)) .. " completed with "
                .. colors.yellow(#results) .. " result" .. (#results > 1 and "s" or "")
                .. " in " .. colors.yellow(string.format("%.03f", os.clock() - time) .. "s")
            )

            for _, res in ipairs(results) do
                print("\t\t→ " .. colors.dim(colors.cyan(tostring(res))))
            end
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

return task
