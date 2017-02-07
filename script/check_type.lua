(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
w2l:initialize()

function message(...)
end

local select        = select
local tonumber      = tonumber
local tostring      = tostring
local string_unpack = string.unpack
local string_pack   = string.pack
local string_lower  = string.lower
local string_sub    = string.sub
local math_floor    = math.floor
local table_concat  = table.concat

local buf_pos
local unpack_buf
local unpack_pos
local has_level
local metadata
local check_bufs

local function set_pos(...)
    unpack_pos = select(-1, ...)
    return ...
end

local function unpack(str)
    return set_pos(string_unpack(str, unpack_buf, unpack_pos))
end

local typedefine
local function get_typedefine(type)
    if not typedefine then
        typedefine = w2l:parse_lni(io.load(w2l.defined / 'typedefine.ini'))
    end
    return typedefine[string_lower(type)] or 3
end

local function unpack_data()
    local id, type = unpack 'c4l'
    local id = string_unpack('z', id)
    local except
    local meta = metadata[id]
    if meta then
        except = get_typedefine(meta.type)
    else
        except = type
    end
    if type ~= except then
        check_bufs[#check_bufs+1] = string_sub(unpack_buf, buf_pos, unpack_pos - 5)
        check_bufs[#check_bufs+1] = string_pack('l', except)
        buf_pos = unpack_pos
    end
    if has_level then
        unpack 'll'
        if type ~= except then
            check_bufs[#check_bufs+1] = string_sub(unpack_buf, buf_pos, unpack_pos - 1)
            buf_pos = unpack_pos
        end
    end
    local value
    if type == 0 then
        value = unpack 'l'
    elseif type == 1 or type == 2 then
        value = unpack 'f'
    else
        value = unpack 'z'
    end
    if type ~= except then
        if except == 0 then
            check_bufs[#check_bufs+1] = string_pack('l', math_floor(tonumber(value) or 0))
        elseif except == 1 then
            check_bufs[#check_bufs+1] = string_pack('f', tonumber(value) or 0)
        elseif except == 2 then
            check_bufs[#check_bufs+1] = string_pack('f', tonumber(value) or 0)
        else
            check_bufs[#check_bufs+1] = string_pack('z', tostring(value))
        end
        buf_pos = unpack_pos
    end
    unpack 'l'
end

local function unpack_obj()
    local parent, name, count = unpack 'c4c4l'
    for i = 1, count do
        unpack_data()
    end
end

local function unpack_chunk()
    local count = unpack 'l'
    for i = 1, count do
        unpack_obj()
    end
end

local function unpack_head()
    unpack 'l'
end

local function check(type, buf)
    buf_pos    = 1
    unpack_pos = 1
    unpack_buf = buf
    has_level  = w2l.info.key.max_level[type]
    metadata   = w2l:parse_slk(io.load(w2l.mpq / w2l.info.metadata[type]))
    check_bufs = {}

    unpack_head()
    unpack_chunk()
    unpack_chunk()

    if buf_pos > 1 then
        check_bufs[#check_bufs+1] = unpack_buf:sub(buf_pos)
        return table_concat(check_bufs)
    end
    
    return buf
end

local function test()
    local archive = require 'archive'
    local mappath = fs.path(uni.a2u(arg[1]))
    local ar = archive(mappath)
    local clock = os.clock()
    for _, type in ipairs {'ability', 'unit', 'item', 'doodad', 'destructable', 'buff', 'upgrade'} do
        local filename = w2l.info.obj[type]
        local buf = ar:get(filename)
        if buf then
            io.save(w2l.root / filename, buf)
            buf = check(type, buf)
            io.save(w2l.root / ('new_' .. filename), buf)
        end
    end
    print('耗时:', os.clock() - clock)
    ar:close()
end

test()
