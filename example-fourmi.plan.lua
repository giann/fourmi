-- Example fourmi.lua

local fourmi   = require "fourmi"
local builtins = require "fourmi.builtins"
local plan     = fourmi.plan
local task     = fourmi.task
local __       = builtins.__
local sh       = builtins.sh
local ls       = builtins.task.ls
local mv       = builtins.task.mv
local shtask   = builtins.task.sh

-- Define tasks

local minify = task "minify"
    :description "Minify lua files with luamin"
    :perform(function(self, file)
        local minifiedFile = __"${HOME}/.fourmi/tmp/"
            .. file
                :match "([^/]*)$"
                :gsub("%.lua$", ".min.lua")

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
                * (minify >> gzip >> mv "${HOME}/tmp-code")
        ),

    plan "clean"
        :description "Cleanup"
        :task(
            shtask("rm", __"${HOME}/tmp-code/*.gz")
        )
}