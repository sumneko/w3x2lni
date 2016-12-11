(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
local map = require 'map'

function message(...)
end

w2l:init()

local clock = os.clock()
local mappath = fs.path(uni.a2u(arg[1]))
local m = map()
m:load_mpq(mappath)
print('time:', os.clock() - clock)
m:load_data()
print('time:', os.clock() - clock)

local function create_object(t)
	local mt = {}
	function mt:__index(key)
		if key:sub(1, 1) == '_' then
			return
		end
		key = key:lower()
		local value = t[key]
		if value and type(value) ~= 'table' then
			return value
		end
		local pos = key:find("%d*$")
		if not pos then
			return
		end
		local value = t[key:sub(1, pos-1)]
		if not value or type(value) ~= 'table' then
			return
		end
		local level = tonumber(key:sub(pos))
		if level > t._max_level then
			return
		end
		return value[level]
	end
	function mt:__newindex()
	end
	function mt:__pairs()
		return function (_, key)
			local nkey = next(t, key)
			while true do
				if not nkey then
					return
				end
				if nkey:sub(1, 1) ~= '_' then
					break
				end
				nkey = next(t, nkey)
			end
			return nkey, self[nkey]
		end
	end
	return setmetatable({}, mt)
end

local function create_proxy(type)
	local t = m.objs[type]
	local mt = {}
	function mt:__index(key)
		return create_object(t[key] or {})
	end
	function mt:__newindex()
	end
	function mt:__pairs()
		return function (_, key)
			local nkey = next(t, key)
			if not nkey then
				return
			end
			return nkey, self[nkey]
		end
	end
	return setmetatable({}, mt)
end

local slk = {}
for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
	slk[name] = create_proxy(name)
end
slk.misc = {}

print(slk.ability.A00E.DataA1)

--for k, v in pairs(slk.ability.A000) do
--	print(k, v)
--end

--for id, abil in pairs(slk.ability) do
--	print(id, abil.DataA1)
--end
