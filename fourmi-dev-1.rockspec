
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
        ["fourmi"] = "croissant/init.lua",
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
}
