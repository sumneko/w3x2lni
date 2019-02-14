local lm = require "luamake"

lm.rootdir = 'c++/bee.lua/3rd/lua/src/'

lm:shared_library 'lua54' {
    sources = {
        "*.c",
        "!lua.c",
        "!luac.c",
        "../utf8/utf8_crt.c",
    },
    defines = {
        "LUA_BUILD_AS_DLL",
        "LUAI_MAXCCALLS=200"
    }
}

lm.rootdir = 'c++/src/'

lm:executable 'w3x2lni' {
    sources = {
        'w3x2lni/main_gui.cpp',
        'w3x2lni/common.cpp',
    }
}

lm:executable 'w2l' {
    deps = "lua54",
    sources = {
        'w3x2lni/main_cli.cpp',
        'w3x2lni/common.cpp',
        'unicode.cpp',
    }
}

lm.rootdir = 'c++/bee.lua/3rd/lua/'

lm:executable 'w3x2lni-lua' {
    deps = "lua54",
    sources = {
        "utf8/utf8_lua.c",
    }
}
