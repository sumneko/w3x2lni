local lm = require 'luamake'

lm.arch = 'x86'

lm:import '3rd/bee.lua/make.lua'

lm.rootdir = 'c++/'

lm:executable 'w3x2lni' {
    sources = {
        'w3x2lni/main_gui.cpp',
        'w3x2lni/common.cpp',
    },
    crt = 'static'
}

lm:executable 'w2l' {
    deps = 'lua54',
    includes = {
        "../3rd/bee.lua/3rd/lua"
    },
    sources = {
        'w3x2lni/main_cli.cpp',
        'w3x2lni/common.cpp',
        'unicode.cpp',
    },
    links = "delayimp",
    ldflags = '/DELAYLOAD:lua54.dll',
    crt = 'static'
}

lm:lua_dll 'yue-ext' {
    deps = 'lua54',
    export_luaopen = "off",
    sources = {
        'yue-ext/main.cpp',
        'unicode.cpp',
    },
    links = {
        'user32',
        'shell32',
        'ole32',
    }
}

lm.rootdir = '3rd/'

lm:lua_dll 'lml' {
    deps = 'lua54',
    sources = {
        'lml/src/LmlParse.cpp',
        'lml/src/main.cpp',
    }
}

lm:lua_dll 'w3xparser' {
    deps = 'lua54',
    sources = {
        'w3xparser/src/real.cpp',
        'w3xparser/src/main.cpp',
    }
}

lm:lua_dll 'lpeglabel' {
    deps = 'lua54',
    sources = 'lpeglabel/*.c',
    visibility = 'default',
}

lm:shared_library 'stormlib' {
    sources = {
        'stormlib/src/*.cpp',
        'stormlib/src/*.c',
        '!stormlib/src/zlib/compress.c',
        '!stormlib/src/pklib/crc32.c',
        '!stormlib/src/wdk/*',
    },
    defines = {
        '_UNICODE',
        'UNICODE'
    },
    links = {
        'user32',
    },
    ldflags = '/DEF:3rd/stormlib/src/DllMain.def',
}

lm:shared_library 'casclib' {
    sources = {
        'casclib/src/*.cpp',
        'casclib/src/*.c',
    },
    defines = {
        '_UNICODE',
        'UNICODE'
    },
    ldflags = '/DEF:3rd/casclib/src/DllMain.def',
}

lm:lua_dll 'lni' {
    deps = 'lua54',
    sources = {
        'lni/src/main.cpp',
    }
}

lm:build 'ffi_dynasm' {
    '$luamake', 'lua', 'make/ffi_dynasm.lua',
    output = "3rd/ffi/src/call_x86.h",
    deps = {
        'lua',
    }
}

lm:phony {
    input = "3rd/ffi/src/call_x86.h",
    output = "3rd/ffi/src/call.c",
}

lm:lua_dll 'ffi' {
    deps = {
        'lua54',
        'ffi_dynasm'
    },
    sources = {
        'ffi/src/*.c',
        '!ffi/src/test.c',
    },
    ldflags = '/EXPORT:luaopen_ffi'
}

lm:shared_library 'minizip' {
    includes = {
        'zlib',
    },
    sources = {
        'zlib/inflate.c',
        'zlib/deflate.c',
        'zlib/zutil.c',
        'zlib/trees.c',
        'zlib/inftrees.c',
        'zlib/inffast.c',
        'zlib/crc32.c',
        'zlib/adler32.c',
        'zlib/contrib/minizip/zip.c',
        'zlib/contrib/minizip/unzip.c',
        'zlib/contrib/minizip/ioapi.c',
    },
    defines = {
        '_CRT_SECURE_NO_WARNINGS',
    },
    ldflags = {
        '/DEF:make/luamake/minizip.def'
    }
}

lm:build 'install' {
    '$luamake', 'lua', 'make/install.lua',
    deps = {
        'w3x2lni',
        'w2l',
        'yue-ext',
        'bee',
        'lua',
        'lml',
        'w3xparser',
        'lpeglabel',
        'stormlib',
        'casclib',
        'lni',
        'ffi',
        'minizip',
    }
}

lm:default {
    'install'
}
