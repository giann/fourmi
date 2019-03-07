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

        local results = {self.__task(table.unpack(arguments.arguments or {}))}

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

        task = function(self, task)
            self.__task = task

            return self
        end,

    }

}

local function plan(name)
    return setmetatable({
        name = name,
    }, planMt)
end

return plan
