require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w3x2lni = require 'w3x2lni'
local archive = require 'archive'
local save_map = require 'save_map'
local w2l = w3x2lni()

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

local input = fs.path(uni.a2u(arg[1]))

print('正在打开地图...')
local slk = {}
local input_ar = archive(input)
if not input_ar then
    return
end
local output
if w2l.config.target_storage == 'dir' then
    if fs.is_directory(input) then
        output = input:parent_path() / (input:filename():string() .. '_' .. w2l.config.target_format)
    else
        output = input:parent_path() / input:stem():string()
    end
    fs.create_directory(output)
elseif w2l.config.target_storage == 'mpq' then
    if fs.is_directory(input) then
        output = input:parent_path() / (input:filename():string() .. '.w3x')
    else
        output = input:parent_path() / (input:stem():string() .. '_' .. w2l.config.target_format .. '.w3x')
    end
end
local output_ar = archive(output, 'w')
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
save_map(w2l, output_ar, slk.w3i, input_ar)
w2l.progress:finish()
output_ar:close()
input_ar:close()
print('转换完毕,用时 ' .. os.clock() .. ' 秒') 
