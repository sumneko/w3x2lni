local stormlib = require 'stormlib'

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

function mt:add_dir(dir)
    table_insert(self.dirs, dir)
end

function mt:get_listfile()
    local files = {}
    local listfile = {}
	local pack_ignore = {}
	for _, name in ipairs(self.config['pack']['packignore']) do
		pack_ignore[name:lower()] = true
	end
    
    for _, dir in ipairs(self.dirs) do
        local dir_len = #dir:string()
        dir_scan(dir, function(path)
            local name = path:string():sub(dir_len+2)
            if not pack_ignore[name:lower()] then
                listfile[#listfile+1] = name
                files[name] = io.load(path)
            end
        end)
    end
	return listfile, files
end

function mt:import_files(map, listfile, files, on_save)
	local clock = os.clock()
	local success, failed = 0, 0
	for i = 1, #listfile do
		local name = listfile[i]
        local name, content = on_save(name, files[name])
        if content then
            if map:save_file(name, content) then
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
	end
	print('导入完毕', '成功:', success, '失败:', failed)
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

function mt:save(map_path, on_save)
    local listfile, files = self:get_listfile()

    io.save(map_path, table.concat(self.hexs))
    
    local map = stormlib.create(map_path, #listfile+8)
	if not map then
		print('地图创建失败,可能是文件被占用了')
		return nil
	end

	self:import_files(map, listfile, files, on_save)
	self:import_imp(map, listfile)

    map:close()
    return true
end

return function (config, w3i)
    if not w3i then
        w3i = {
            map_name = '只是另一张魔兽争霸III地图',
            map_flag = 0,
            player_count = 2333,
        }
    end
    local tbl = setmetatable({}, mt)
    tbl.hexs = {}
    tbl.w3i  = w3i
    tbl.dirs = {}
    tbl.config = config

    tbl:add_head()
    tbl:add_name()
    tbl:add_flag()
    tbl:add_playercount()
    return tbl
end
