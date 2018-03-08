local loaddll = require 'ffi.loaddll'
loaddll 'ydbase'
require 'filesystem'
require 'utility'
local lni = require 'lni-c'
local uni = require 'ffi.unicode'
local core = require 'sandbox_core'
local ui = require 'ui-builder'
local archive = require 'archive'
local save_map = require 'save_map'
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
local config = lni(assert(io.load(root / 'config.ini')), 'config')
local fmt = config.target_format
for k, v in pairs(config[fmt]) do
    config[k] = v
end
w2l:set_config(config)

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

local function string_trim (self) 
	return self:gsub("^%s*(.-)%s*$", "%1")
end

local function ydwe_path()
    require 'registry'
    local commands = registry.current_user() / [[SOFTWARE\Classes\YDWEMap\shell\run_war3\command]]
    if not commands then
        return nil
    end
    local command = commands['']
    local path = command:match '^"([^"]*)"'
    local ydpath = fs.path(path):remove_filename()
    if fs.exists(ydpath / 'YDWE.exe') then
        return ydpath
    else
        local ydpath = ydpath:remove_filename()
        if fs.exists(ydpath / 'YDWE.exe') then
            return ydpath
        end
    end
    return nil
end

local loader = {}

local function trigger_config(mpq_path)
	local list = {}
	local f, err = io.open((mpq_path / 'config'):string(), 'r')
	if not f then
		return nil
    end
	for line in f:lines() do
		table.insert(list, mpq_path / string_trim(line))
	end
    f:close()
    return list
end

local function load_triggerdata(list)
    if not list or #list == 0 then
        return nil
    end
	local t = nil
	for _, path in ipairs(list) do
		if fs.exists(path / 'ui') then
			t = ui.merge(t, ui.old_reader(function(filename)
				return io.load(path / 'ui' / filename)
			end))
		else
			t = ui.merge(t, ui.new_reader(function(filename)
				return io.load(path / filename)
			end))
		end
	end
	return t
end

function w2l:trigger_data()
    local path = ydwe_path()
    if not path then
        return nil, '请设置YDWE关联地图'
    end
    local list = trigger_config(path / 'share' / 'ui') or trigger_config(path / 'share' / 'mpq')
    if not list then
        return nil, '没有找到触发器数据的目录：' .. path:string()
    end
    local state = load_triggerdata(list)
    if not state then
        return nil, '没有读取到触发器数据'
    end
    return state
end

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
