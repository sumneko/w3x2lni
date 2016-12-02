(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local uni      = require 'ffi.unicode'
local w3x2lni  = require 'w3x2lni'

local function main()
	if not arg[1] then
		message('请将地图或文件夹拖动到bat中!')
		return
	end

	w3x2lni:init(arg[2])
	
	local input_path = fs.path(uni.a2u(arg[1]))
	if fs.is_directory(input_path) then
		local map_name = input_path:filename():string() .. '.w3x'
		local map_file = w3x2lni:create_map()
		map_file:add_input(input_path)
		function map_file:on_lni(name, lni)
			return lni
		end
		function map_file:on_save(name, file, dir)
			return name, file
		end
		if map_file:save(input_path:parent_path() / map_name) then
			message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
		end
	else
		local output_dir = input_path:parent_path() / input_path:stem()
		local map_file = w3x2lni:create_map()
		map_file:add_input(input_path)
		function map_file:on_lni(name, lni)
			return lni
		end
		function map_file:on_save(name)
			return name, output_dir
		end
		if map_file:save(output_dir) then
			message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
		end
	end
end

main()
