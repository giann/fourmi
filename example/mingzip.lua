local lfs   = require "lfs"
local fourmi = require "fourmi"
local utils = require "fourmi.utils"
local task  = fourmi.task
local sh    = fourmi.sh

local ls = task "ls"
    :description "List files in a directory"
    :perform(function(self, dir)
        return lfs.dir(dir)
    end)

local filter = task "filter"
    :description "Return input if matches pattern"
    :perform(function(self, item)
        return item:match(self.options.pattern or ".*") and item
    end)

local prefix = task "prefix"
    :description "Add a prefix to input element"
    :perform(function(self, element)
        return (self.options.prefix or "") .. element
    end)

local minify = task "minify"
    :description "Minify lua files with luamin"
    :perform(function(self, ...)
        local minified = {}

        for _, file in ipairs {...} do
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


            table.insert(minified, minifiedFile)
        end

        return table.unpack(minified)
    end)

local gzip = task "gzip"
    :description "Zip files"
    :perform(function(self, ...)
        for _, file in ipairs {...} do
            sh(
                "gzip",
                "-k",
                "-f",
                file
            )
        end

        return table.unpack(utils.table.map({...}, function(_, file)
            return file .. ".gzip"
        end))
    end)

fourmi.banner()

local path = ({...})[1]

return (
    ls
    *
    (filter:opt {
            pattern = "%.lua$",
            quiet = true
        }
        ~ (prefix:opt {
                prefix = path .. "/",
                quiet = true
            }
            >> minify:opt("out", os.getenv "HOME" .. "/tmp-code")
                >> gzip))
)(path)
