local lm = require "luamake"

lm:import '3rd/bee.lua/make.lua'

lm.rootdir = 'c++/'

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
    },
    defines = '/DELAYLOAD:"lua54.dll"'
}

lm:shared_library 'yue-ext' {
    deps = "lua54",
    sources = {
        'yue-ext/main.cpp',
        'unicode.cpp',
    },
    links = {
        "user32",
        "shell32",
        "ole32",
    }
}

lm:build 'install' {
    '$luamake', 'lua', 'make/install.lua',
    deps = {
        'w3x2lni',
        'w2l',
        'yue-ext',
        'bee',
        'lua'
    }
}

lm:default {
    'install'
}
