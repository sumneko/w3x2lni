local progress = require 'progress'

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
    for ttype, filename in pairs(w2l.info['template']['lni']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = slk[ttype]
        
        local content = w2l:backend_lni(ttype, data)
        if content then
            archive:set(filename, content)
        end
        progress(1)
    end
end

local function to_obj(w2l, archive, slk)
    --转换物编
    local count = 0
    for type, meta in pairs(w2l.info['metadata']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = slk[type]
        local content = w2l:backend_obj(type, data)
        if content then
            archive:set(w2l.info['template']['obj'][type], content)
        end
        progress(1)
    end
end

local function remove_unuse(w2l, slk)
    local unuse_list = {}
    local user_count = 0
    local count = 0
    local unuse_count = 0
    local origin_list = {}
    for type in pairs(w2l.info['template']['slk']) do
        local data = slk[type]
        for name, obj in pairs(data) do
            count = count + 1
            if obj._true_origin then
                user_count = user_count + 1
                if not obj._mark then
                    unuse_list[#unuse_list+1] = obj
                end
            else
                if not obj._mark then
                    unuse_count = unuse_count + 1
                else
                    origin_list[#origin_list+1] = obj
                end
            end
        end
    end

    if unuse_count > 0 then
        message('-report', ('简化掉的对象数: %d/%d'):format(unuse_count, count))
    end
    if #unuse_list > 0 then
        message('-report', ('简化掉的自定义对象数: %d/%d'):format(#unuse_list, user_count))
        for i = 1, math.min(10, #unuse_list) do
            message('-report', unuse_list[i]._id, unuse_list[i]._type, unuse_list[i].name or unuse_list[i].bufftip)
        end
    end
    if #origin_list > 0 then
        message('-report', ('保留的默认对象数: %d'):format(#origin_list))
        for i = 1, math.min(10, #origin_list) do
            message('-report', origin_list[i]._id, origin_list[i]._type, origin_list[i].name or origin_list[i].bufftip)
        end
    end
end

local function to_slk(w2l, archive, slk)
    --转换物编
    local count = 0
    local has_set = {}
    for type in pairs(w2l.info['template']['slk']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = slk[type]
        if type ~= 'doodad' then
            for _, slk in ipairs(w2l.info['template']['slk'][type]) do
                local content = w2l:backend_slk(type, slk, data)
                archive:set(slk, content)
            end
            if output[type] then
                archive:set(output[type], w2l:backend_txt(type, data))
                has_set[output[type]] = true
            end
            if w2l.info['template']['txt'][type] then
                for i, txt in ipairs(w2l.info['template']['txt'][type]) do
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

        local content = w2l:backend_obj(type, data)
        if content then
            archive:set(w2l.info['template']['obj'][type], content)
        end
        
        progress(1)
    end

    local content = w2l:backend_extra_txt(slk['txt'])
    if content then
        archive:set(output['txt'], content)
    end
end

return function (w2l, archive, slk)
    for type, filename in pairs(w2l.info.template.obj) do
        archive:set(filename, false)
    end
    for type, filelist in pairs(w2l.info.template.slk) do
        for _, filename in ipairs(filelist) do
            archive:set(filename, false)
        end
    end
    for type, filelist in pairs(w2l.info.template.txt) do
        for _, filename in ipairs(filelist) do
            archive:set(filename, false)
        end
    end
    for type, filelist in pairs(w2l.info.template.lni) do
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

    w2l:backend_processing(slk)

    if w2l.config.remove_unuse_object then
        w2l:backend_mark(archive, slk)
    end
    if w2l.config.target_format == 'slk' then
        w2l:backend_computed(slk)
    end
    if w2l.config.remove_unuse_object then
        remove_unuse(w2l, slk)
    end
    
    if w2l.config.target_format == 'lni' then
        to_lni(w2l, archive, slk, on_lni)
    elseif w2l.config.target_format == 'obj' then
        to_obj(w2l, archive, slk, on_lni)
    elseif w2l.config.target_format == 'slk' then
        to_slk(w2l, archive, slk, on_lni)
    end

    archive:set('war3mapmisc.txt', w2l:backend_misc(slk.misc, slk.txt, slk.wts))

    local buf = archive:get 'war3mapskin.txt'
    if buf then
        local skin = w2l:parse_ini()
        archive:set('war3mapskin.txt', w2l:backend_skin(skin, slk.wts))
    end

    w2l:backend_convertjass(archive, slk.wts)

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
	--local content = slk.wts:refresh()
	archive:set('war3map.wts', false)
end
