(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua;' .. exepath .. '..\\script\\?\\init.lua;' .. exepath .. '..\\script\\core\\?.lua;' .. exepath .. '..\\script\\core\\?\\init.lua'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w3x2lni = require 'w3x2lni'
local archive = require 'archive'
local save_map = require 'save_map'
local w2l = w3x2lni()
local ui = w2l.ui_builder

local std_print = print
function print(...)
    if select(1, ...) == '-progress' then
        return
    end
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i])):gsub('[\r\n]', ' ')
    end
    std_print(table.concat(tbl, ' '))
end

if arg[0]:find('..', 1, true) then
	arg[1] = uni.a2u(arg[1])
	arg[2] = uni.a2u(arg[2])
end
local map_path = fs.path(arg[1])
local ydwe_path = fs.path(arg[2])
local mpq_path = ydwe_path / 'share' / 'mpq'
local map_name = map_path:stem():string()

local function string_trim (self) 
	return self:gsub("^%s*(.-)%s*$", "%1")
end

local loader = {}

local function is_enable_japi()
	local ok, result = pcall(function ()
		local tbl = w2l:parse_lni(io.load(ydwe_path / 'plugin' / 'warcraft3' / 'config.cfg'))
		return tbl['Enable']['yd_jass_api.dll'] ~= '0'
	end)
	if not ok then return true end
	return result
end

function loader:config()
	self.list = {}
	local f, err = io.open((mpq_path / 'config'):string(), 'r')
	if not f then
		error('Open ' .. (mpq_path / 'config'):string() .. ' failed.')
		return false
    end
    local global_config = w2l:parse_lni(io.load(ydwe_path / "bin" / "EverConfig.cfg"))
	local enable_ydtrigger = global_config["ThirdPartyPlugin"]["EnableYDTrigger"] ~= "0"
	local enable_japi = is_enable_japi()
	for line in f:lines() do
		if not enable_ydtrigger and (string_trim(line) == 'ydtrigger') then
			-- do nothing
		elseif not enable_japi and (string_trim(line) == 'japi') then
			-- do nothing
		elseif string_trim(line) == map_name then
			-- do nothing
		else
			table.insert(self.list, mpq_path / string_trim(line))
		end
	end
	f:close()
	return true
end

function loader:triggerdata()
	if #self.list == 0 then
		return nil
	end
	local t = nil
	for _, path in ipairs(self.list) do
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

local function new_config()
	local lines = {}
	local f = io.open((mpq_path / 'config'):string(), 'r')
	if not f then
		return nil
	end
	for line in f:lines() do
		if string_trim(line) == map_name then
			return nil
		end
		table.insert(lines, line)
	end
	table.insert(lines, map_name)
	return table.concat(lines, '\n')
end

w2l:set_messager(print)
loader:config()
local state = loader:triggerdata()

local clock = os.clock()
local map = archive(map_path)
local wtg = map:get 'war3map.wtg'
if not wtg or not state then
    return false
end
print('打开地图用时：', os.clock() - clock)

local clock = os.clock()
local suc = w2l:wtg_checker(wtg, state)
print('检查wtg结果：', suc, '用时：', os.clock() - clock)

local clock = os.clock()
local data, fix = w2l:wtg_reader(wtg, state)
print('读取wtg用时：', os.clock() - clock)

local buf = w2l:wtg_writer(data)
io.save(map_path:parent_path() / (map_path:filename():string() .. '.txt'), buf)

ui.merge(state, fix)
local bufs = {ui.new_writer(fix)}
fs.create_directories(map_path:parent_path() / map_name)
io.save(map_path:parent_path() / map_name / 'define.txt',    bufs[1])
io.save(map_path:parent_path() / map_name / 'event.txt',     bufs[2])
io.save(map_path:parent_path() / map_name / 'condition.txt', bufs[3])
io.save(map_path:parent_path() / map_name / 'action.txt',    bufs[4])
io.save(map_path:parent_path() / map_name / 'call.txt',      bufs[5])

local config = new_config()
if config then
	io.save(map_path:parent_path() / 'config', config)
end

print('成功，修复wtg总用时：', os.clock() - clock)
