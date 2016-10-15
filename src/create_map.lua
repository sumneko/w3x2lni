local stormlib = require 'stormlib'
local lni = require 'lni'

local table_insert = table.insert

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

local function remove_then_create_dir(dir)
	if fs.exists(dir) then
		task(fs.remove_all, dir)
	end
	task(fs.create_directories, dir)
end

local mt = {}
mt.__index = mt

function mt:add(format, ...)
    self.hexs[#self.hexs+1] = (format):pack(...)
end

function mt:add_head()
    self:add('c4', 'HM3W')
    self:add('c4', '\0\0\0\0')
end

function mt:add_name()
    self:add('z', self.w3i.map_name)
end

function mt:add_flag()
    self:add('l', self.w3i.map_flag)
end

function mt:add_playercount()
    self:add('l', self.w3i.player_count)
end

function mt:add_input(input)
    if fs.is_directory(input) then
        if #self.w3xs > 0 then
            return false
        end
        table_insert(self.dirs, input)
    else
        if #self.dirs > 0 then
            return false
        end
        table_insert(self.w3xs, input)
    end
    return true
end

function mt:get_listfile()
    local files = {}
    local dirs = {}
    local listfile = {}
	local pack_ignore = {}
	for _, name in ipairs(self.config['pack']['packignore']) do
		pack_ignore[name:lower()] = true
	end
    
	local clock = os.clock()
	local success, failed = 0, 0
    for _, dir in ipairs(self.dirs) do
        local dir_len = #dir:string()
        dir_scan(dir, function(path)
            local name = path:string():sub(dir_len+2)
            if not pack_ignore[name:lower()] then
                listfile[#listfile+1] = name
                files[name] = io.load(path)
                dirs[name] = dir
                if files[name] then
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
        end)
    end
    if failed == 0 then
        print('读取完毕', '成功:', success)
    else
	    print('读取完毕', '成功:', success, '失败:', failed)
    end
	return listfile, files, dirs
end

function mt:lni2w3x(name, file)
	if name:sub(-4) == '.ini' and self.config['metadata'][name:sub(1, -5)] then
		print('正在转换:', name)
		local data = lni:loader(file, name)
		local new_name = name:sub(1, -5)
        if self.on_lni then
            data = self:on_lni(new_name, data)
        end
		local key = lni:loader(io.load(self.dir['meta'] / name), name)
		local metadata = self.w3x2txt:read_metadata(self.config['metadata'][name:sub(1, -5)])
		local content = self.w3x2txt:lni2obj(data, metadata, key)
		return new_name, content
	elseif name == 'war3map.w3i.ini' then
	else
		return name, file
	end
end

function mt:import_files(map, listfile, files, dirs)
	local clock = os.clock()
	local success, failed = 0, 0
	for i = 1, #listfile do
		local name = listfile[i]
        local content = files[name]
        if self.on_save then
            name, content = self:on_save(name, content, dirs[name])
        end
        if name then
            local name, content = self:lni2w3x(name, content)
            if content then
                if map:save_file(name, content) then
                    success = success + 1
                else
                    failed = failed + 1
                    print('文件导入失败', name)
                end
                if os.clock() - clock >= 0.5 then
                    clock = os.clock()
                    if failed == 0 then
                        print('正在导入', '成功:', success)
                    else
                        print('正在导入', '成功:', success, '失败:', failed)
                    end
                end
            end
        end
	end
    if failed == 0 then
        print('导入完毕', '成功:', success)
    else
	    print('导入完毕', '成功:', success, '失败:', failed)
    end
end

function mt:import_imp(map, listfile)
	local imp_ignore = {}
	for _, name in ipairs(self.config['pack']['impignore']) do
		imp_ignore[name:lower()] = true
	end

	local imp = {}
	for _, name in ipairs(listfile) do
		if not imp_ignore[name:lower()] then
			imp[#imp+1] = ('z'):pack(name)
		end
	end
	table.insert(imp, 1, ('ll'):pack(1, #imp))
	if not map:save_file('war3map.imp', table.concat(imp, '\r')) then
		print('war3map.imp导入失败')
	end
end

function mt:save_map(map_path)
    local w3i = {
        map_name = '只是另一张魔兽争霸III地图',
        map_flag = 0,
        player_count = 2333,
    }
    for _, dir in ipairs(self.dirs) do
        if fs.exists(dir / 'war3map.w3i') then
            w3i = self.w3x2txt:read_w3i(io.load(dir / 'war3map.w3i'))
            break
        end
    end

    self.hexs = {}
    self.w3i  = w3i

    self:add_head()
    self:add_name()
    self:add_flag()
    self:add_playercount()

    local temp_path = fs.path 'temp'

    io.save(temp_path, table.concat(self.hexs))
    
    local listfile, files, dirs = self:get_listfile()
    local map = stormlib.create(temp_path, #listfile+8)
	if not map then
		print('地图创建失败,可能是文件被占用了')
		return nil
	end

	self:import_files(map, listfile, files, dirs)
	self:import_imp(map, listfile)

    map:close()
    fs.rename(temp_path, map_path)
    
    return true
end

function mt:extract_files(map_path, output_dir)
	local files = {}
	local paths = {}
	local dirs = {}
	local map = stormlib.open(map_path)
	local clock = os.clock()
	local success, failed = 0, 0
	for name in pairs(map) do
		name = name:lower()
		local new_name, output_dir = name, output_dir
        if self.on_save then
            new_name, output_dir = self:on_save(name)
        end
		if new_name then
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

function mt:w3x2lni(files, paths)
	--读取编辑器文本
	local editstring
	local ini = self.w3x2txt:read_ini(self.dir['meta'] / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end
	
	--读取字符串
	local wts
	if files['war3map.wts'] then
		wts = self.w3x2txt:read_wts(files['war3map.wts'])
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
			local metadata = self.w3x2txt:read_metadata(self.config['metadata'][name])
			local data = self.w3x2txt:read_obj(content, metadata)
            if self.on_lni then
                data = self:on_lni(name, data)
            end
			local content = self.w3x2txt:obj2lni(data, metadata, editstring)
			local content = self.w3x2txt:convert_wts(content, wts)
			save(paths[name]:parent_path() / (name .. '.ini'), content)
		elseif name == 'war3map.w3i' then
			save(paths[name], file)
			local content = file
			local data = self.w3x2txt:read_w3i(content)
            if self.on_lni then
                data = self:on_lni(name, data)
            end
			local content = self.w3x2txt:w3i2lni(data)
			local content = self.w3x2txt:convert_wts(content, wts, false, true)
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
		local content = self.w3x2txt:fresh_wts(wts)
		io.save(paths['war3map.wts'], content)
	end
end

function mt:unpack(output_dir)
    local map_path = self.w3xs[1]
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
	
	local files, paths = self:extract_files(map_path, output_dir)
	self:w3x2lni(files, paths)
end

function mt:save(map_path)
    if #self.dirs > 0 then
        return self:save_map(map_path)
    elseif #self.w3xs > 0 then
        return self:unpack(map_path)
    end
    return false
end

return function (w3x2txt)
    local self = setmetatable({}, mt)
    self.dirs = {}
    self.w3xs = {}
    self.config = w3x2txt.config
    self.dir = w3x2txt.dir
    self.w3x2txt = w3x2txt
    return self
end
