local progress = require 'progress'

local os_clock = os.clock

local output = {
    unit    = 'units\\campaignunitstrings.txt',
    ability = 'units\\campaignabilitystrings.txt',
    buff    = 'units\\commonabilitystrings.txt',
    upgrade = 'units\\campaignupgradestrings.txt',
    item    = 'units\\itemstrings.txt',
    txt     = 'units\\itemabilitystrings.txt',
}

local function to_lni(w2l, archive, slk)
    --转换物编
    local count = 0
    for ttype, filename in pairs(w2l.info.lni) do
        count = count + 1
        local data = slk[ttype]
        progress:start(count / 7)
        local content = w2l:backend_lni(ttype, data)
        progress:finish()
        if content then
            archive:set(filename, content)
        end
    end
end

local function to_obj(w2l, archive, slk)
    --转换物编
    local count = 0
    for type, filename in pairs(w2l.info.obj) do
        count = count + 1
        local data = slk[type]
        progress:start(count / 7)
        local content = w2l:backend_obj(type, data)
        progress:finish()
        if content then
            archive:set(filename, content)
        end
    end
end

local displaytype = {
    unit = '单位',
    ability = '技能',
    item = '物品',
    buff = '魔法效果',
    upgrade = '科技',
}

local function slk_object_name(o)
    if o._type == 'buff' then
        return o.bufftip or o.editorname or ''
    elseif o._type == 'upgrade' then
        return o.name[1] or ''
    else
        return o.name or ''
    end
end

local function slk_all(slk, id)
    id = id:lower()
    return slk.ability[id]
           or slk.unit[id]
           or slk.buff[id]
           or slk.item[id]
           or slk.destructable[id]
           or slk.doodad[id]
           or slk.upgrade[id]
end

local function report_object(slk, type, o)
    message('-report', o._id, displaytype[type], slk_object_name(o))
    if o._mark then
        local p = slk_all(slk, o._mark[1])
        if not p then
            message('-tip', o._mark[2]:format('<unknown>', o._mark[1]))
            return
        end
        message('-tip', o._mark[2]:format(slk_object_name(p), p._id))
    end
end

