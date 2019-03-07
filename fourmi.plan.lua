-- Example fourmi.lua

local colors = require "term.colors"
local lfs    = require "lfs"
local fourmi = require "fourmi"
local plan   = fourmi.plan
local task   = fourmi.task
local sh     = fourmi.sh

-- Define tasks

local ls = task "ls"
    :description "List files in a directory"
    :perform(function(self, dir)
        local items = {}

        for item in lfs.dir(dir) do
            if not self.options.mask
                or item:match(self.options.mask) then
                table.insert(items, dir .. "/" .. item)
            end
        end

        return table.unpack(items)
    end)

local minify = task "minify"
    :description "Minify lua files with luamin"
    :perform(function(self, file)
        local minifiedFile =
            self.options.out .. "/" .. file:gsub("%.lua$", ".min.lua")

        local fd = io.open(minifiedFile, "w")

        if fd then
            fd:write(
                sh(
                    "luamin",
                    "-f", file
                )
            )

            fd:close()
        else
            error("Could not create minified file at: " .. minifiedFile)
        end

        return minifiedFile
    end)

local gzip = task "gzip"
    :description "Zip files"
    :perform(function(self, file)
        sh(
            "gzip",
            "-k",
            "-f",
            file
        )


        return file .. ".gz"
    end)

local rm = task "rm"
    :description "Delete files"
    :perform(function(self, ...)
        for _, file in ipairs {...} do
            local ok, message = os.remove(
                (self.options.dir and self.options.dir .. "/" or "")
                .. file
            )

            if not ok then
                print(
                    colors.red("Could not delete file ")
                    .. colors.yellow(file)
                    .. ": "
                    .. colors.red(tostring(message))
                )
            end
        end
    end)

local map = task "map"
    :description "Transform input"
    :perform(function(self, ...)
        local results = {}

        for _, element in ipairs {...} do
            table.insert(results, self.options.map(element))
        end

        return table.unpack(results)
    end)

-- Define plans

return {
    plan "default"
        :task(
            ls:opt("mask", "%.lua$")
            *
            (
                (minify:opt("out", os.getenv "HOME" .. "/tmp-code") >> gzip)
                    ^ function(file)
                        local filename = os.getenv "HOME" .. "/tmp-code/" .. file:gsub("%.lua$", ".min.lua.gz")

                        return not lfs.attributes(filename),
                            filename .. " already present"
                    end
            )
        ),

    plan "clean"
        :task(
            (
                ls:opt("mask", "%.lua$")
                >>
                map:opt("map" , function(element)
                    local mapped = element:gsub("%.lua$", ".min.lua.gz")
                    return mapped
                end)
            )
            *
            rm:opt("dir", os.getenv "HOME" .. "/tmp-code")
        )
}
