local stormlib = require 'ffi.stormlib'
local lni = require 'lni'
local read_ini = require 'read_ini'
local progress = require 'progress'
local w2l = require 'w3x2lni'

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

local function add_table(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if tbl1[k] then
            if type(tbl1[k]) == 'table' and type(v) == 'table' then
                add_table(tbl1[k], v)
            end
        else
            tbl1[k] = v
        end
    end
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
    table_insert(self.inputs, input)
    return true
end

function mt:get_listfile()
    local files = {}
    local dirs = {}
    local listfile = {}
	local pack_ignore = {}
	for _, name in ipairs(self.info['pack']['packignore']) do
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
                    message('文件读取失败', name)
                end
                if os.clock() - clock >= 0.5 then
                    clock = os.clock()
                    if failed == 0 then
                        message('正在读取', '成功:', success)
                    else
                        message('正在读取', '成功:', success, '失败:', failed)
                    end
                end
            end
        end)
    end
    if failed == 0 then
        message('读取完毕', '成功:', success)
    else
	    message('读取完毕', '成功:', success, '失败:', failed)
    end
	return listfile, files, dirs
end

function mt:to_w3x(name, file)
	if name:sub(-4) == '.ini' and self.info['metadata'][name:sub(1, -5)] then
		message('正在转换:', name)
		local data = lni:loader(file, name)
		local new_name = name:sub(1, -5)
        if self.on_lni then
            data = self:on_lni(new_name, data)
        end
        if self.wts then
            self.wts:save(data)
        end
		local key = lni:loader(io.load(self.dir['key'] / name), name)
		local metadata = w2l:read_metadata(self.dir['meta'] / self.info['metadata'][new_name])
		local template = lni:loader(io.load(self.dir['template'] / name), new_name)
		local content = w2l:lni2obj(data, metadata, key, template)
		return new_name, content
	elseif name == 'war3map.w3i.ini' then
		message('正在转换:', name)
		local data = lni:loader(file, name)
		local new_name = name:sub(1, -5)
        if self.on_lni then
            data = self:on_lni(new_name, data)
        end
        if self.wts then
            self.wts:save(data)
        end
		local content = w2l:lni2w3i(data)
		return new_name, content
	elseif name == 'war3map.w3i' then
		w3i = file
		return name, file
	else
		return name, file
	end
end

function mt:import_files(map, listfile, files, dirs)
	self.wts = w2l:read_wts(files['war3map.wts'] or '')
	local clock = os.clock()
	local success, failed = 0, 0
	for i = 1, #listfile do
		local name = listfile[i]
        local content = files[name]
        if self.on_save then
            name, content = self:on_save(name, content, dirs[name])
        end
        if name then
            local name, content = self:to_w3x(name, content)
            if content then
                if map:save_file(name, content) then
                    success = success + 1
                else
                    failed = failed + 1
                    message('文件导入失败', name)
                end
                if os.clock() - clock >= 0.5 then
                    clock = os.clock()
                    if failed == 0 then
                        message('正在导入', '成功:', success)
                    else
                        message('正在导入', '成功:', success, '失败:', failed)
                    end
                end
            end
        end
	end
    if failed == 0 then
        message('导入完毕', '成功:', success)
    else
	    message('导入完毕', '成功:', success, '失败:', failed)
    end
    local content = self.wts:refresh()
    map:save_file('war3map.wts', content)
    if not files['war3mapunits.doo'] then
        map:save_file('war3mapunits.doo', w2l:create_unitsdoo())
    end
end

function mt:import_imp(map, listfile)
	local imp_ignore = {}
	for _, name in ipairs(self.info['pack']['impignore']) do
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
		message('war3map.imp导入失败')
	end
end

function mt:save_map(map_path)
    local w3i = {
        map_name = '只是另一张魔兽争霸III地图',
        map_flag = 0,
        player_count = 2333,
    }
    for _, dir in ipairs(self.dirs) do
        if fs.exists(dir / 'war3map.w3i.ini') then
            w3i = w2l:read_w3i(w2l:lni2w3i(lni:loader(io.load(dir / 'war3map.w3i.ini'), 'war3map.w3i.ini')))
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
		message('地图创建失败,可能是文件被占用了')
		return nil
	end

	self:import_files(map, listfile, files, dirs)
	self:import_imp(map, listfile)

    map:close()
    fs.rename(temp_path, map_path)
    
    return true
end

function mt:load_slk(file_name, delete)
    local slk = w2l:slk_loader(file_name)
    
    local slk = self.info['template']['slk'][file_name]
    for i = 1, #slk do
        local name = slk[i]
        message('正在转换', name)
        slk:add_slk(w2l:read_slk(self.files[name] or io.load(self.dir['meta'] / name)))
        if self.files[name] then
            delete[name] = true
        end
    end

    local txt = self.info['template']['txt'][file_name]
    for i = 1, #txt do
        local name = txt[i]
        message('正在转换', name)
        slk:add_txt(w2l:read_txt(self.files[name] or io.load(self.dir['meta'] / name)))
        if self.files[name] then
            delete[name] = true
        end
    end

    return slk
end

