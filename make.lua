local lm = require 'luamake'

lm.arch = 'x64'
lm.EXE  = 'lua'
lm.c    = lm.compiler == 'msvc' and 'c89' or 'c11'
lm.cxx  = 'c++17'

lm:import '3rd/bee.lua/make.lua'

lm:executable 'w3x2lni' {
    rootdir = 'c++',
    sources = {
        'w3x2lni/main_gui.cpp',
        'w3x2lni/common.cpp',
    },
    ldflags = '/largeaddressaware',
    crt = 'static'
}

lm:executable 'w2l' {
    rootdir = 'c++',
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
    ldflags = {'/DELAYLOAD:lua54.dll','/largeaddressaware'},
    crt = 'static'
}

lm:lua_dll 'yue-ext' {
    rootdir = 'c++',
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


lm:lua_dll 'lml' {
    rootdir = '3rd',
    deps = 'lua54',
    sources = {
        'lml/src/LmlParse.cpp',
        'lml/src/main.cpp',
    }
}

lm:lua_dll 'w3xparser' {
    rootdir = '3rd',
    deps = 'lua54',
    sources = {
        'w3xparser/src/real.cpp',
        'w3xparser/src/main.cpp',
    }
}

lm:lua_dll 'lpeglabel' {
    rootdir = '3rd',
    deps = 'lua54',
    sources = 'lpeglabel/*.c',
    visibility = 'default',
}

lm:shared_library 'stormlib' {
    rootdir = '3rd',
    sources = {
        'stormlib/src/*.cpp',
        'stormlib/src/*.c',
        'stormlib/src/zlib/*.c',
        '!stormlib/src/zlib/compress.c',
        'stormlib/src/jenkins/*.c',
        'stormlib/src/sparse/*.cpp',
        'stormlib/src/adpcm/*.cpp',
        'stormlib/src/bzip2/*.c',
        'stormlib/src/huffman/*.cpp',
        'stormlib/src/pklib/*.c',
        'stormlib/src/libtomcrypt/src/hashes/*.c',
        'stormlib/src/libtomcrypt/src/misc/*.c',
        'stormlib/src/libtomcrypt/src/math/*.c',
        'stormlib/src/libtomcrypt/src/pk/rsa/*.c',
        'stormlib/src/libtomcrypt/src/pk/ecc/*.c',
        'stormlib/src/libtomcrypt/src/pk/asn1/*.c',
        'stormlib/src/libtomcrypt/src/pk/pkcs1/*.c',
        'stormlib/src/libtommath/*.c',
        'stormlib/src/lzma/C/*.c',
        --'!stormlib/src/zlib/compress.c',
        --'!stormlib/src/pklib/crc32.c',
        --'!stormlib/src/wdk/*',
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
    rootdir = '3rd',
    sources = {
        'casclib/src/*.cpp',
        'casclib/src/*.c',
        'casclib/src/common/*.cpp',
        'casclib/src/md5/*.cpp',
        'casclib/src/jenkins/*.c',
        'casclib/src/zlib/*.c',
    },
    defines = {
        '_UNICODE',
        'UNICODE'
    },
    ldflags = '/DEF:3rd/casclib/src/DllMain.def',
}

lm:lua_dll 'lni' {
    rootdir = '3rd',
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
    rootdir = '3rd',
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
    rootdir = '3rd',
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

--lm:msvc_copy_vcrt 'copy_vcrt' {
--    output = 'bin',
--}

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
        --'copy_vcrt',
    }
}

lm:default {
    'install'
}
