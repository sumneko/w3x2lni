local progress = require 'progress'
local w2l = require 'w3x2lni'
local archive = require 'archive'
local create_map = require 'create_map'
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

function mt:add_input(input)
    self.inputs[#self.inputs+1] = input
end

function mt:load_misc()
    w2l:frontend_misc(self.archive, self.slk)
end

function mt:backend()
    w2l:backend(self.archive, self.slk, self.on_lni)
end

function mt:load_data()
    self.slk = {}
	w2l:frontend(self.archive, self.slk)
end

function mt:save_dir(output_dir)
    local paths = {}
    local max_count = 0

    for name in pairs(self.archive) do
        local path = output_dir
		if self.on_save then
            name, path = self:on_save(name)
        end
        if name and path then
            local ex = name:sub(-4)
            if ex == '.slk' or ex == '.txt' then
                paths[name] = path
                max_count = max_count + 1
            end
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
    local map = create_map(self.slk.w3i, w2l.info)

    for name, buf in pairs(self.archive) do
        map:add(name, buf)
    end

    map:save(output_path)
end

function mt:load_file()
    self.archive = archive(self.inputs[1])
    if not self.archive then
        return false
    end
    return true
end

function mt:save(output_dir)
    message('正在打开地图...')
    if not self:load_file() then
        message('地图打开失败')
        return false
    end
    message('正在读取物编...')
    self:load_data()
    message('正在处理物编...')
    message('正在转换...')
    w2l:backend_processing(self.slk)
    self:backend()

    if w2l.config.target_storage == 'dir' then
        message('正在清空输出目录...')
        remove_then_create_dir(output_dir)
        message('正在导出文件...')
        self:save_dir(output_dir)
    elseif w2l.config.target_storage == 'map' then
        message('正在打包地图...')
        self:save_map(output_dir:parent_path() / (output_dir:filename():string() .. '_slk.w3x'))
    end
    progress:target(100)
    return true
end

return function ()
    local self = setmetatable({}, mt)
    self.inputs = {}
    self.slk = {}
    return self
end
