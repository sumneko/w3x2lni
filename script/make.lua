(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local uni        = require 'ffi.unicode'
local w2l        = require 'w3x2lni'
local create_map = require 'create_map'

function message(...)
	local tbl = {...}
	local err = {}
	local count = select('#', ...)
	for i = 1, count do
		tbl[i] = tostring(tbl[i])
		err[i] = uni.u2a(tbl[i])
	end
	io.stderr:write(table.concat(err, ' ')..'\r\n')
	io.stderr:flush()
	print(table.concat(tbl, ' '))
end

local function main()
	if not arg[1] then
		message('请将地图或文件夹拖动到bat中!')
		return
	end

	w2l:init(arg[2])
	
	local input_path = fs.path(uni.a2u(arg[1]))
	if fs.is_directory(input_path) then
		local map_name = input_path:filename():string() .. '.w3x'
		local map_file = create_map()
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
		message('正在打开...')
		local output_dir = input_path:parent_path() / input_path:stem()
		local map_file = create_map()
		map_file:add_input(input_path)
		function map_file:on_lni(name, lni)
			return lni
		end
		function map_file:on_save(name)
			return name, output_dir
		end
		if map_file:save(output_dir, 'lni', 'dir') then
			message('转换完毕,用时 ' .. os.clock() .. ' 秒') 
		end
	end
end

main()
