local stormlib = require 'ffi.stormlib'
local progress = require 'progress'

local mt = {}
mt.__index = mt

local function load_file(self, filename)
    local buf = self.handle:load_file(filename)
    if buf then
        if not self.listfile[filename] then
            self.listfile[filename] = true
            self.file_number = self.file_number + 1
        end
        return buf
    end
    return false
end

local function has_file(self, filename)
    local ok = self.handle:has_file(filename)
    if ok then
        if not self.listfile[filename] then
            self.listfile[filename] = true
            self.file_number = self.file_number + 1
        end
    end
    return ok
end

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
    local buf = load_file(self, filename)
    if buf then
        self.cache[filename] = buf
        return buf
    end
    self.cache[filename] = false
    return false, ('文件 %q 不存在'):format(filename)
end

function mt:close()
    self.handle:close()
end

function mt:save(slk, info, config)
    local w3i = slk.w3i
    local packignore = info and info.pack.packignore
    local impignore = info and info.pack.impignore

    local hexs = {}

    hexs[#hexs+1] = ('c4'):pack('HM3W')
    hexs[#hexs+1] = ('c4'):pack('\0\0\0\0')
    hexs[#hexs+1] = ('z'):pack(w3i and w3i.map_name or '未命名地图')
    hexs[#hexs+1] = ('l'):pack(w3i and w3i.map_flag or 0)
    hexs[#hexs+1] = ('l'):pack(w3i and w3i.player_count or 233)

    io.save(self.path, table.concat(hexs))

    local files = {}
    local imp = {}
    for name in pairs(self.cache) do
        if not packignore[name] then
            files[#files+1] = name
            if not impignore[name] then
                imp[#imp+1] = name
            end
        end
    end
    table.sort(files)
    table.sort(imp)

    self.handle = stormlib.create(self.path, #files + 8)
    if not self.handle then
        message('创建新地图失败,可能文件被占用了')
        return
    end
    local clock = os.clock()
    for i, name in ipairs(files) do
        self.handle:save_file(name, self.cache[name])
		if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(i / #files)
            message(('正在打包文件... (%d/%d)'):format(i, #files))
		end
    end

    if not config or not config.remove_we_only then
        local hex = {}
        hex[1] = ('ll'):pack(1, #imp)
        for _, name in ipairs(imp) do
            hex[#hex+1] = ('z'):pack(name)
            hex[#hex+1] = '\r'
        end
        self.handle:save_file('war3map.imp', table.concat(hex))
    end
end

function mt:__pairs()
    local cache = self.cache
    if not self.cached_all then
        self.cached_all = true
        for filename in pairs(self.handle) do
            local filename = filename:lower()
            if cache[filename] == nil then
                cache[filename] = load_file(self, filename)
            else
                has_file(self, filename)
            end
        end
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
    local total = self.handle:number_of_files()
    if self.file_number < total then
        return false, ('读取(%d/%d)个文件，还有%d个文件没有读取'):format(self.file_number, total, total - self.file_number)
    end
    return true
end

return function (pathorhandle, tp)
    local ar = { cache = {}, path = pathorhandle }
    if tp ~= 'w' then
        if type(pathorhandle) == 'number' then
            ar.handle = stormlib.attach(pathorhandle)
        else
            ar.handle = stormlib.open(pathorhandle, true)
        end
        if not ar.handle then
            return nil
        end
        ar.listfile = {}
        ar.file_number = 0
    end
    return setmetatable(ar, mt)
end
