local mpq = require 'map-builder.archive_mpq'
local dir = require 'map-builder.archive_dir'

local os_clock = os.clock

local mt = {}
mt.__index = mt

function mt:number_of_files()
    if self:get_type() == 'mpq' then
        return self.handle:number_of_files()
    else
        return self.handle:count_files()
    end
end

function mt:search_files()
    return self.handle:search_files()
end

function mt:get_type()
    return self._type
end

function mt:is_readonly()
    return self._read
end

function mt:save_file(name, buf, filetime)
    return self.handle:save_file(name, buf, filetime)
end

function mt:close()
    if self._attach then
        return false
    end
    return self.handle:close()
end

function mt:save(w3i, progress, encrypt)
    if self:is_readonly() then
        return false
    end
    local max = 0
    for _ in pairs(self) do
        max = max + 1
    end
    if not self.handle:save(self.path, w3i, max, encrypt) then
        return false
    end
    local clock = os_clock()
    local count = 0
    for name, buf in pairs(self) do
        if buf then
            self.handle:save_file(name, buf)
            count = count + 1
            if os_clock() - clock > 0.1 then
                clock = os_clock()
                progress(count / max)
                if self:get_type() == 'mpq' then
                    print(('正在打包文件... (%d/%d)'):format(count, max))
                else
                    print(('正在导出文件... (%d/%d)'):format(count, max))
                end
            end
        end
    end
    return true
end

function mt:flush()
    if self:is_readonly() then
        return false
    end
    self._flushed = true
    self.cache = {}
    self.has_cache = {}
end

local function unify(name)
    return name:lower():gsub('/', '\\')
end

function mt:has(name)
    name = unify(name)
    if not self.handle then
        return false
    end
    if self.has_cache[name] ~= nil then
        return self.has_cache[name]
    end
    if self._flushed then
        return
    end
    return self.handle:has_file(name)
end

function mt:set(name, buf)
    name = unify(name)
    self.cache[name] = buf
end

function mt:remove(name)
    name = unify(name)
    self.cache[name] = false
end

function mt:get(name)
    name = unify(name)
    if self.cache[name] then
        return self.cache[name]
    end
    if self.cache[name] == false then
        return nil
    end
    if not self.handle then
        return nil
    end
    if self._flushed then
        return nil
    end
    local buf = self.handle:load_file(name)
    if buf then
        self.cache[name] = buf
        self.has_cache[name] = true
    else
        self.has_cache[name] = false
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
        has_cache = {},
        path = pathorhandle,
        _read = read_only,
    }
    if type(pathorhandle) == 'number' then
        ar.handle = mpq(pathorhandle)
        ar._type = 'mpq'
        ar._attach = true
        ar._read = false
    elseif read_only then
        if fs.is_directory(pathorhandle) then
            ar.handle = dir(pathorhandle)
            ar._type = 'dir'
        else
            ar.handle = mpq(pathorhandle, true)
            ar._type = 'mpq'
        end
        if not ar.handle then
            print('地图打开失败')
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
