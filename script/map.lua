(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
local progress = require 'progress'
local archive = require 'archive'
w2l:initialize()

function message(...)
	print(...)
end

local input = fs.path(uni.a2u(arg[1]))

message('正在打开地图...')
local slk = {}
local input_ar = archive(input)
if not input_ar then
    return
end
local output
if w2l.config.target_storage == 'dir' then
    message('正在导出文件...')
    if fs.is_directory(input) then
        output = input:parent_path() / (input:filename():string() .. '_' .. w2l.config.target_format)
    else
        output = input:parent_path() / input:stem():string()
    end
    fs.create_directory(output)
elseif w2l.config.target_storage == 'map' then
    message('正在打包地图...')
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

message('正在读取物编...')
w2l:frontend(input_ar, slk)
message('正在转换...')
w2l:backend_processing(slk)
w2l:backend(input_ar, slk)
for name, buf in pairs(input_ar) do
    output_ar:set(name, buf)
end
local ok, e = input_ar:sucess()
if not ok then
end
progress:target(100)
output_ar:save(slk, w2l.info, w2l.config)
output_ar:close()
input_ar:close()
progress:target(100)
message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
