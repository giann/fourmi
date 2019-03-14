-- fourmi -f example/buildlua.fourmi.plan.lua

local builtins = require "fourmi.builtins"
local plan     = require "fourmi.plan"
local task     = require "fourmi.task"
local log      = require "fourmi.log"
local sh       = builtins.sh
local var      = builtins.var
local getvar   = builtins.getvar
local __       = builtins.__
local outdated = builtins.task.outdated

var { -- User overridable settings
    PLAT       = "none",
    SYSCFLAGS  = {},
    SYSLDFLAGS = {},
    SYSLIBS    = {},
    MYCFLAGS   = {},
    MYLDFLAGS  = {},
    MYLIBS     = {},
    MYOBJS     = {},
}

var {
    PLATS   = {
        {
            value = "aix",
            label = "aix",
        },
        {
            value = "bsd",
            label = "bsd",
        },
        {
            value = "c89",
            label = "c89",
        },
        {
            value = "freebsd",
            label = "freebsd",
        },
        {
            value = "generic",
            label = "generic",
        },
        {
            value = "linux",
            label = "linux",
        },
        {
            value = "macosx",
            label = "macosx",
        },
        {
            value = "mingw",
            label = "mingw",
        },
        {
            value = "posix",
            label = "posix",
        },
        {
            value = "solaris",
            label = "solaris",
        },
    },

    CC      = "gcc -std=gnu99",
    CFLAGS  = "-O2 -Wall -Wextra -DLUA_COMPAT_5_2 @{SYSCFLAGS} @{MYCFLAGS}",
    LDFLAGS = "@{SYSLDFLAGS} @{MYLDFLAGS}",
    LIBS    = "-lm @{SYSLIBS} @{MYLIBS}",

    AR      = "ar rcu",
    RANLIB  = "ranlib",
    RM      = "rm -f",
}

var {
    LUA_A  = "liblua.a",
    LUA_T  = "lua",
    LUA_O  = "lua.o",
    LUAC_T = "luac",
    LUAC_O = "luac.o",
}

var {
    ALL_T = {
        getvar "LUA_A",
        getvar "LUA_T",
        getvar "LUAC_T",
    },
    CORE_O = {
        "lapi.o",
        "lcode.o",
        "lctype.o",
        "ldebug.o",
        "ldo.o",
        "ldump.o",
        "lfunc.o",
        "lgc.o",
        "llex.o",
        "lmem.o",
        "lobject.o",
        "lopcodes.o",
        "lparser.o",
        "lstate.o",
        "lstring.o",
        "ltable.o",
        "ltm.o",
        "lundump.o",
        "lvm.o",
        "lzio.o",
    },
    AUX_O = "lauxlib.o",
    LIB_O = {
        "lauxlib.o",
        "lbaselib.o",
        "lbitlib.o",
        "lcorolib.o",
        "ldblib.o",
        "liolib.o",
        "lmathlib.o",
        "loslib.o",
        "lstrlib.o",
        "ltablib.o",
        "lutf8lib.o",
        "loadlib.o",
        "linit.o",
    },
}

var {
    BASE_O = {
        getvar "CORE_O",
        getvar "LIB_O",
        getvar "MYOBJS",
    }
}

task "LUA_A"
    :file "@{LUA_A}"
    :requires {
        getvar "BASE_O"
    }
    :perform(function(self)
        if not sh("@{AR}", "@{LUA_A}", "@{BASE_O}")
            or not sh("@{RANLIB}", "@{LUA_A}") then
            error(__"Could not build @{LUA_A}")
        end

        return __"@{LUA_A}"
    end)

task "LUA_T"
    :file "@{LUA_T}"
    :requires {
        getvar "LUA_O",
        getvar "LUA_A"
    }
    :perform(function(self)
        local ok, msg =
            sh(
                "@{CC}", "-o", "@{LUA_T}", "@{LDFLAGS}",
                    "@{LUA_O}", "@{LUA_A}", "@{LIBS}"
            )

        if not ok then
            error(msg)
        end

        return __"@{LUA_T}"
    end)

task "LUAC_T"
    :file "@{LUAC_T}"
    :requires {
        getvar "LUAC_O",
        getvar "LUA_A"
    }
    :perform(function(self)
        local ok, msg =
            sh(
                "@{CC}", "-o", "@{LUAC_T}",
                    "@{LDFLAGS}", "@{LUAC_O}", "@{LUA_A}", "@{LIBS}"
            )

        if not ok then
            error(msg)
        end

        return __"@{LUAC_T}"
    end)

local all = task "all"
    :requires(getvar "ALL_T")
    :perf(function(self)
        log.success "All done!"
    end)

