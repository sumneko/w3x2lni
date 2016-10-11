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

local function load(filename)
    return io.load(fs.path(filename))
end

local function read_config()
	lni:set_marco('TableSearcher', root_dir:string() .. '/')
		config = lni:packager('config', function(filename)
		return io.load(fs.path(filename))
	end)

	for file_name, meta_name in pairs(config['metadata']) do
		w3x2txt:set_metadata(file_name, meta_name)
	end
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

		--刷新字符串
		if wts then
			local content = w3x2txt:fresh_wts(wts)
			io.save(lni_dir / 'war3map.wts', content)
		end
	end

	if mode == "lni2w3x" then
		for file_name, meta in pairs(config['metadata']) do
			lni:set_marco('TableSearcher', lni_dir:string() .. '/')
			local data = lni:packager(file_name, load)
			if next(data) then
				print('正在转换:', file_name)
				lni:set_marco('TableSearcher', meta_dir:string() .. '/')
				local key = lni:packager(file_name, load)
				local metadata = w3x2txt:read_metadata(meta)
				local content = w3x2txt:lni2obj(data, metadata, key)
				io.save(w3x_dir / file_name, content)
			else
				print('文件无效:' .. file_name)
			end
		end
	end

	if mode == "key2id" then
		for file_name, meta in pairs(config['metadata']) do
			local metadata = w3x2txt:read_metadata(meta)
			local content = w3x2txt:key2id(file_name, metadata)
			io.save(meta_dir / (file_name .. '.ini'), content)
		end
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
