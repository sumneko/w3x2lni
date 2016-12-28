local stormlib = require 'ffi.stormlib'
local mpq = require 'archive_mpq'
local dir = require 'archive_dir'
local progress = require 'progress'
local sleep = require 'ffi.sleep'

local os_clock = os.clock

local function task(f, ...)
	for i = 1, 99 do
		if pcall(f, ...) then
			return
		end
		sleep(10)
	end
	f(...)
end

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

local function create_map(path, w3i, n, encrypt)
    local hexs = {}
    hexs[#hexs+1] = ('c4'):pack('HM3W')
    hexs[#hexs+1] = ('c4'):pack('\0\0\0\0')
    hexs[#hexs+1] = ('z'):pack(w3i and w3i['地图']['地图名称'] or '未命名地图')
    hexs[#hexs+1] = ('l'):pack(get_map_flag(w3i))
    hexs[#hexs+1] = ('l'):pack(w3i and w3i['玩家']['玩家数量'] or 233)
    io.save(path, table.concat(hexs))
    return stormlib.create(path, n, encrypt)
end

local mt = {}
mt.__index = mt

function mt:number_of_files()
    return self.handle:number_of_files()
end

function mt:get_type()
    return self._type
end

function mt:close()
    self.handle:close()
end

function mt:save(w3i, encrypt)
    if self._type == 'mpq' then
        self.handle = create_map(self.path, w3i, self.write_count, encrypt)
    else
        if fs.exists(self.path) then
            task(fs.remove_all, self.path)
        end
        task(fs.create_directories, self.path)
    end
    if not self.handle then
        return false
    end
    local clock = os_clock()
    local count = 0
    for name, buf in pairs(self.cache) do
        if buf then
            self.handle:save_file(name, buf)
            count = count + 1
            if os_clock() - clock > 0.1 then
                clock = os_clock()
                progress(count / self.write_count)
                if self._type == 'mpq' then
                    message(('正在打包文件... (%d/%d)'):format(count, self.write_count))
                else
                    message(('正在导出文件... (%d/%d)'):format(count, self.write_count))
                end
            end
        end
    end
    return true
end

function mt:set(name, buf)
    if buf == nil then
        buf = false
    end
    if self.cache[name] == nil then
        if self.handle and self.handle:has_file(name) then
            self.know_count = self.know_count + 1
        end
    end
    if self.cache[name] then
        self.write_count = self.write_count - 1
    end
    if buf then
        self.write_count = self.write_count + 1
    end
    self.cache[name] = buf
end

function mt:get(name)
    if self.cache[name] then
        return self.cache[name]
    end
    if self.cache[name] == false then
        return nil
    end
    if not self.handle then
        return nil
    end
    local buf = self.handle:load_file(name)
    if buf then
        self.cache[name] = buf
        self.know_count = self.know_count + 1
        self.write_count = self.write_count + 1
    end
    return buf
end

function mt:__pairs()
    return next, self.cache
end

return function (pathorhandle, tp)
    local read_only = tp ~= 'w'
    local ar = {
        cache = {},
        ignore_file = {},
        path = pathorhandle,
        know_count = 0,
        write_count = 0,
    }
    if read_only then
        if type(pathorhandle) == 'number' then
            ar.handle = mpq.attach(pathorhandle)
            ar._type = 'mpq'
        elseif fs.is_directory(pathorhandle) then
            ar.handle = dir.create(pathorhandle)
            ar._type = 'dir'
        else
            ar.handle = mpq.open(pathorhandle, true)
            ar._type = 'mpq'
        end
        if not ar.handle then
            message('地图打开失败')
            return nil
        end
        if ar._type == 'mpq' and not ar.handle:has_file '(listfile)' then
            message('不支持没有(listfile)的地图')
            return nil
        end
    else
        if type(pathorhandle) == 'number' then
            ar._type = 'mpq'
        elseif fs.is_directory(pathorhandle) then
            ar.handle = dir.create(pathorhandle)
            ar._type = 'dir'
        else
            ar._type = 'mpq'
        end
    end
    return setmetatable(ar, mt)
end
