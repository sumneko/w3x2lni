local progress = require 'progress'

local string_lower = string.lower
local setmetatable = setmetatable
local rawset = rawset
local is_remove_exceeds_level

local function fill_and_copy(a, lv)
    local c = {}
    if #a < lv then
        for i = 1, #a do
            c[i] = a[i] 
        end
        for i = #a+1, lv do
            c[i] = a[#a] 
        end
    else
        for i = 1, lv do
            c[i] = a[i] 
        end
    end
    return c
end

local function maxindex(t)
    local i = 0
    for k in pairs(t) do
        i = math.max(i, k)
    end
    return i
end

local function fill_and_merge(a, b, lv)
    local c = {}
    if #a < lv then
        for i = 1, #a do
            c[i] = b[i] or a[i] 
        end
        for i = #a+1, lv do
            c[i] = b[i] or a[#a] 
        end
    else
        for i = 1, lv do
            c[i] = b[i] or a[i] 
        end
    end
    if not is_remove_exceeds_level then
        local maxlv = maxindex(b)
        if maxlv > lv then
            for i = lv+1, maxlv do
                c[i] = b[i] or a[#a] 
            end
        end
    end
    return c
end

local function copy_obj(a, b)
    local c = {}
    local lv = b._max_level or a._max_level
    for k, v in pairs(a) do
        if b[k] then
            if type(v) == 'table' then
                c[k] = fill_and_merge(v, b[k], lv)
            else
                c[k] = b[k]
            end
            b[k] = nil
        else
            if type(v) == 'table' then
                c[k] = fill_and_copy(v, lv)
            else
                c[k] = v
            end
        end
    end
    for k, v in pairs(b) do
        -- 不应该会有等级数据
        assert(type(v) ~= 'table')
        c[k] = v
    end
    return c
end

local function merge_obj(data, objs)
    local template = {}
    for name, obj in pairs(objs) do
        local source = data[name]
        if source then
            template[name] = source
        else
            source = template[obj._parent] or data[obj._parent]
        end
        data[name] = copy_obj(source, obj)
    end
end

local function load_slk(w2l, archive, force_slk)
    if force_slk then
        message('-report', '物编信息不完整,强制读取slk文件')
    end
    if force_slk or w2l.config.read_slk then
        local datas, txt = w2l:frontend_slk(function(name)
            local buf = archive:get(name)
            if buf then
                archive:set(name, false)
                return buf
            end
            return io.load(w2l.mpq / name)
        end)
        datas.txt = txt
        return datas
    else
        return w2l:get_default(true)
    end
end

local function load_obj(w2l, archive, wts)
    local objs = {}
    local force_slk
    local count = 0
    for type, name in pairs(w2l.info.obj) do
        local buf = archive:get(name)
        local force
        local count = count + 1
        if buf then
            message('正在转换', name)
            objs[type], force = w2l:frontend_obj(type, wts, buf)
            progress(count / 7)
            if force then
                force_slk = true
            end
             archive:set(name, false)
        end
    end
    return objs, force_slk
end

local function load_lni(w2l, archive)
    local count = 0
    local lnis = {}
    for type, name in pairs(w2l.info.lni) do
        count = count + 1
        local buf = archive:get(name)
        if buf then
            message('正在转换', name)
            lnis[type] = w2l:frontend_lni(type, buf)
            progress(count / 7)
            archive:set(name, false)
        end
    end
    return lnis
end

local function update_then_merge(w2l, slks, objs, lnis, slk)
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        local data = slks[type]
        local obj = objs[type] or {}
        if lnis[type] then
            w2l:frontend_updatelni(type, lnis[type], data)
            for k, v in pairs(lnis[type]) do
                obj[k] = v
            end
        end
        merge_obj(data, obj)
        slk[type] = data
    end
end

return function(w2l, archive, slk)
    is_remove_exceeds_level = w2l.config.remove_exceeds_level

    --读取字符串
    slk.wts = w2l:frontend_wts(archive)
    progress(0.2)

    message('读取obj...')
    progress:start(0.4)
    local objs, force_slk1 = load_obj(w2l, archive, slk.wts)
    progress:finish()

    message('读取lni...')
    progress:start(0.6)
    local lnis, force_slk2 = load_lni(w2l, archive)
    progress:finish()

    message('读取slk...')
    progress:start(0.8)
    local slks = load_slk(w2l, archive, force_slk1 or force_slk2)
    progress:finish()
    
    message('合并物编数据...')
    progress:start(1)
    update_then_merge(w2l, slks, objs, lnis, slk)
    progress:finish()
    slk.txt = slks.txt
    w2l:frontend_misc(archive, slk)
end
