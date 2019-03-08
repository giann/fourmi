
package = "fourmi"
version = "dev-1"
rockspec_format = "3.0"

source = {
    url = "git://github.com/giann/fourmi",
}

description = {
    summary  = "🐜 A task runner",
    homepage = "https://github.com/giann/fourmi",
    license  = "MIT/X11",
}

build = {
    modules = {
        ["fourmi"]          = "fourmi/init.lua",
        ["fourmi.plan"]     = "fourmi/plan.lua",
        ["fourmi.task"]     = "fourmi/task.lua",
        ["fourmi.builtins"] = "fourmi/builtins.lua",
    },
    type = "builtin",
    install = {
        bin = {
            "bin/fourmi"
        }
    }
}

dependencies = {
    "lua >= 5.3",
    "lua-term >= 0.7-1",
    "argparse >= 0.6.0-1",
    "luafilesystem >= 1.7.0-2",
}
