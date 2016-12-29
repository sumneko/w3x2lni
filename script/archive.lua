local mpq = require 'archive_mpq'
local dir = require 'archive_dir'
local progress = require 'progress'

local os_clock = os.clock

local mt = {}
mt.__index = mt

function mt:number_of_files()
    if self:get_type() == 'mpq' then
        return self.handle:number_of_files()
    else
        return -1
    end
end

function mt:get_type()
    return self._type
end

function mt:is_readonly()
    return self._read
end

function mt:close()
    return self.handle:close()
end

function mt:save(w3i, encrypt)
    if self:is_readonly() then
        return false
    end
    if not self.handle:save(self.path, w3i, self.write_count, encrypt) then
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
                if self:get_type() == 'mpq' then
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
    name = name:lower()
    if buf == nil then
        buf = false
    end
    if self.cache[name] == nil then
        if self:is_readonly() and self.handle:has_file(name) then
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
    name = name:lower()
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
        path = pathorhandle,
        know_count = 0,
        write_count = 0,
        _read = read_only,
    }
    if read_only then
        if fs.is_directory(pathorhandle) then
            ar.handle = dir(pathorhandle)
            ar._type = 'dir'
        else
            ar.handle = mpq(pathorhandle, true)
            ar._type = 'mpq'
        end
        if not ar.handle then
            message('地图打开失败')
            return nil
        end
    else
        if fs.is_directory(pathorhandle) then
            ar.handle = dir(pathorhandle)
            ar._type = 'dir'
        else
            ar.handle = mpq(pathorhandle)
            ar._type = 'mpq'
        end
    end
    return setmetatable(ar, mt)
end
