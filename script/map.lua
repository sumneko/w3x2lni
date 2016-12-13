local stormlib = require 'ffi.stormlib'
local progress = require 'progress'
local w2l = require 'w3x2lni'
w2l:initialize()

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
            else
                tbl1[k] = v
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
	for _, name in ipairs(w2l.info['pack']['packignore']) do
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
    -- TODO: 这个判断二进制的方法不科学
	if name:sub(-4) == '.ini' and w2l.info['metadata'][name:sub(1, -5)] then
		message('正在转换:', name)
		local data = w2l:parse_lni(file, name)
		local new_name = name:sub(1, -5)
        if self.on_lni then
            data = self:on_lni(new_name, data)
        end
        if w2l.wts then
            w2l.wts:save(data)
        end
		local key = w2l:parse_lni(io.load(w2l.key / name), name)
		local metadata = w2l:read_metadata(new_name)
		local template = w2l:parse_lni(io.load(w2l.template / name), new_name)
		local content = w2l:lni2obj(data, metadata, key, template)
		return new_name, content
	elseif name == 'war3map.w3i.ini' then
		message('正在转换:', name)
		local data = w2l:parse_lni(file, name)
		local new_name = name:sub(1, -5)
        if self.on_lni then
            data = self:on_lni(new_name, data)
        end
        if w2l.wts then
            w2l.wts:save(data)
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
	w2l:read_wts(files['war3map.wts'] or '')
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
    local content = w2l.wts:refresh()
    map:save_file('war3map.wts', content)
    if not files['war3mapunits.doo'] then
        map:save_file('war3mapunits.doo', w2l:create_unitsdoo())
    end
end

function mt:import_imp(map, listfile)
	local imp_ignore = {}
	for _, name in ipairs(w2l.info['pack']['impignore']) do
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
            w3i = w2l:read_w3i(w2l:lni2w3i(w2l:parse_lni(io.load(dir / 'war3map.w3i.ini'), 'war3map.w3i.ini')))
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

function mt:load_misc()
    local misc = {}
    for _, name in ipairs {"UI\\MiscData.txt", "Units\\MiscData.txt", "Units\\MiscGame.txt"} do
        add_table(misc, w2l:parse_ini(io.load(w2l.mpq / name)))
    end
    local name = "war3mapmisc.txt"
    if self.files[name] then
        add_table(misc, w2l:parse_ini(self.files[name](name)))
    end
    self.slk['misc'] = misc
end

function mt:to_lni()
    w2l:backend(self.files, self.slk, self.on_lni)
end

function mt:post_process()
    w2l:backend_processing(self.slk)
end

function mt:load_data()
	self.slk = w2l:frontend(self.files)
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

    progress:target(100)
    local clock = os.clock()
    local count = 0
    for name, path in pairs(paths) do
        local dir = (path / name):remove_filename()
        if not fs.exists(dir) then
            fs.create_directories(dir)
        end
        io.save(path / name, self.files[name](name))
        count = count + 1
		if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(count / max_count)
            message(('正在导出文件... (%d/%d)'):format(count, max_count))
		end
    end
end

function mt:load_mpq(mappath)
    local map
    if type(mappath) == 'number' then
        map = stormlib.attach(mappath)
    else
        map = stormlib.open(mappath, true)
    end
	if not map then
		message('地图打开失败')
		return false
	end

    local function loader(name)
        return map:load_file(name)
    end

    local function add_file(name, read)
        local name = name:lower()
        if not map:has_file(name) then
            return
        end
        if read then
            local content = loader(name)
            self.files[name] = function() return content end
        else
            self.files[name] = loader
        end
    end

	for name in pairs(map) do
		add_file(name)
	end
    for _, name in pairs(w2l.info.template.obj) do
        add_file(name, true)
    end
    for _, names in pairs(w2l.info.template.slk) do
        for _, name in ipairs(names) do
            add_file(name, true)
        end
    end
    for _, names in pairs(w2l.info.template.txt) do
        for _, name in ipairs(names) do
            add_file(name, true)
        end
    end
    add_file("war3mapmisc.txt", true)
end

function mt:load_dir(mappath)
    local function loader(name)
        return map:load_file(name)
    end

    local function add_file(name, read)
        local name = name:lower()
        if not map:has_file(name) then
            return
        end
        if read then
            local content = loader(name)
            self.files[name] = function() return content end
        else
            self.files[name] = loader
        end
    end

	for name in pairs(map) do
		add_file(name)
	end
    for _, name in pairs(w2l.info.template.obj) do
        add_file(name, true)
    end
    for _, names in pairs(w2l.info.template.slk) do
        for _, name in ipairs(names) do
            add_file(name, true)
        end
    end
    for _, names in pairs(w2l.info.template.txt) do
        for _, name in ipairs(names) do
            add_file(name, true)
        end
    end
end

function mt:load_file()
    for i, input in ipairs(self.inputs) do
        progress:target(3 * i / #self.inputs)
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
    message('正在处理物编...')
    self:post_process()
    if convert_type == 'lni' then
	    self:to_lni()
    else
        self:save_map(output_dir)
    end

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
    self.inputs = {}
    self.files = {}
    self.slk = {}
    return self
end
