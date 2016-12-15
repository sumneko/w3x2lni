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

local function copy(a, b)
    if b then
        local c = {}
        for k, v in pairs(a) do
            c[k] = b[k] or v
        end
        return c
    end
    local c = {}
    for k, v in pairs(a) do
        c[k] = v
    end
    return c
end

local function table_copy(a, b)
    local c = {}
    for k, v in pairs(a) do
        if type(v) == 'table' then
            c[k] = copy(v, b[k])
        else
            c[k] = b[k] or v
        end
    end
    return c
end

local function merge_obj(data, objs)
    for name, obj in pairs(objs) do
        if data[name] then
            table_merge(data[name], obj)
        else
            data[name] = table_copy(data[obj._origin_id], obj)
        end
    end
end

local function load(w2l, wts, archive, type, filename, target_progress)
    local obj, data, force_slk

    progress:target(target_progress-1)
    local buf = archive:get(filename)
    if buf then
        message('正在转换', filename)
        obj, force_slk = w2l:frontend_obj(type, wts, buf)
    end

    progress:target(target_progress)
    if force_slk or w2l.config.read_slk then
        data = w2l:frontend_slk(type, function(name)
            message('正在转换', name)
            local buf = archive:get(name)
            if buf then
                return buf
            end
            return io.load(w2l.mpq / name)
        end)
    else
        data = w2l:parse_lni(io.load(w2l.default / (type .. '.ini')))
    end

    if obj then
        merge_obj(data, obj)
    end
    return data
end

return function(w2l, archive, slk)
	--读取字符串
	slk.wts = w2l:frontend_wts(archive)

    local count = 0
    for type, name in pairs(w2l.info.template.obj) do
        count = count + 1
        local target_progress = 3 + count * 2
        slk[type] = load(w2l, slk.wts, archive, type, name, target_progress)
    end

    -- TODO: 删掉输入的二进制物编和slk,因为他们已经转化成lua数据了
    -- 
    --for _, name in pairs(w2l.info.template.obj) do
    --    files[name] = nil
    --end
    --if w2l.config['unpack']['read_slk'] then
    --    for _, names in pairs(w2l.info.template.slk) do
    --        for _, name in ipairs(names) do
    --            files[name] = nil
    --        end
    --    end
    --    for _, names in pairs(w2l.info.template.txt) do
    --        for _, name in ipairs(names) do
    --            files[name] = nil
    --        end
    --    end
    --end
end
