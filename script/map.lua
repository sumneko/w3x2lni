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
local w3xparser = require 'w3xparser'
w2l:initialize()

function message(...)
	print(...)
end

local mt = {}
function mt:__index(key)
    print(debug.traceback(('读取不存在的全局变量[%s]'):format(key)))
    return nil
end
function mt:__newindex(key, value)
    print(debug.traceback(('保存全局变量[%s][%s]'):format(key, value)))
    rawset(self, key, value)
    return nil
end

setmetatable(_G, mt)

local function scan_dir(dir, callback)
    for path in dir:list_directory() do
        if fs.is_directory(path) then
            scan_dir(path, callback)
        else
            callback(path)
        end
    end
end

local function search_map(map)
    if map:get_type() == 'mpq' then
        map:get '(listfile)'
        map:get '(signature)'
        map:get '(attributes)'
        local buf = map:get '(listfile)'
        if buf then
            for name in buf:gmatch '[^\r\n]+' do
                map:get(name)
            end
        end
        local buf = map:get 'war3map.imp'
        if buf then
            local _, count, index = ('ll'):unpack(buf)
            local name
            for i = 1, count do
                _, name, index = ('c1z'):unpack(buf, index)
                map:get(name)
            end
        end
        local total = map:number_of_files()
        if map.read_count ~= total then
            message('-report|error', ('还有%d个文件没有读取'):format(total -map.read_count))
            message('-tip', '这些文件被丢弃了,请包含完整(listfile)')
            message('-report|error', ('读取(%d/%d)个文件'):format(map.read_count, total))
        end
    else
        local len = #map.path:string()
        scan_dir(map.path, function(path)
            local name = path:string():sub(len+2):lower()
            map:get(name)
        end)
    end
end

local function load_map(input)
    local map = archive(input)
    if map:get_type() == 'mpq' and not map:get '(listfile)' then
        message('不支持没有(listfile)的地图')
        return nil
    end
    return map
end

local function save_map(output_ar, w3i, input_ar)
    search_map(input_ar)
    for name, buf in pairs(input_ar) do
        if buf then
            if w2l.config.mdx_squf and name:sub(-4) == '.mdx' then
                buf = w3xparser.mdxopt(buf)
            end
            output_ar:set(name, buf)
        end
    end
    output_ar:set('(listfile)', false)
    output_ar:set('(signature)', false)
    output_ar:set('(attributes)', false)

    if not w2l.config.remove_we_only then
        local impignore = {}
        for _, name in ipairs(w2l.info.pack.impignore) do
            impignore[name] = true
        end
        local imp = {}
        for name, buf in pairs(output_ar) do
            if buf and not impignore[name] then
                imp[#imp] = name
            end
        end
        local hex = {}
        hex[1] = ('ll'):pack(1, #imp)
        for _, name in ipairs(imp) do
            hex[#hex+1] = ('z'):pack(name)
            hex[#hex+1] = '\r'
        end
        output_ar:set('war3map.imp', table.concat(hex))
    end

    if not output_ar:save(w3i, w2l.config.remove_we_only) then
        message('创建新地图失败,可能文件被占用了')
    end
end

local input = fs.path(uni.a2u(arg[1]))

message('正在打开地图...')
local slk = {}
local input_ar = load_map(input)
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
elseif w2l.config.target_storage == 'map' then
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
progress:start(0.4)
w2l:frontend(input_ar, slk)
progress:finish()

message('正在转换...')
progress:start(0.8)
w2l:backend(input_ar, slk)
progress:finish()

message('正在生成文件...')
progress:start(1)
save_map(output_ar, slk.w3i, input_ar)
progress:finish()
output_ar:close()
input_ar:close()
message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
