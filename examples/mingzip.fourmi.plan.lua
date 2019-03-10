-- fourmi -f example/mingzip.fourmi.plan.lua

-- Example fourmi.lua

local builtins = require "fourmi.builtins"
local plan     = require "fourmi.plan"
local task     = require "fourmi.task"
local __       = builtins.__
local empty    = builtins.task.empty
local ls       = builtins.task.ls
local mv       = builtins.task.mv
local outdated = builtins.task.outdated
local sh       = builtins.sh
local var      = builtins.var

-- Define vars

var("min", "luamin")
var("src", "./fourmi")
var("dest", __"~/tmp-code")

-- Define tasks

local minify = task "minify"
    :description "Minify lua files with luamin"
    :perform(function(self, file)
        local minifiedFile = __"@{tmp}/"
            .. file
                :match "([^/]*)$"

        if not sh("@{min}", "-f", file, ">", minifiedFile) then
            error("Could not create minified file at: " .. minifiedFile)
        end

        return minifiedFile
    end)

local gzip = task "gzip"
    :description "Zip file"
    :perform(function(self, file)
        sh(
            "gzip", "-k", "-f", file
        )

        return file .. ".gz"
    end)

-- Define plans

return {
    plan "all"
        :description "Minify and gzip lua files"
        :task(
            ls("@{src}", "%.lua$")
                * (outdated "@{dest}/#{original}.gz"
                    & minify >> gzip >> mv "@{dest}")
        ),

    plan "clean"
        :description "Cleanup"
        :task(
            empty "@{dest}"
        )
}