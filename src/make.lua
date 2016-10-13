package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'
local stormlib = require 'stormlib'
local lni      = require 'lni'
local create_map = require 'create_map'

local root_dir = fs.path(uni.a2u(arg[1]))
local meta_dir = root_dir / 'meta'
local temp_dir = root_dir / 'temp'

local config

local function read_config()
	local config_str = io.load(root_dir / 'config.ini')
	config = lni:loader(config_str, 'config')

	for file_name, meta_name in pairs(config['metadata']) do
		w3x2txt:set_metadata(file_name, meta_name)
	end
end

local count = 0
local function get_temp_path()
	count = count + 1
	return root_dir / ('temp' .. count .. os.time())
end

local function create_dir(dir)
	-- 将原来的目录改名后删除(否则之后创建同名目录时可能拒绝访问)
	local temp_dir = get_temp_path()
	if fs.exists(dir) then
		fs.rename(dir, temp_dir)
		fs.remove_all(temp_dir)
	end
	fs.create_directories(dir)
end

local function lni2w3x(name, file)
	if name:sub(-4) == '.ini' and config['metadata'][name:sub(1, -5)] then
		print('正在转换:', name)
		local data = lni:loader(file, name)
		local key = lni:loader(io.load(meta_dir / name), name)
		local metadata = w3x2txt:read_metadata(config['metadata'][name:sub(1, -5)])
		local content = w3x2txt:lni2obj(data, metadata, key)
		return name:sub(1, -5), content
	elseif name == 'war3map.w3i' then
		return name, file
	else
		return name, file
	end
end

local function w3x2lni(files, paths)
	--读取编辑器文本
	local editstring
	local ini = w3x2txt:read_ini(meta_dir / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end
	
	--读取字符串
	local wts
	if files['war3map.wts'] then
		wts = w3x2txt:read_wts(files['war3map.wts'])
	end

	for name, file in pairs(files) do
		if config['metadata'][name] then
			local content = file
			print('正在转换:' .. name)
			local metadata = w3x2txt:read_metadata(config['metadata'][name])
			local data = w3x2txt:read_obj(content, metadata)
			local content = w3x2txt:obj2lni(data, metadata, editstring)
			local content = w3x2txt:convert_wts(content, wts)
			io.save(paths[name]:parent_path() / (name .. '.ini'), content)
		elseif name == 'war3map.w3i' then
			io.save(paths[name], file)
			local content = file
			local w3i = w3x2txt:read_w3i(content)
			local content = w3x2txt:w3i2lni(w3i)
			local content = w3x2txt:convert_wts(content, wts)
			io.save(paths['war3map.w3i']:parent_path() / 'war3map.w3i.ini', content)
		elseif name == 'war3map.wts' then
		else
			io.save(paths[name], file)
		end
	end
	--刷新字符串
	if wts then
		local content = w3x2txt:fresh_wts(wts)
		io.save(paths['war3map.wts'], content)
	end
end

local function extract_files(map_path, get_output_dir)
	local files = {}
	local paths = {}
	local map = stormlib.open(map_path)
	for name in pairs(map) do
		local output_dir = get_output_dir(name)
		if output_dir then
			local path = output_dir / name
			fs.create_directories(path:parent_path())
			local buf = map:load_file(name, path)
			if buf then
				files[name] = buf
				paths[name] = path
			end
		end
	end
	map:close()
	return files, paths
end

local function unpack(map_path, get_output_dir)
	-- 解压地图
	local map = stormlib.open(map_path)
	if not map then
		print('地图打开失败')
		return
	end

	if not map:has_file '(listfile)' then
		print('不支持没有文件列表(listfile)的地图')
		return
	end
	map:close()
	
	local files, paths = extract_files(map_path, get_output_dir)
	w3x2lni(files, paths)
end

local function main()
	if not arg[2] then
		print('请将地图或文件夹拖动到bat中!')
		return
	end

	read_config()
	w3x2txt:set_dir('meta', meta_dir)
	
	local input_path = fs.path(uni.a2u(arg[2]))
	if fs.is_directory(input_path) then
		local input_dir = input_path
		local map_name = input_dir:filename():string() .. '.w3x'
		local map_file = create_map(config, w3x2txt:read_w3i(io.load(input_dir / 'war3map.w3i')))
		map_file:add_dir(input_dir)
		map_file:save(input_dir:parent_path() / map_name, lni2w3x)
	else
		local output_dir = root_dir / uni.a2u(fs.basename(input_path))
		create_dir(output_dir)
		unpack(input_path, function(filename)
			return output_dir
		end)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
