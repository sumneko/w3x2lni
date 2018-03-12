require 'filesystem'
require 'utility'
local lni = require 'lni'
local uni = require 'ffi.unicode'
local core = require 'tool.sandbox_core'
local builder = require 'map-builder'
local triggerdata = require 'tool.triggerdata'
local w2l = core()

local std_print = print
function print(...)
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = tostring(tbl[i]):gsub('[\r\n]', ' ')
    end
    std_print(table.concat(tbl, ' '))
end
w2l:set_messager(print)


local root = fs.current_path():remove_filename()

function w2l:mpq_load(filename)
    return w2l.mpq_path:each_path(function(path)
        return io.load(root / 'data' / 'mpq' / path / filename)
    end)
end

function w2l:prebuilt_load(filename)
    return w2l.mpq_path:each_path(function(path)
        return io.load(root / 'data' / 'prebuilt' / path / filename)
    end)
end

function w2l:trigger_data()
    return triggerdata()
end

local function unpack_config()
    local config = lni(io.load(root / 'config.ini'))
    config.mode = arg[2]:sub(2)
    for k, v in pairs(config[config.mode]) do
        config[k] = v
    end
    return config
end

local input = fs.path(arg[1])

print('正在打开地图...')
local slk = {}
local input_ar = builder.load(input)
if not input_ar then
    return
end
w2l:set_config(unpack_config())
local output
if w2l.config.target_storage == 'dir' then
    if fs.is_directory(input) then
        output = input:parent_path() / (input:filename():string() .. '_' .. w2l.config.mode)
    else
        output = input:parent_path() / input:stem():string()
    end
    fs.create_directory(output)
elseif w2l.config.target_storage == 'mpq' then
    if fs.is_directory(input) then
        output = input:parent_path() / (input:filename():string() .. '.w3x')
    else
        output = input:parent_path() / (input:stem():string() .. '_' .. w2l.config.mode .. '.w3x')
    end
end
local output_ar = builder.load(output, 'w')
if not output_ar then
    return
end

function w2l:map_load(filename)
    return input_ar:get(filename)
end

function w2l:map_save(filename, buf)
    return input_ar:set(filename, buf)
end

function w2l:map_remove(filename)
    return input_ar:remove(filename)
end

print('正在读取物编...')
w2l.progress:start(0.4)
w2l:frontend(slk)
w2l.progress:finish()

print('正在转换...')
w2l.progress:start(0.8)
w2l:backend(slk)
w2l.progress:finish()

print('正在生成文件...')
w2l.progress:start(1)
builder.save(w2l, output_ar, slk.w3i, input_ar)
w2l.progress:finish()
output_ar:close()
input_ar:close()
print('转换完毕,用时 ' .. os.clock() .. ' 秒') 
