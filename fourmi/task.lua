---
-- Task module
-- @classmod fourmi.task
-- @author Benoit Giannangeli
-- @license MIT
-- @copyright Benoit Giannangeli 2019

local colors = require "term.colors"

local function parallel(functions, ...)
    error "NYI"
end

local taskMt

---
-- Task constructor
-- @tparam string name Task's name
-- @treturn task New task
local function task(name)
    return setmetatable({
        __name     = name,
        run        = function() end,
        options    = {},
        properties = {}
    }, taskMt)
end

taskMt = {
    ---
    -- Runs task1 in parallel of task2
    -- @todo NYI
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __div = function(task1, task2)
        return task("(" .. task1.__name .. " / " .. task2.__name .. ")")
            :perform(function(self, ...)
                return parallel({task1.run, task2.run}, ...)
            end)
            :property("quiet", true)
    end,

    ---
    -- Runs task1 then task2
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __concat = function(task1, task2)
        return task("(" .. task1.__name .. " .. " .. task2.__name .. ")")
            :perform(function(self, ...)
                return task1:run(...),
                    task2:run(...)
            end)
            :property("quiet", true)
    end,

    ---
    -- Runs task2 with task1 ouput if any and first output is truthy value
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __band = function(task1, task2)
        return task("(" .. task1.__name .. " & " .. task2.__name .. ")")
            :perform(function(self, ...)
                local resultask1 = table.pack(task1:run(...))

                if resultask1 and resultask1[1] then
                    return task2:run(table.unpack(resultask1))
                end
            end)
            :property("quiet", true)
    end,

    ---
    -- Runs task2 only if task1 returns falsy value
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __bor = function(task1, task2)
        return task("(" .. task1.__name .. " | " .. task2.__name .. ")")
            :perform(function(self, ...)
                return task1:run(...) or task2:run(...)
            end)
            :property("quiet", true)
    end,

    ---
    -- Pipes task1's output to task2 input
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __shr = function(task1, task2)
        return task("(" .. task1.__name .. " >> " .. task2.__name .. ")")
            :perform(function(self, ...)
                return task2:run(task1:run(...))
            end)
            :property("quiet", true)
    end,

    ---
    -- Pipes task2's output to task1 input
    -- @tparam task task2
    -- @tparam task task1
    -- @treturn task
    __shl = function(task2, task1)
        return task2 >> task1
    end,

    ---
    -- Runs task2 for each output of task1, task2 is silenced
    -- @tparam task task1
    -- @tparam task task2
    -- @treturn task
    __mul = function(task1, task2)
        return task("(" .. task1.__name .. " * " .. task2.__name .. ")")
            :perform(function(self, ...)
                local results = {}

                for _, result in ipairs {task1:run(...)} do
                    local task2Res = task2:run(result)

                    if task2Res ~= nil then
                        table.insert(
                            results,
                            task2Res
                        )
                    end
                end

                return table.unpack(results)
            end)
            :property("quiet", true)
    end,

    ---
    -- Runs task1 if a condition is met
    -- @tparam task task1
    -- @tparam boolean|function condition If a function, will be run when resulting task is invoked
    -- @treturn task
    __pow = function(task1, condition)
        return task(task1.__name  .. " ^ (" .. tostring(condition) .. ")")
            :perform(function(self, ...)
                local ok, message

                if type(condition) == "function" then
                    ok, message = condition(...)
                else
                    ok = condition
                end

                if ok then
                    return task1:run(...)
                else
                    local args = {}
                    for _, arg in ipairs {...} do
                        table.insert(args, tostring(arg))
                    end

                    print(colors.yellow("\nTask " .. task1.__name .. " ignored: " .. message))
                end
            end)
            :property("quiet", true)
    end,

    ---
    -- Set options
    -- @tparam task self
    -- @param ... Task input
    __call = function(self, ...)
        self.options = {...}

        return self
    end,

    __index = {
        ---
        -- Set task's description
        -- @tparam task self
        -- @tparam string description
        description = function(self, description)
            self.__description = description

            return self
        end,

        ---
        -- Set task's name
        -- @tparam task self
        -- @tparam string name
        name = function(self, name)
            self.__name = name

            return self
        end,

        ---
        -- Set task's action
        -- @tparam task self
        -- @tparam string fn function
        perform = function(self, fn)
            self.run = function(self, ...)
                local time = os.clock()

                if not self.properties.quiet then
                    print(
                        colors.green("\n🌿 Running task "
                            .. colors.bright(colors.blue(self.__name))
                            .. colors.green .. " for " .. colors.bright(colors.yellow(table.concat({...}, ", "))))
                        .. (self.__description and colors.dim(colors.cyan("\n" .. self.__description)) or "")
                    )
                end

                local results = {fn(self, ...)}

                if not self.properties.quiet then
                    print(
                        "  Task " .. colors.bright(colors.blue(self.__name)) .. " completed with "
                        .. colors.yellow(#results) .. " result" .. (#results > 1 and "s" or "")
                        .. " in " .. colors.yellow(string.format("%.03f", os.clock() - time) .. "s")
                    )

                    for _, res in ipairs(results) do
                        print("\t→ " .. colors.dim(colors.cyan(tostring(res))))
                    end
                end

                return table.unpack(results)
            end

            return self
        end,

        ---
        -- Set a property
        -- @tparam task self
        -- @tparam string name Option's name
        -- @param value Option's value
        property = function(self, name, value)
            local properties = type(name) == "table"
                and name or {[name] = value}

            for n, v in pairs(properties) do
                self.properties[n] = v
            end

            return self
        end,

        prop = function(self, ...)
            return self:property(...)
        end,

        perf = function(self, ...)
            return self:perform(...)
        end,

        desc = function(self, ...)
            return self:description(...)
        end,
    },

    __tostring = function(self)
        return "Task " .. self.__name
    end
}

-- Non operators aliases
taskMt.parallelTo = taskMt.__div
taskMt.after      = taskMt.__concat
taskMt.success    = taskMt.__band
taskMt.failure    = taskMt.__bor
taskMt.into       = taskMt.__shr
taskMt.ouput      = taskMt.__bxor
taskMt.each       = taskMt.__mul
taskMt.meet       = taskMt.__pow

return task
