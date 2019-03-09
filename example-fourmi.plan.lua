-- Example fourmi.lua

local fourmi   = require "fourmi"
local builtins = require "fourmi.builtins"
local plan     = fourmi.plan
local task     = fourmi.task
local __       = builtins.__
local sh       = builtins.sh
local ls       = builtins.task.ls
local mv       = builtins.task.mv
local empty    = builtins.task.empty
local outdated = builtins.task.outdated

-- Define tasks

local minify = task "minify"
    :description "Minify lua files with luamin"
    :perform(function(self, file)
        local minifiedFile = __"~/.fourmi/tmp/"
            .. file
                :match "([^/]*)$"

        if not sh("luamin", "-f", file, ">", minifiedFile) then
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
            ls("./fourmi", "%.lua$")
                * (outdated "~/tmp-code/#{original}.gz" & minify >> gzip >> mv "~/tmp-code")
        ),

    plan "clean"
        :description "Cleanup"
        :task(
            empty "~/tmp-code"
        )
}