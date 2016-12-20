local progress = require 'progress'
local w2l = require 'w3x2lni'
local archive = require 'archive'
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

local mt = {}
mt.__index = mt

function mt:save_dir(output_dir)
    local paths = {}
    local max_count = 0

    for name in pairs(self.archive) do
        local path = output_dir
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
        io.save(path / name, self.archive:get(name))
        count = count + 1
		if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(count / max_count)
            message(('正在导出文件... (%d/%d)'):format(count, max_count))
		end
    end
end

function mt:save_map(output_path)
    local map = archive(output_path, 'w')
    for name, buf in pairs(self.archive) do
        map:set(name, buf)
    end

    progress:target(100)
    map:save(w2l.info, self.slk)
    map:close()
end

function mt:load_file(input)
    self.archive = archive(input)
    if not self.archive then
        return false
    end
    return true
end

function mt:save(input)
    message('正在打开地图...')
    if not self:load_file(input) then
        message('地图打开失败')
        return false
    end
    message('正在读取物编...')
    self.slk = {}
	w2l:frontend(self.archive, self.slk)
    message('正在转换...')
    w2l:backend_processing(self.slk)
    w2l:backend(self.archive, self.slk)

    local output = input:parent_path() / input:stem()
    if w2l.config.target_storage == 'dir' then
        message('正在清空输出目录...')
        remove_then_create_dir(output)
        message('正在导出文件...')
        self:save_dir(output)
    elseif w2l.config.target_storage == 'map' then
        message('正在打包地图...')
        self:save_map(output:parent_path() / (output:filename():string() .. '_slk.w3x'))
    end
    self.archive:close()
    progress:target(100)
    return true
end

return function ()
    local self = setmetatable({}, mt)
    self.slk = {}
    return self
end
