(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\src\\?.lua'
end)()

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'

local function main()
	if not arg[1] then
		print('请将地图或文件夹拖动到bat中!')
		return
	end

	w3x2txt:init()
	
	local input_path = fs.path(uni.a2u(arg[1]))
	if fs.is_directory(input_path) then
		local map_name = input_path:filename():string() .. '.w3x'
		local map_file = w3x2txt:create_map()
		map_file:add_input(input_path)
		map_file:save(input_path:parent_path() / map_name, function(name, file, dir)
			return name, file
		end)
	else
		local output_dir = input_path:parent_path() / input_path:stem()
		local map_file = w3x2txt:create_map()
		map_file:add_input(input_path)
		map_file:save(_, function(name)
			return name, output_dir
		end)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
