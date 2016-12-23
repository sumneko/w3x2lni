local stormlib = require 'ffi.stormlib'
local progress = require 'progress'

local os_clock = os.clock

local sleep = require 'ffi.sleep'
function task(f, ...)
	for i = 1, 99 do
		if pcall(f, ...) then
			return
		end
		sleep(10)
	end
	f(...)
end

local function scan_dir(dir, callback)
    for path in dir:list_directory() do
        if fs.is_directory(path) then
            scan_dir(path, callback)
        else
            callback(path)
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

function mt:set(filename, content)
    self.cache[filename] = content
end

function mt:get(filename)
    local filename = filename:lower()
    if self.cache[filename] ~= nil then
        if self.cache[filename] then
            return self.cache[filename]
        end
        return false, ('文件 %q 不存在'):format(filename)
    end
    local buf = io.load(self.path / filename)
    if buf then
        self.cache[filename] = buf
        return buf
    end
    self.cache[filename] = false
    return false, ('文件 %q 不存在'):format(filename)
end

function mt:close()
end

function mt:save(slk, info, config)
    local output = self.path
    message('正在清空输出目录...')
    remove_then_create_dir(output)

    local max_count = 0
    for name in pairs(self) do
        max_count = max_count + 1
	end

    local clock = os_clock()
    local count = 0
    for name, file in pairs(self) do
        local path = output / name
        local dir = path:parent_path()
        if not fs.exists(dir) then
            fs.create_directories(dir)
        end
        io.save(path, file)
        count = count + 1
		if os_clock - clock >= 0.1 then
            clock = os_clock
            progress(count / max_count)
            message(('正在导出文件... (%d/%d)'):format(count, max_count))
		end
    end
end

function mt:__pairs()
    local cache = self.cache
    if not self.cached_all then
        self.cached_all = true
        local len = #self.path:string()
        scan_dir(self.path, function(path)
            local filename = path:string():sub(len+2):lower()
            if cache[filename] == nil then
                cache[filename] = io.load(path)
            end
        end)
    end
    local function next_file(_, key)
        local new_key, value = next(cache, key)
        if value == false then
            return next_file(cache, new_key)
        end
        return new_key, value
    end
    return next_file, cache
end

function mt:sucess()
    return true
end

return function (path, tp)
    local ar = { cache = {}, path = fs.canonical(path) }
    return setmetatable(ar, mt)
end