local function report_list(slk, list, type, n)
    list = list[type]
    for i = 1, math.min(n, #list) do
        report_object(slk, type, list[i])
    end
end

local function remove_unuse(w2l, slk)
    local unuse_list = {
        ability = {},
        unit = {},
        item = {},
        buff = {},
        upgrade = {},
        doodad = {},
        destructable = {},
    }
    local origin_list = {
        ability = {},
        unit = {},
        item = {},
        buff = {},
        upgrade = {},
        doodad = {},
        destructable = {},
    }
    local mustuse = {
        ability = {},
        unit = {},
        item = {},
        buff = {},
        upgrade = {},
        doodad = {},
        destructable = {},
    }
    for type, list in pairs(slk.mustuse) do
        for _, id in ipairs(list) do
            mustuse[type][id] = true
        end
    end
    local max = 0
    for type in pairs(w2l.info.slk) do
        for _ in pairs(slk[type]) do
            max = max + 1
        end
    end
    
    local user_count = 0
    local count = 0
    local unuse_count = 0
    local unuse_user_count = 0
    local origin_count = 0
    local clock = os_clock()
    for type in pairs(w2l.info.slk) do
        local default = w2l:parse_lni(io.load(w2l.default / (type .. '.ini')), type)
        local data = slk[type]
        for name, obj in pairs(data) do
            count = count + 1
            if obj._true_origin or not default[name] then
                user_count = user_count + 1
                if not obj._mark then
                    unuse_user_count = unuse_user_count + 1
                    unuse_list[type][#unuse_list[type]+1] = obj
                end
            else
                if not obj._mark then
                    unuse_count = unuse_count + 1
                else
                    origin_count = origin_count + 1
                    if not mustuse[type][name] then
                        origin_list[type][#origin_list[type]+1] = obj
                    end
                end
            end
            if os_clock() - clock > 0.1 then
                clock = os_clock()
                progress(count / max)
            end
        end
    end

    if unuse_count > 0 then
        message('-report', ('简化掉的对象数: %d/%d'):format(unuse_count, count))
    end
    if unuse_user_count > 0 then
        message('-report', ('简化掉的自定义对象数: %d/%d'):format(unuse_user_count, user_count))
        report_list(slk, unuse_list, 'unit', 5)
        report_list(slk, unuse_list, 'ability', 5)
        report_list(slk, unuse_list, 'item', 5)
        report_list(slk, unuse_list, 'buff', 1)
        report_list(slk, unuse_list, 'upgrade', 1)
    end
    if origin_count > 0 then
        message('-report', ('保留的默认对象数: %d/%d'):format(origin_count, count - user_count))
        report_list(slk, origin_list, 'unit', 5)
        report_list(slk, origin_list, 'ability', 5)
        report_list(slk, origin_list, 'item', 5)
        report_list(slk, origin_list, 'buff', 1)
        report_list(slk, origin_list, 'upgrade', 1)
    end
end

local function to_slk(w2l, archive, slk)
    --转换物编
    local count = 0
    local has_set = {}
    for type in pairs(w2l.info.slk) do
        count = count + 1
        progress:start(count / 7)
        local data = slk[type]
        if type ~= 'doodad' then
            progress:start(0.4)
            for _, slk in ipairs(w2l.info.slk[type]) do
                local content = w2l:backend_slk(type, slk, data)
                archive:set(slk, content)
            end
            progress:finish()

            if output[type] then
                progress:start(0.8)
                archive:set(output[type], w2l:backend_txt(type, data))
                progress:finish()
                has_set[output[type]] = true
            end
            if w2l.info.txt[type] then
                for i, txt in ipairs(w2l.info.txt[type]) do
                    if not has_set[txt] then
                        archive:set(txt, '')
                        has_set[txt] = true
                    end
                end
            end
        end
        
        for name, obj in pairs(data) do
            local empty = true
            for k in pairs(obj) do
                if k:sub(1, 1) ~= '_' then
                    empty = false
                    break
                end
            end
            if empty then
                data[name] = nil
            end
        end
        progress(0.9)
        
        progress:start(1)
        local content = w2l:backend_obj(type, data)
        progress:finish()
        if content then
            archive:set(w2l.info.obj[type], content)
        end
        progress:finish()
    end

    local content = w2l:backend_extra_txt(slk['txt'])
    if content then
        archive:set(output['txt'], content)
    end
end

return function (w2l, archive, slk)
    for type, filename in pairs(w2l.info.obj) do
        archive:set(filename, false)
    end
    for type, filelist in pairs(w2l.info.slk) do
        for _, filename in ipairs(filelist) do
            archive:set(filename, false)
        end
    end
    for type, filelist in pairs(w2l.info.txt) do
        for _, filename in ipairs(filelist) do
            archive:set(filename, false)
        end
    end
    for type, filelist in pairs(w2l.info.lni) do
        for _, filename in ipairs(filelist) do
            archive:set(filename, false)
        end
    end

    slk.w3i = w2l:read_w3i(archive:get 'war3map.w3i')
    if slk.w3i then
        local lni = w2l:w3i2lni(slk.w3i, slk.wts)
        if w2l.config.target_format == 'lni' then
            archive:set('mapinfo.ini', lni)
        end
        archive:set('war3map.w3i', w2l:lni2w3i(w2l:parse_lni(lni)))
        if slk.w3i.game_data_set == 1 then
            message('-report', '只支持"默认(1.07)",地图为"自定义"')
        end
        if slk.w3i.game_data_set == 2 then
            message('-report', '只支持"默认(1.07)",地图为"对战(最新版本)"')
        end
    end
    progress(0.1)

    progress:start(0.2)
    message('清理数据...')
    w2l:backend_processing(slk)
    progress:finish()

    if w2l.config.remove_unuse_object then
        message('标记简化对象...')
        w2l:backend_mark(archive, slk)
        progress(0.3)
    end
    if w2l.config.target_format == 'slk' then
        message('计算描述中的公式...')
        w2l:backend_computed(slk)
        progress(0.4)
    end
    if w2l.config.remove_unuse_object then
        message('移除简化对象...')
        progress:start(0.7)
        remove_unuse(w2l, slk)
        progress:finish()
    end
    
    progress:start(0.9)
    message('转换物编文件...')
    if w2l.config.target_format == 'lni' then
        to_lni(w2l, archive, slk, on_lni)
    elseif w2l.config.target_format == 'obj' then
        to_obj(w2l, archive, slk, on_lni)
    elseif w2l.config.target_format == 'slk' then
        to_slk(w2l, archive, slk, on_lni)
    end
    progress:finish()

    message('转换脚本...')
    w2l:backend_convertjass(archive, slk.wts)
    progress(0.94)

    message('转换其他文件...')
    archive:set('war3mapmisc.txt', w2l:backend_misc(slk.misc, slk.txt, slk.wts))
    progress(0.96)

    local buf = archive:get 'war3mapskin.txt'
    if buf then
        local skin = w2l:parse_ini(buf)
        archive:set('war3mapskin.txt', w2l:backend_skin(skin, slk.wts))
    end
    progress(0.98)

    if w2l.config.remove_we_only then
        archive:set('war3map.wtg', false)
        archive:set('war3map.wct', false)
        archive:set('war3map.imp', false)
        archive:set('war3map.w3s', false)
        archive:set('war3map.w3r', false)
        archive:set('war3map.w3c', false)
        archive:set('war3mapunits.doo', false)
    end

	--刷新字符串
    message('重新生成字符串...')
	local content = slk.wts:refresh()
    if #content > 0 then
	    archive:set('war3map.wts', content)
    else
	    archive:set('war3map.wts', false)
    end

    for _, name in ipairs(w2l.info.pack.packignore) do
        archive:set(name, false)
    end
    progress(1)
end
