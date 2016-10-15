local stormlib = require 'stormlib'
local create_map = require 'create_map'
local lni = require 'lni'

local function remove_then_create_dir(dir)
	if fs.exists(dir) then
		task(fs.remove_all, dir)
	end
	task(fs.create_directories, dir)
end

local mt = {}

function mt:convert_wts(content, wts, only_short, read_only)
	if not wts then
		return content
	end
	return content:gsub([=[['"]TRIGSTR_(%d+)['"]]=], function(i)
		local str_data = wts[i]
		if not str_data then
			return
		end
		local text = str_data.text
		if only_short and #text > 256 then
			return
		end
		str_data.converted = not read_only
		if text:match '[\n\r]' then
			return ('[[\n%s\n]]'):format(text)
		else
			return ('%q'):format(text)
		end
	end)
end

mt.dir = {}
function mt:set_dir(name, dir)
	self.dir[name] = dir
end

mt.metadata = {}
function mt:set_metadata(name, metadata)
	self.metadata[name] = metadata
end

function mt:read_config()
	self.config = lni:loader(io.load(self.dir['root'] / 'config.ini'), 'config')

	for file_name, meta_name in pairs(self.config['metadata']) do
		self:set_metadata(file_name, meta_name)
	end

	return self.config
end

function mt:lni2w3x(name, file)
	if name:sub(-4) == '.ini' and self.config['metadata'][name:sub(1, -5)] then
		print('正在转换:', name)
		local data = lni:loader(file, name)
		local key = lni:loader(io.load(self.dir['meta'] / name), name)
		local metadata = self:read_metadata(self.config['metadata'][name:sub(1, -5)])
		local content = self:lni2obj(data, metadata, key)
		return name:sub(1, -5), content
	elseif name == 'war3map.w3i.ini' then
	else
		return name, file
	end
end

function mt:w3x2lni(files, paths)
	--读取编辑器文本
	local editstring
	local ini = self:read_ini(self.dir['meta'] / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end
	
	--读取字符串
	local wts
	if files['war3map.wts'] then
		wts = self:read_wts(files['war3map.wts'])
	end
	
	local clock = os.clock()
	local success, failed = 0, 0
	local function save(path, content)
		if io.save(path, content) then
			success = success + 1
		else
			failed = failed + 1
			print('文件导出失败', name)
		end
		if os.clock() - clock >= 0.5 then
			clock = os.clock()
			if failed == 0 then
				print('正在导出', '成功:', success)
			else
				print('正在导出', '成功:', success, '失败:', failed)
			end
		end
	end
	for name, file in pairs(files) do
		if self.config['metadata'][name] then
			local content = file
			print('正在转换:' .. name)
			local metadata = self:read_metadata(self.config['metadata'][name])
			local data = self:read_obj(content, metadata)
			local content = self:obj2lni(data, metadata, editstring)
			local content = self:convert_wts(content, wts)
			save(paths[name]:parent_path() / (name .. '.ini'), content)
		elseif name == 'war3map.w3i' then
			save(paths[name], file)
			local content = file
			local w3i = self:read_w3i(content)
			local content = self:w3i2lni(w3i)
			local content = self:convert_wts(content, wts, false, true)
			save(paths['war3map.w3i']:parent_path() / 'war3map.w3i.ini', content)
		elseif name == 'war3map.wts' then
		else
			save(paths[name], file)
		end
	end
	
	if failed == 0 then
		print('导出完毕', '成功:', success)
	else
		print('导出完毕', '成功:', success, '失败:', failed)
	end

	--刷新字符串
	if wts then
		local content = self:fresh_wts(wts)
		io.save(paths['war3map.wts'], content)
	end
end

function mt:extract_files(map_path, get_output_dir)
	local files = {}
	local paths = {}
	local dirs = {}
	local map = stormlib.open(map_path)
	local clock = os.clock()
	local success, failed = 0, 0
	for name in pairs(map) do
		name = name:lower()
		local new_name, output_dir = get_output_dir(name)
		if new_name and output_dir then
			if not dirs[output_dir:string()] then
				dirs[output_dir:string()] = true
				remove_then_create_dir(output_dir)
			end
			local path = output_dir / new_name
			fs.create_directories(path:parent_path())
			local buf = map:load_file(name)
			if buf then
				files[name] = buf
				paths[name] = path
				success = success + 1
			else
				failed = failed + 1
				print('文件读取失败', name)
			end
			if os.clock() - clock >= 0.5 then
				clock = os.clock()
				if failed == 0 then
					print('正在读取', '成功:', success)
				else
					print('正在读取', '成功:', success, '失败:', failed)
				end
			end
		end
	end
    if failed == 0 then
        print('读取完毕', '成功:', success)
    else
	    print('读取完毕', '成功:', success, '失败:', failed)
    end
	map:close()
	return files, paths
end

function mt:create_map()
	return create_map(self)
end

function mt:init(root_dir)
	self:set_dir('root', root_dir)
	self:set_dir('meta', root_dir / 'meta')
	self:read_config()
end

local function main()
	-- 加载脚本
	local convertors = {
		'read_wts', 'fresh_wts',
		'obj2lni', 'lni2obj',
		'w3i2lni',
		'read_obj', 'read_ini',
		'read_w3i',
		'read_metadata',
		'key2id',
	}
	
	for _, name in ipairs(convertors) do
		local func = require('impl.' .. name)
		mt[name] = function (self, ...)
			print(('正在执行:') .. name)
			return func(self, ...)
		end
	end
end

main()

return mt
