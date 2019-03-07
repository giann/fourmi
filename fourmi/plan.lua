local colors = require "term.colors"

local planMt = {

    __call = function(self, arguments)
        local time = os.clock()

        if not arguments.quiet then
            print(
                colors.green("\n🐜 Running plan "
                    .. colors.bright(colors.blue(self.name)))
            )
        end

        if not self.task then
            error("Task is undefined for plan " .. self.name)
        end

        local results = {self.__task(self:processArgs(arguments))}

        if not arguments.quiet then
            print(
                "\n🐜 Plan " .. colors.bright(colors.blue(self.name)) .. " completed with "
                .. colors.yellow(#results) .. " result" .. (#results > 1 and "s" or "")
                .. " in " .. colors.yellow(string.format("%.03f", os.clock() - time) .. "s")
            )

            for _, res in ipairs(results) do
                print("\t\t→ " .. colors.dim(colors.cyan(tostring(res))))
            end
        end
    end,

    __index = {

        processArgs = function(self, arguments)
            -- Assume it's the default definition
            return table.unpack(arguments.arguments or {})
        end,

        task = function(self, task)
            self.__task = task

            return self
        end,

        argdef = function(self, argdef)
            self.__argdef = argdef

            return self
        end,

    }

}

local function plan(name)
    return setmetatable({
        name = name,
        __argdef = function(self, parser)
            parser:argument "arguments"
                :args "*"
        end,
    }, planMt)
end

return plan
