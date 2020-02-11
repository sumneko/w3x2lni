local lang = require 'lang'
local wct
local unpack_index
local chunk

local function unpack(fmt)
    local result
    result, unpack_index = fmt:unpack(wct, unpack_index)
    return result
end

local function read_head()
    local ver = unpack 'L'
    if ver > 1 then
        assert(ver == 0x80000004, lang.script.UNSUPPORTED_WCT)
        chunk.format_version = ver
        ver = unpack 'L'
    end
    assert(ver == 1, lang.script.UNSUPPORTED_WCT)
end

local function read_custom()
    chunk.custom = {}
    chunk.custom.comment = unpack 'z'
    local size = unpack 'l'
    if size == 0 then
        chunk.custom.code = ''
    else
        chunk.custom.code = unpack 'z'
    end
end

local function read_triggers()
    chunk.triggers = {}
    local count = unpack 'l'
    for i = 1, count do
        local size = unpack 'L'
        if size == 0 then
            chunk.triggers[i] = ''
        else
            chunk.triggers[i] = unpack('c'..(size-1))
            unpack('c1')
        end
    end
end

local function read_triggers_new()
    chunk.triggers = {}
    while unpack_index <= #wct do
        local size = unpack 'L'
        if size == 0 then
            chunk.triggers[#chunk.triggers+1] = ''
        else
            chunk.triggers[#chunk.triggers+1] = unpack('c'..(size-1))
            unpack('c1')
        end
    end
end

return function (w2l, wct_)
    wct = wct_
    unpack_index = 1
    chunk = {}

    read_head()
    read_custom()
    if chunk.format_version then
        read_triggers_new()
    else
        read_triggers()
    end

    return chunk
end