function mt:to_lni()
	--读取编辑器文本
    progress:target(20)
	local ini = read_ini(self.dir['meta'] / 'WorldEditStrings.txt')
	if ini then
		self.editstring = ini['WorldEditStrings']
	end
	
	--读取字符串
    progress:target(21)
	if self.files['war3map.wts'] then
		self.wts = w2l:read_wts(self.files['war3map.wts'])
	end

    local delete = {}
    local count = 0
    for file_name, meta in pairs(self.info['metadata']) do
        count = count + 1
        local target_progress = 22 + count * 9
        progress:target(target_progress)
        
        local data = self.objs[file_name]
        if not data['_版本'] then
            data['_版本'] = 2
        end
        if self.on_lni then
            data = self:on_lni(file_name, data)
        end
        
        local metadata = w2l:read_metadata(self.dir['meta'] / self.info['metadata'][file_name])
        local temp_data = lni:loader(io.load(self.dir['template'] / (file_name .. '.ini')), file_name)
        local key_data = lni:loader(io.load(self.dir['key'] / (file_name .. '.ini')), file_name)
        local max_level_key = self.info['key']['max_level'][file_name]
        local content = w2l:obj2lni(data, metadata, self.editstring, temp_data, key_data, max_level_key, file_name)
        if self.wts then
            content = self.wts:load(content)
        end
        if content then
            self.files[file_name .. '.ini'] = content
        end
        progress(1)
    end

	--刷新字符串
	if self.wts then
        progress:target(86)
		local content = self.wts:refresh()
		self.files['war3map.wts'] = content
        progress(1)
	end
end

function mt:load_data()
    local delete = {}
    local count = 0
    for file_name, meta in pairs(self.info['metadata']) do
        count = count + 1
        local target_progress = 5 + count * 2
        self.objs[file_name] = {}

        local metadata = w2l:read_metadata(self.dir['meta'] / self.info['metadata'][file_name])
        local key_data = lni:loader(io.load(self.dir['key'] / (file_name .. '.ini')), file_name)

        if self.files[file_name] then
            progress:target(target_progress - 1)
            message('正在转换', file_name)
            add_table(self.objs[file_name], w2l:read_obj(self.files[file_name], metadata))
            delete[file_name] = true
            progress(1)
        end

        if self.config['unpack']['read_slk'] then
            progress:target(target_progress)
            local template = self:load_slk(file_name, delete)
            add_table(self.objs[file_name], template:save(metadata, key_data))
            progress(1)
        end

        local temp_data = lni:loader(io.load(self.dir['template'] / (file_name .. '.ini')), file_name)
        w2l:add_template(self.objs[file_name], metadata, key_data, temp_data)
    end

    for name in pairs(delete) do
        self.files[name] = nil
    end
end

function mt:save_dir(output_dir)
    local paths = {}
    local max_count = 0

    for name in pairs(self.files) do
        local path = output_dir
		if self.on_save then
            name, path = self:on_save(name)
        end
        if name and path then
            paths[name] = path
            max_count = max_count + 1
        end
	end

    local clock = os.clock()
    local count = 0
    for name, path in pairs(paths) do
        local dir = (path / name):remove_filename()
        if not fs.exists(dir) then
            fs.create_directories(dir)
        end
        io.save(path / name, self.files[name])
        count = count + 1
		if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(count / max_count)
		end
    end
end

function mt:load_mpq(map_path)
    local map = stormlib.open(map_path)
	if not map then
		message('地图打开失败')
		return false
	end

    local list = {}
    local files = {}
    local max_count = 0
    local function add_file(name)
        local name = name:lower()
        if not list[name] then
            list[name] = true
            max_count = max_count + 1
        end
    end

	for name in pairs(map) do
		add_file(name)
	end
	for name in pairs(self.info['metadata']) do
        add_file(name)
        for _, name in ipairs(self.info['template']['slk'][name]) do
            add_file(name)
        end
        for _, name in ipairs(self.info['template']['txt'][name]) do
            add_file(name)
        end
    end

    local clock = os.clock()
    local count = 0
    for name in pairs(list) do
        local buf = map:load_file(name)
        if buf then
            files[name] = buf
        end
        count = count + 1
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(count / max_count)
        end
    end

    map:close()

    add_table(self.files, files)
end

function mt:load_file()
    for i, input in ipairs(self.inputs) do
        progress:target(5 * i / #self.inputs)
        if fs.is_directory(input) then
            self:load_dir(input)
        else
            self:load_mpq(input)
        end
    end
    return true
end

function mt:save(output_dir, convert_type, output_type)
    message('正在打开地图...')
    self:load_file()
    message('正在读取物编...')
    self:load_data()
    if convert_type == 'lni' then
	    self:to_lni()
    else
        self:save_map(output_dir)
    end

    progress:target(100)
    if output_type == 'dir' then
        message('正在清空输出目录...')
        remove_then_create_dir(output_dir)
        message('正在导出文件...')
        self:save_dir(output_dir)
    end
    progress:target(100)
    return true
end

return function ()
    local self = setmetatable({}, mt)
    self.config = w2l.config
    self.info = w2l.info
    self.dir = w2l.dir
    w2l = w2l
    self.inputs = {}
    self.files = {}
    self.objs = {}
    return self
end
