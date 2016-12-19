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
	local t = {...}
	for i = 1, select('#', ...) do
		t[i] = tostring(t[i])
	end
	print(table.concat(t, ' '))
end

local input = fs.path(uni.a2u(arg[1]))
local map_file = map()
if map_file:save(input) then
	message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
end
