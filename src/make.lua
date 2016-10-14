package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'

local root_dir = fs.path(uni.a2u(arg[1]))

local function main()
	if not arg[2] then
		print('请将地图或文件夹拖动到bat中!')
		return
	end

	w3x2txt:init(root_dir)
	
	local input_path = fs.path(uni.a2u(arg[2]))
	if fs.is_directory(input_path) then
		local map_name = input_path:filename():string() .. '.w3x'
		local map_file = w3x2txt:create_map()
		map_file:add_input(input_path)
		map_file:save(input_path:parent_path() / map_name, function(name, file, dir)
			return name, file
		end)
	else
		local output_dir = root_dir / input_path:stem()
		local map_file = w3x2txt:create_map()
		map_file:add_input(input_path)
		map_file:save(_, function(name)
			return name, output_dir
		end)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
