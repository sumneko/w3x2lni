package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
require 'localization'

local w3x2txt  = require 'w3x2txt'
local stormlib = require 'stormlib'
local lni      = require 'lni'

local root_dir = fs.path(arg[1])
local lni_dir  = root_dir / 'lni'
local w3x_dir  = root_dir / 'w3x'
local meta_dir = root_dir / 'meta'

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
		w3x2txt:set_wts(wts)
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
			io.save(lni_dir / (file_name .. '.ini'), content)
		else
			print('文件无效:' .. file_name)
		end
	end

	--转换其他文件
	local content = io.load(w3x_dir / 'war3map.w3i')
	local w3i = w3x2txt:read_w3i(content)
	local content = w3x2txt:w3i2lni(w3i)
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
	local map = mpq_open(map_path)
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

local function unpack()
	if not arg[3] then
		print('请将地图拖动到bat中!')
		return
	end
	local map_path = fs.path(arg[3])
	local temp_dir = root_dir / 'temp'

	-- 解压地图
	local map = mpq_open(map_path)
	if not map then
		print('地图打开失败')
		return
	end

	if not map:has '(listfile)' then
		print('不支持没有文件列表(listfile)的地图')
		return
	end
	mpq:close()

	-- 将原来的目录改名后删除(否则之后创建同名目录时可能拒绝访问)
	if fs.exists(w3x_dir) then
		fs.rename(w3x_dir, temp_dir)
		fs.remove_all(temp_dir)
	end
	fs.create_directories(w3x_dir)
	
	extract_files(map_path, w3x_dir)
end

local function get_listfile(map_path)
	local parent_dir_len = #w3x_dir:string()
	local listfile = {}
	dir_scan(w3x_dir, function(path)
		listfile[#listfile+1] = path:string():sub(parent_dir_len+2)
	end)
	return listfile
end

local function import_files(map_path, listfile, input_path)
	local mpq = mpq_open(map_path)
	local clock = os.clock()
	local success, failed = 0, 0
	for i = 1, #listfile do
		local name = listfile[i]
		local path = input_path / name
		if mpq:import(name, path) then
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
	mpq:close()
end

local function import_listfile(map_path, listfile)
	local mpq = mpq_open(map_path)
	local temp_path = root_dir / 'temp'
	io.save(temp_path, table.concat(listfile, '\n'))
	if not mpq:import('(listfile)', temp_path) then
		print('文件列表(listfile)导入失败')
	end
	fs.remove(temp_path)
	mpq:close()
end

local function mpq2map(map_path, w3i_path)
	local mpq_str = io.load(map_path)
	local w3i_str = io.load(w3i_path)
	local w3i = w3x2txt:read_w3i(w3i_str)
	local map_str = w3x2txt:mpq2map(mpq_str, w3i)
	io.save(map_path, map_str)
end

local function pack()
	local map_name = 'temp.w3x'
	local map_path = root_dir / map_name

	local listfile = get_listfile(map_path)

	fs.remove(map_path)
	local mpq = mpq_create(map_path, #listfile+8)
	if not mpq then
		print('地图创建失败')
		return
	end
	mpq:close()

	mpq2map(map_path, w3x_dir / 'war3map.w3i')

	import_files(map_path, listfile, w3x_dir)
	import_listfile(map_path, listfile)
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
		unpack()
	end

	if mode == 'pack' then
		pack()
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
