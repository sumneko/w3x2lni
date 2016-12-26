local progress = require 'progress'

local type = type
local pairs = pairs
local os_clock = os.clock

local w2l
local revert_list
local unit_list
local metadata
local keydata

local function remove_nil_value(key, id, obj, default, max_level)
    local data = obj[key]
    local meta = metadata[id]
    local tp = w2l:get_id_type(meta.type)
    local dest = default[key]
    if not meta['repeat'] or meta['repeat'] == 0 then
        if not data and dest then
            if tp == 0 then
                obj[key] = 0
            elseif tp == 1 or tp == 2 then
                obj[key] = 0.0
            else
                obj[key] = ''
            end
        end
        return
    end
    if not data then
        data = {}
        obj[key] = data
    end
    local default_value
    local default_level = 0
    if dest then
        default_level = #dest
    end
    if default_level > 0 then
        default_value = dest[default_level]
        if max_level < default_level then
            max_level = default_level
        end
    end
    for i = 1, max_level do
        if not data[i] then
            if tp == 0 then
                if i <= default_level then
                    error('value level error')
                end
                data[i] = default_value or 0
            elseif tp == 1 or tp == 2 then
                if i <= default_level then
                    error('value level error')
                end
                data[i] = default_value or 0.0
            else
                if default_value then
                    data[i] = ''
                end
            end
        end
    end
end

local function fill_obj(name, obj, type, default, config)
    local parent = obj._lower_parent
    local code = obj._code
    local max_level = obj._max_level
    local default = default[parent]
    for key, id in pairs(keydata.common) do
        remove_nil_value(key, id, obj, default, max_level)
    end
    if keydata[code] then
        for key, id in pairs(keydata[code]) do
            remove_nil_value(key, id, obj, default, max_level)
        end
    end
end

local function get_revert_list(default, code)
    if not revert_list then
        revert_list = {}
        for lname, obj in pairs(default) do
            local code = obj['_code']
            local list = revert_list[code]
            if not list then
                revert_list[code] = lname
            else
                if type(list) ~= 'table' then
                    revert_list[code] = {[list] = true}
                end
                revert_list[code][lname] = true
            end
        end
    end
    return revert_list[code]
end

local function get_unit_list(default, name)
    if not unit_list then
        unit_list = {}
        for lname, obj in pairs(default) do
            local _name = obj['_name']
            if _name then
                local list = unit_list[_name]
                if not list then
                    unit_list[_name] = lname
                else
                    if type(list) ~= 'table' then
                        unit_list[_name] = {[list] = true}
                    end
                    unit_list[_name][lname] = true
                end
            end
        end
    end
    return unit_list[name]
end

local function find_para(name, obj, default, type)
    if obj['_true_origin'] then
        local parent = obj['_lower_parent']
        return parent
    end
    if default[name] then
        return name
    end
    local code = obj['_code']
    if code then
        local list = get_revert_list(default, code)
        if list then
            return list
        end
    end
    if type == 'unit' then
        local list = get_unit_list(default, obj['_name'])
        if list then
            return list
        end
    end
    return default
end

local function try_obj(obj, may_obj)
    local diff_count = 0
    for name, may_data in pairs(may_obj) do
        if name:sub(1, 1) ~= '_' then
            local data = obj[name]
            if type(may_data) == 'table' then
                if type(data) == 'table' then
                    for i = 1, #may_data do
                        if data[i] ~= may_data[i] then
                            diff_count = diff_count + 1
                            break
                        end
                    end
                else
                    diff_count = diff_count + 1
                end
            else
                if data ~= may_data then
                    diff_count = diff_count + 1
                end
            end
        end
    end
    return diff_count
end

local function parse_obj(name, obj, default, config, ttype)
    local parent
    local count
    local find_times = config.find_id_times
    local maybe = find_para(name, obj, default, ttype)
    if type(maybe) == 'table' then
        for try_name in pairs(maybe) do
            local new_count = try_obj(obj, default[try_name])
            if not count or count > new_count or (count == new_count and parent > try_name) then
                count = new_count
                parent = try_name
            end
            find_times = find_times - 1
            if find_times == 0 then
                break
            end
        end
    else
        parent = maybe
    end

    obj._lower_parent = parent
    obj._parent = default[parent]._id
    obj._code = default[parent]._code
end

local function processing(w2l, type, chunk)
    local default = w2l:parse_lni(io.load(w2l.default / (type .. '.ini')))
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    local config = w2l.config
    local names = {}
    for name in pairs(chunk) do
        names[#names+1] = name
    end
    table.sort(names, function(a, b)
        return chunk[a]['_id'] < chunk[b]['_id']
    end)

    revert_list = nil
    unit_list = nil
    progress(0.1)
    
    progress:start(0.9)
    local clock = os_clock()
    for i, name in ipairs(names) do
        parse_obj(name, chunk[name], default, config, type)
        if os_clock() - clock >= 0.1 then
            clock = os_clock()
            message(('搜索最优模板[%s] (%d/%d)'):format(chunk[name]._id, i, #names))
            progress(i / #names)
        end
    end
    progress:finish()
    progress:start(1)
    for i, name in ipairs(names) do
        fill_obj(name, chunk[name], type, default, config)
        if os_clock() - clock >= 0.1 then
            clock = os_clock()
            message(('补全数据[%s] (%d/%d)'):format(chunk[name]._id, i, #names))
            progress(i / #names)
        end
    end
    progress:finish()
end

return function (w2l_, slk)
    w2l = w2l_
    local count = 0
    for type, name in pairs(w2l.info.obj) do
        count = count + 1
        progress:start(count / 7)
        processing(w2l, type, slk[type])
        progress:finish()
    end
end
