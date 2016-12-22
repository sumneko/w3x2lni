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

message('-report', '输入路径为:', input:string())
message('-report', '输出路径为:', output:string())

message('-report', '转换格式:', w2l.config.target_format)
message('-report', '输出方式:', w2l.config.target_storage)
message('-report', '分析slk文件:', w2l.config.read_slk)
message('-report', '搜索最优模板次数:', w2l.config.find_id_times)
message('-report', '移除与模板完全相同的数据:', w2l.config.remove_same)
message('-report', '移除超出等级的数据:', w2l.config.remove_exceeds_level)
message('-report', '补全空缺的数据:', w2l.config.remove_nil_value)
message('-report', '移除只在WE使用的文件:', w2l.config.remove_we_only)
message('-report', '移除没有引用的对象:', w2l.config.remove_unuse_object)

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
    message('-report', e)
end
progress:target(100)
output_ar:save(slk, w2l.info, w2l.config)
output_ar:close()
input_ar:close()
progress:target(100)
message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
