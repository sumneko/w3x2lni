local stormlib = require 'ffi.stormlib'
local progress = require 'progress'
local w2l = require 'w3x2lni'
local impignore

local os_clock = os.clock

local function get_map_flag(w3i)
    if not w3i then
        return 0
    end
    return w3i['选项']['关闭预览图']       << 0
         | w3i['选项']['自定义结盟优先权'] << 1
         | w3i['选项']['对战地图']        << 2
         | w3i['选项']['大型地图']        << 3
         | w3i['选项']['迷雾区域显示地形'] << 4
         | w3i['选项']['自定义玩家分组']   << 5
         | w3i['选项']['自定义队伍']       << 6
         | w3i['选项']['自定义科技树']     << 7
         | w3i['选项']['自定义技能']       << 8
         | w3i['选项']['自定义升级']       << 9
         | w3i['选项']['地图菜单标记']     << 10
         | w3i['选项']['地形悬崖显示水波'] << 11
         | w3i['选项']['地形起伏显示水波'] << 12
         | w3i['选项']['未知1']           << 13
         | w3i['选项']['未知2']           << 14
         | w3i['选项']['未知3']           << 15
         | w3i['选项']['未知4']           << 16
         | w3i['选项']['未知5']           << 17
         | w3i['选项']['未知6']           << 18
         | w3i['选项']['未知7']           << 19
         | w3i['选项']['未知8']           << 20
         | w3i['选项']['未知9']           << 21
end

local function create_map(path, w3i, n)
    local hexs = {}
    hexs[#hexs+1] = ('c4'):pack('HM3W')
    hexs[#hexs+1] = ('c4'):pack('\0\0\0\0')
    hexs[#hexs+1] = ('z'):pack(w3i and w3i['地图']['地图名称'] or '未命名地图')
    hexs[#hexs+1] = ('l'):pack(get_map_flag(w3i))
    hexs[#hexs+1] = ('l'):pack(w3i and w3i['玩家']['玩家数量'] or 233)
    io.save(path, table.concat(hexs))
    return stormlib.create(path, n, w2l.config.remove_we_only)
end

local mt = {}
mt.__index = mt

function mt:has_file(filename)
    local ok = self.handle:has_file(filename)
    if ok and not self._read[filename] then
        self._read[filename] = true
        self._read_number = self._read_number + 1
    end
    return ok
end

function mt:load_file(filename)
    local buf = self.handle:load_file(filename)
    if buf and not self._read[filename] then
        self._read[filename] = true
        self._read_number = self._read_number + 1
    end
    return buf
end

function mt:set(filename, content)
    local filename = filename:lower()
    self.cache[filename] = content
end

function mt:ignore(filename)
    local filename = filename:lower()
    self.ignore_file[filename] = true
end

function mt:get(filename)
    local filename = filename:lower()
    if self.cache[filename] ~= nil then
        if self.cache[filename] then
            return self.cache[filename]
        end
        return false, ('文件 %q 不存在'):format(filename)
    end
    local buf = self:load_file(filename)
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

function mt:write_file(filename)
    if self._hwrite[filename] then
        return
    end
    self._hwrite[filename] = true
    self._write[#self._write+1] = filename
    if not impignore[filename] then
        self._imp[#self._imp+1] = filename
    end
end

function mt:is_complete()
    local total = self.handle:number_of_files()
    if self._read_number < total then
        message('-report|error', ('还有%d个文件没有读取'):format(total -self._read_number))
        message('-tip', '这些文件被丢弃了,请包含完整(listfile)')
        message('-report|error', ('读取(%d/%d)个文件'):format(self._read_number, total))
    end
end

function mt:write_flush(input, slk)
    local cache = input.cache
    table.sort(self._write)
    table.sort(self._imp)
    if input.handle and not input:is_complete() then
    end
    self.handle = create_map(self.path, slk.w3i, #self._write)
    if not self.handle then
        message('创建新地图失败,可能文件被占用了')
        return
    end
    local clock = os_clock()
    for i, filename in ipairs(self._write) do
        if cache[filename] then
            self.handle:save_file(filename, cache[filename])
        else
            self.handle:save_file(filename, input:load_file(filename))
        end
		if os_clock() - clock >= 0.1 then
            clock = os_clock()
            progress(i / #self._write)
            message(('正在打包文件... (%d/%d)'):format(i, #self._write))
		end
    end
    if not w2l.config.remove_we_only then
        local hex = {}
        hex[1] = ('ll'):pack(1, #self._imp)
        for _, name in ipairs(self._imp) do
            hex[#hex+1] = ('z'):pack(name)
            hex[#hex+1] = '\r'
        end
        self.handle:save_file('war3map.imp', table.concat(hex))
    end
end

function mt:save(input, slk)
    impignore = w2l.info.pack.impignore
    local cache = input.cache
    local ignore = input.ignore_file
    for filename, v in pairs(cache) do
        if v then
            self:write_file(filename)
        end
    end
    for filename in pairs(input) do
        if input:has_file(filename) and not ignore[filename] and cache[filename] ~= false then
            self:write_file(filename)
        end
    end
    self:write_flush(input, slk)
end

function mt:__pairs()
    return pairs(self.handle)
end

return function (pathorhandle, tp)
    local ar = {
        cache = {}, 
        ignore_file = {},
        path = pathorhandle,
    }
    if tp ~= 'w' then
        if type(pathorhandle) == 'number' then
            ar.handle = stormlib.attach(pathorhandle)
        else
            ar.handle = stormlib.open(pathorhandle, true)
        end
        if not ar.handle then
            message('地图打开失败')
            return nil
        end
        if not ar.handle:has_file('(listfile)') then
            message('不支持没有(listfile)的地图')
            return nil
        end
        ar._read = {}
        ar._read_number = 0
    else
        ar._hwrite = {}
        ar._write = {}
        ar._imp = {}
    end
    return setmetatable(ar, mt)
end
