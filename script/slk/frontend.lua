local progress = require 'progress'

local setmetatable = setmetatable
local rawset = rawset

local function merge(a, b)
    for k, v in pairs(b) do
        a[k] = v
    end
end

local function table_merge(a, b)
    for k, v in pairs(b) do
        if a[k] and type(v) == 'table' then
            merge(a[k], v)
        else
            a[k] = v
        end
    end
end

local function copy(b)
    local a = {}
    for k, v in pairs(b) do
        a[k] = v
    end
    return a
end

local function copy2(a, b)
    local c = {}
    for k, v in pairs(a) do
        c[k] = b[k] or v
        b[k] = nil
    end
    for k, v in pairs(b) do
        c[k] = v
    end
    return c
end

local function table_copy(a, b)
    local c = {}
    for k, v in pairs(a) do
        if b[k] then
            if type(v) == 'table' then
                c[k] = copy2(v, b[k])
            else
                c[k] = b[k]
            end
            b[k] = nil
        else
            if type(v) == 'table' then
                c[k] = copy(v)
            else
                c[k] = v
            end
        end
    end
    for k, v in pairs(b) do
        if type(v) == 'table' then
            c[k] = copy(v)
        else
            c[k] = v
        end
    end
    return c
end

local function copy_obj(b)
    local a = {}
    for k, v in pairs(b) do
        if type(v) == 'table' then
            a[k] = copy_obj(v)
        else
            a[k] = v
        end
    end
    return a
end

local function merge_obj(data, objs)
    local template = {}
    for name, obj in pairs(objs) do
        if data[name] then
            template[name] = copy_obj(data[name])
            table_merge(data[name], obj)
        else
            data[name] = table_copy(template[obj._lower_parent] or data[obj._lower_parent], obj)
        end
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
        return datas, txt
    else
        local datas = {}
        local i = 0
        for type in pairs(w2l.info.slk) do
            datas[type] = {}
            w2l:parse_lni(io.load(w2l.default / (type .. '.ini')), type, datas[type])
            setmetatable(datas[type], nil)
            i = i + 1
            progress(i / 7)
        end
        local txt = w2l:parse_lni(io.load(w2l.default / 'txt.ini'))
        return datas, txt
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

local function update_then_merge(w2l, datas, objs, lnis, slk)
    local i = 0
    for type, data in pairs(datas) do
        local obj = objs[type] or {}
        if lnis[type] then
            w2l:frontend_updatelni(type, lnis[type], data)
            merge(obj, lnis[type])
        end
        merge_obj(data, obj)
        slk[type] = data
        i = i + 1
        progress(i / 7)
    end
end

return function(w2l, archive, slk)
    --读取字符串
    slk.wts = w2l:frontend_wts(archive)
    progress(0.1)

    message('读取obj...')
    progress:start(0.2)
    local objs, force_slk1 = load_obj(w2l, archive, slk.wts)
    progress:finish()

    message('读取lni...')
    progress:start(0.3)
    local lnis, force_slk2 = load_lni(w2l, archive)
    progress:finish()

    message('读取slk...')
    progress:start(0.4)
    local datas, txt = load_slk(w2l, archive, force_slk1 or force_slk2)
    progress:finish()
    
    message('合并物编数据...')
    progress:start(0.5)
    update_then_merge(w2l, datas, objs, lnis, slk)
    progress:finish()
    slk.txt = txt
    w2l:frontend_misc(archive, slk)

    message('处理物编数据...')
    progress:start(1)
    w2l:frontend_processing(slk)
    progress:finish()
end
