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
local ui = require 'ui-builder'
local w2l = w3x2lni()

local map_path = fs.path(arg[1])
local ydwe_path = fs.path(arg[2])
local mpq_path = ydwe_path / 'share' / 'mpq'

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
			t = ui.merge(t, ui.old_reader(path / 'ui'))
		else
			t = ui.merge(t, ui.new_reader(path))
		end
	end
	return ui.old_writer(t)
end

local map = archive(map_path)
local wtg = map:get 'war3map.wtg'
loader:config()
local data = loader:triggerdata()
if not wtg or not data then
    return false
end

local state = w2l:read_triggerdata(data)
local buf = w2l:check_wtg(wtg, state)
io.save(map_path:parent_path() / (map_path:filename():string() .. '_wtg.txt'), buf)
