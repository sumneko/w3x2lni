local progress = require 'progress'

local function load_slk(w2l, archive, force_slk)
    if force_slk then
        message('-report|7其他', '物编信息不完整,强制读取slk文件')
    end
    if force_slk or w2l.config.read_slk then
        return w2l:frontend_slk(function(name)
            local buf = archive:get(name)
            if buf then
                archive:set(name, false)
                return buf
            end
            return io.load(w2l.mpq / name)
        end)
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

     local buf = archive:get('war3map.txt.ini')
    if buf then
        lnis['txt'] = w2l:parse_lni(buf, 'txt')
        archive:set('war3map.txt.ini', false)
    end
    return lnis
end

local function update_then_merge(w2l, slks, objs, lnis, slk)
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'txt'} do
        local data = slks[type]
        local obj = objs[type]
        if obj then
            w2l:frontend_updateobj(type, obj, data)
        else
            obj = {}
        end
        if lnis[type] then
            w2l:frontend_updatelni(type, lnis[type], data)
            for k, v in pairs(lnis[type]) do
                obj[k] = v
            end
        end
        w2l:frontend_merge(data, obj)
        slk[type] = data
    end
end

return function(w2l, archive, slk)
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
