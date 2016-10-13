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
local lni_dir  = root_dir / 'lni'
local w3x_dir  = root_dir / 'w3x'
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

local function dir_scan(dir, callback)
	for full_path in dir:list_directory() do
		if fs.is_directory(full_path) then
			-- 递归处理
			dir_scan(full_path, callback)
		else
			callback(full_path)
		end
	end
end

local function w3x2lni()
	--读取字符串
	local content = io.load(w3x_dir / 'war3map.wts')
	local wts
	if content then
		wts = w3x2txt:read_wts(content)
	end

	--读取编辑器文本
	local editstring
	local ini = w3x2txt:read_ini(meta_dir / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end
	
	--转换二进制文件到lni
	for file_name, meta in pairs(config['metadata']) do
		local content = io.load(w3x_dir / file_name)
		if content then
			print('正在转换:' .. file_name)
			local metadata = w3x2txt:read_metadata(meta)
			local data = w3x2txt:read_obj(content, metadata)
			local content = w3x2txt:obj2lni(data, metadata, editstring)
			local content = w3x2txt:convert_wts(content, wts)
			io.save(lni_dir / (file_name .. '.ini'), content)
		else
			print('文件无效:' .. file_name)
		end
	end

	--转换其他文件
	local content = io.load(w3x_dir / 'war3map.w3i')
	local w3i = w3x2txt:read_w3i(content)
	local content = w3x2txt:w3i2lni(w3i)
	local content = w3x2txt:convert_wts(content, wts)
	io.save(lni_dir / 'war3map.w3i.ini', content)

	--刷新字符串
	if wts then
		local content = w3x2txt:fresh_wts(wts)
		io.save(lni_dir / 'war3map.wts', content)
	end
end

local function lni2w3x()
	for file_name, meta in pairs(config['metadata']) do
		local lni_str = io.load(lni_dir / (file_name .. '.ini'))
		if lni_str then
			print('正在转换:', file_name)
			local data = lni:loader(lni_str, file_name)
			local key_str = io.load(meta_dir / (file_name .. '.ini'))
			local key = lni:loader(key_str, file_name)
			local metadata = w3x2txt:read_metadata(meta)
			local content = w3x2txt:lni2obj(data, metadata, key)
			io.save(w3x_dir / file_name, content)
		else
			print('文件无效:' .. file_name)
		end
	end
end

local function key2id()
	for file_name, meta in pairs(config['metadata']) do
		local metadata = w3x2txt:read_metadata(meta)
		local content = w3x2txt:key2id(file_name, metadata)
		io.save(meta_dir / (file_name .. '.ini'), content)
	end
end

local function extract_files(map_path, output_path)
	local map = stormlib.open(map_path)
	local clock = os.clock()
	local success, failed = 0, 0
	for name in pairs(map) do
		local path = output_path / name
		local dir = path:parent_path()
		fs.create_directories(dir)
		if map:extract(name, path) then
			success = success + 1
		else
			failed = failed + 1
			print('文件导出失败', name)
		end
		if os.clock() - clock >= 0.5 then
			clock = os.clock()
			print('正在导出', '成功:', success, '失败:', failed)
		end
	end
	print('导出完毕', '成功:', success, '失败:', failed)
	map:close()
end

local function unpack(map_path, output_path)
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

	-- 将原来的目录改名后删除(否则之后创建同名目录时可能拒绝访问)
	if fs.exists(output_path) then
		fs.rename(output_path, temp_dir)
		fs.remove_all(temp_dir)
	end
	fs.create_directories(output_path)
	
	extract_files(map_path, output_path)
end

local function get_listfile(input_path)
	local parent_dir_len = #input_path:string()
	local listfile = {}
	dir_scan(input_path, function(path)
		listfile[#listfile+1] = path:string():sub(parent_dir_len+2)
	end)
	return listfile
end

local function import_files(map, listfile, input_path)
	local clock = os.clock()
	local success, failed = 0, 0
	for i = 1, #listfile do
		local name = listfile[i]
		local path = input_path / name
		if map:add_file(name, path) then
			success = success + 1
		else
			failed = failed + 1
			print('文件导入失败', name)
		end
		if os.clock() - clock >= 0.5 then
			clock = os.clock()
			print('正在导入', '成功:', success, '失败:', failed)
		end
	end
	print('导入完毕', '成功:', success, '失败:', failed)
end

local function import_imp(map, listfile)
	local imp_ignore = {}
	for _, name in ipairs(config['pack']['impignore']) do
		imp_ignore[name:lower()] = true
	end

	local temp_path = root_dir / 'temp'
	local imp = {}
	for _, name in ipairs(listfile) do
		if not imp_ignore[name:lower()] then
			imp[#imp+1] = ('z'):pack(name)
		end
	end
	table.insert(imp, 1, ('ll'):pack(1, #imp))

	io.save(temp_path, table.concat(imp, '\r'))
	if not map:add_file('war3map.imp', temp_path) then
		print('war3map.imp导入失败')
	end
	fs.remove(temp_path)
end

local function pack(map_path, input_path)
	local listfile = get_listfile(input_path)
	fs.remove(map_path)

	local w3i = w3x2txt:read_w3i(io.load(input_path / 'war3map.w3i'))
	io.save(map_path, create_map(w3i))

	local map = stormlib.create(map_path, #listfile+8)
	if not map then
		print('地图创建失败')
		return
	end
	import_files(map, listfile, input_path)
	import_imp(map, listfile)
	map:close()
end

local function main()
	local mode = arg[2]
	
	read_config()
	
	-- 创建目录
	fs.create_directory(lni_dir)
	fs.create_directory(w3x_dir)

	w3x2txt:set_dir('w3x', w3x_dir)
	w3x2txt:set_dir('lni', lni_dir)
	w3x2txt:set_dir('meta', meta_dir)

	if mode == "w3x2lni" then
		w3x2lni()
	end

	if mode == "lni2w3x" then
		lni2w3x()
	end

	if mode == "key2id" then
		key2id()
	end

	if mode == 'unpack' then
		if not arg[3] then
			print('请将地图拖动到bat中!')
			return
		end
		local map_path = fs.path(uni.a2u(arg[3]))
		local output_path = root_dir / fs.basename(map_path)
		unpack(map_path, output_path)
	end

	if mode == 'pack' then
		if not arg[3] then
			print('请将文件夹拖动到bat中!')
			return
		end
		local input_path = fs.path(uni.a2u(arg[3]))
		local map_name = 'new_' .. input_path:filename():string() .. '.w3x'
		local map_path = input_path:parent_path() / map_name
		pack(map_path, input_path)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
