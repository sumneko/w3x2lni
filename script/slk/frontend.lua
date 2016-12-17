local progress = require 'progress'

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

local function merge_obj(data, objs)
    for name, obj in pairs(objs) do
        if data[name] then
            table_merge(data[name], obj)
        else
            data[name] = table_copy(data[obj._lower_code:lower()], obj)
        end
    end
end

local function load_slk(w2l, archive, force_slk)
    if force_slk or w2l.config.read_slk then
        local datas = w2l:frontend_slk(function(name)
            message('正在转换', name)
            local buf = archive:get(name)
            if buf then
                return buf
            end
            return io.load(w2l.mpq / name)
        end)
        return datas
    else
        local datas = {}
        for type in pairs(w2l.info.template.slk) do
            datas[type] = w2l:parse_lni(io.load(w2l.default / (type .. '.ini')))
        end
        return datas
    end
end

local function load_obj(w2l, archive, wts)
    local objs = {}
    local force_slk
    for type, name in pairs(w2l.info.template.obj) do
        local buf = archive:get(name)
        local force
        if buf then
            message('正在转换', name)
            objs[type], force = w2l:frontend_obj(type, wts, buf)
            if force then
                force_slk = true
            end
        end
    end
    return objs, force_slk
end

return function(w2l, archive, slk)
    --读取字符串
    slk.wts = w2l:frontend_wts(archive)
    local objs, force_slk = load_obj(w2l, archive, slk.wts)
    local datas = load_slk(w2l, archive, force_slk)
    for type, data in pairs(datas) do
        if objs then
            merge_obj(data, objs[type])
        end
        slk[type] = data
    end
end