local compile = task "compile"
        :desc "Compile a single .o"
        :perf(function(self, out, original)
            log.warn("Compiling " .. out)

            local ok, msg =
                sh(
                    "@{CC}", "@{CFLAGS}", "-c", "-o", original, out
                )

            if not ok then
                error(msg)
            end

            return original
        end)

-- luacheck: push ignore 631
for file, deps in pairs {
    ["lapi.o"]     = { "lapi.c",     "lprefix.h",  "lua.h",      "luaconf.h",  "lapi.h",     "llimits.h",
                       "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldebug.h",
                        "ldo.h",     "lfunc.h",    "lgc.h",      "lstring.h",  "ltable.h",   "lundump.h",
                        "lvm.h" },
    ["lauxlib.o"]  = { "lauxlib.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h", },
    ["lbaselib.o"] = { "lbaselib.c", "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lbitlib.o"]  = { "lbitlib.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lcode.o"]    = { "lcode.c",    "lprefix.h",  "lua.h",      "luaconf.h",  "lcode.h",    "llex.h",
                       "lobject.h",  "llimits.h",  "lzio.h",     "lmem.h",     "lopcodes.h", "lparser.h",
                       "ldebug.h",   "lstate.h",   "ltm.h",      "ldo.h",      "lgc.h",      "lstring.h",
                        "ltable.h",   "lvm.h" },
    ["lcorolib.o"] = { "lcorolib.c", "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lctype.o"]   = { "lctype.c",   "lprefix.h",  "lctype.h",   "lua.h",      "luaconf.h",  "llimits.h" },
    ["ldblib.o"]   = { "ldblib.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["ldebug.o"]   = { "ldebug.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "lapi.h",     "llimits.h",
                       "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",     "lcode.h",
                        "llex.h",    "lopcodes.h", "lparser.h",  "ldebug.h",   "ldo.h",      "lfunc.h",
                        "lstring.h", "lgc.h",      "ltable.h",   "lvm.h" },
    ["ldo.o"]      = { "ldo.c",      "lprefix.h",  "lua.h",      "luaconf.h",  "lapi.h",     "llimits.h",
                       "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldebug.h",
                        "ldo.h",     "lfunc.h",    "lgc.h",      "lopcodes.h", "lparser.h",  "lstring.h",
                        "ltable.h",   "lundump.h", "lvm.h" },
    ["ldump.o"]    = { "ldump.c",    "lprefix.h",  "lua.h",      "luaconf.h",  "lobject.h",  "llimits.h",
                       "lstate.h",   "ltm.h",      "lzio.h",     "lmem.h",     "lundump.h" },
    ["lfunc.o"]    = { "lfunc.c",    "lprefix.h",  "lua.h",      "luaconf.h",  "lfunc.h",    "lobject.h",
                       "llimits.h",  "lgc.h",      "lstate.h",   "ltm.h",      "lzio.h",     "lmem.h" },
    ["lgc.o"]      = { "lgc.c",      "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lfunc.h",   "lgc.h",      "lstring.h",  "ltable.h" },
    ["linit.o"]    = { "linit.c",    "lprefix.h",  "lua.h",      "luaconf.h",  "lualib.h",   "lauxlib.h" },
    ["liolib.o"]   = { "liolib.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["llex.o"]     = { "llex.c",     "lprefix.h",  "lua.h",      "luaconf.h",  "lctype.h",   "llimits.h",
                       "ldebug.h",   "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",
                        "ldo.h",     "lgc.h",      "llex.h",     "lparser.h",  "lstring.h",  "ltable.h" },
    ["lmathlib.o"] = { "lmathlib.c", "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lmem.o"]     = { "lmem.c",     "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lgc.h" },
    ["loadlib.o"]  = { "loadlib.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lobject.o"]  = { "lobject.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lctype.h",   "llimits.h",
                       "ldebug.h",   "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",
                        "ldo.h",     "lstring.h",  "lgc.h",      "lvm.h" },
    ["lopcodes.o"] = { "lopcodes.c", "lprefix.h",  "lopcodes.h", "llimits.h",  "lua.h",      "luaconf.h" },
    ["loslib.o"]   = { "loslib.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lparser.o"]  = { "lparser.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lcode.h",    "llex.h",
                       "lobject.h",  "llimits.h",  "lzio.h",     "lmem.h",     "lopcodes.h", "lparser.h",
                        "ldebug.h",  "lstate.h",   "ltm.h",      "ldo.h",      "lfunc.h",    "lstring.h",
                        "lgc.h",      "ltable.h"    },
    ["lstate.o"]   = { "lstate.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "lapi.h",     "llimits.h",
                       "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldebug.h",
                        "ldo.h",     "lfunc.h",    "lgc.h",      "llex.h",     "lstring.h",  "ltable.h" },
    ["lstring.o"]  = { "lstring.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lstring.h", "lgc.h" },
    ["lstrlib.o"]  = { "lstrlib.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["ltable.o"]   = { "ltable.c",   "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lgc.h",     "lstring.h",  "ltable.h",   "lvm.h" },
    ["ltablib.o"]  = { "ltablib.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["ltm.o"]      = { "ltm.c",      "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lstring.h", "lgc.h",      "ltable.h",   "lvm.h" },
    ["lua.o"]      = { "lua.c",      "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["luac.o"]     = { "luac.c",     "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lobject.h",
                       "llimits.h",  "lstate.h",   "ltm.h",      "lzio.h",     "lmem.h",     "lundump.h",
                        "ldebug.h",  "lopcodes.h" },
    ["lundump.o"]  = { "lundump.c",  "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lfunc.h",   "lstring.h",  "lgc.h",      "lundump.h" },
    ["lutf8lib.o"] = { "lutf8lib.c", "lprefix.h",  "lua.h",      "luaconf.h",  "lauxlib.h",  "lualib.h" },
    ["lvm.o"]      = { "lvm.c",      "lprefix.h",  "lua.h",      "luaconf.h",  "ldebug.h",   "lstate.h",
                       "lobject.h",  "llimits.h",  "ltm.h",      "lzio.h",     "lmem.h",     "ldo.h",
                        "lfunc.h",   "lgc.h",      "lopcodes.h", "lstring.h",  "ltable.h",   "lvm.h" },
    ["lzio.o"]     = { "lzio.c",     "lprefix.h",  "lua.h",      "luaconf.h",  "llimits.h",  "lmem.h",
                       "lstate.h",   "lobject.h",  "ltm.h",      "lzio.h"      },
} do -- luacheck: pop
    local _ = (outdated(deps, file) & compile):file(file)
end

-- Use sirocco to ask for missing input
local List = require "sirocco.list"

local plat = task "plat"
    :desc "Configure for specific platform"
    :perf(function(self)
        local platform = __"@{PLAT}"

        if not platform or platform == "none" then
            platform = List {
                prompt   = "For which platform? ",
                multiple = false,
                required = true,
                items    = getvar "PLATS",
            }:ask()[1]
        end

        if platform == "aix" then
            var {
                CC         = "xlc",
                CFLAGS     = "-O2 -DLUA_USE_POSIX -DLUA_USE_DLOPEN",
                SYSLIBS    = "-ldl",
                SYSLDFLAGS = "-brtl -bexpall"
            }
        elseif platform == "bsd" then
            var {
                SYSCFLAGS = "-DLUA_USE_POSIX -DLUA_USE_DLOPEN",
                SYSLIBS   = "-Wl,-E"
            }
        elseif platform == "c89" then
            log.warn "\n*** C89 does not guarantee 64-bit integers for Lua.\n"
            var {
                SYSCFLAGS = "-DLUA_USE_C89",
                CC        = "gcc -std=c89"
            }
        elseif platform == "freebsd" then
            var {
                SYSCFLAGS ="-DLUA_USE_LINUX -DLUA_USE_READLINE -I/usr/include/edit",
                SYSLIBS   = "-Wl,-E -ledit",
                CC        = "cc"
            }
        elseif platform == "linux" then
            var {
                SYSCFLAGS = "-DLUA_USE_LINUX",
                SYSLIBS   = "-Wl,-E -ldl -lreadline"
            }
        elseif platform == "macosx" then
            var {
                SYSCFLAGS = "-DLUA_USE_MACOSX",
                SYSLIBS   = "-lreadline"
            }
        elseif platform == "mingw" then
            var {
                LUA_A      = "lua53.dll",
                LUA_T      = "lua.exe",
                LUAC_T     = "luac.exe",
                AR         = "@{CC} -shared -o",
                RANLIB     = "strip --strip-unneeded",
                SYSCFLAGS  = "-DLUA_BUILD_AS_DLL",
                SYSLIBS    = "",
                SYSLDFLAGS = "-s"
            }
        elseif platform == "posix" then
            var {
                SYSCFLAGS="-DLUA_USE_POSIX"
            }
        elseif platform == "solaris" then
            var {
                SYSCFLAGS = "-DLUA_USE_POSIX -DLUA_USE_DLOPEN -D_REENTRANT",
                SYSLIBS   = "-ldl"
            }
        end
    end)

return {
    plan "build"
        :task(
            plat .. all
        )
}
