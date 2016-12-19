local progress = require 'progress'

local table_sort   = table.sort
local string_char  = string.char
local revert_list
local unit_list
local metadata
local keydata

local mt = {}
mt.__index = mt

local function copy(tbl)
    local ntbl = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            v = copy(v)
        end
        ntbl[k] = v
    end
    return ntbl
end

local function add_table(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if tbl1[k] then
            if type(tbl1[k]) == 'table' or type(v) == 'table' then
                if type(tbl1[k]) ~= 'table' then
                    tbl1[k] = {tbl1[k]}
                end
                if type(v) ~= 'table' then
                    v = {v}
                end
                add_table(tbl1[k], v)
            end
        else
            tbl1[k] = v
        end
    end
end

local function get_revert_list(default, para)
    if not revert_list then
        revert_list = {}
        for lname, obj in pairs(default) do
            local para = obj['_lower_para']
            local list = revert_list[para]
            if not list then
                revert_list[para] = lname
            else
                if type(list) ~= 'table' then
                    revert_list[para] = {[list] = true}
                end
                revert_list[para][lname] = true
            end
        end
    end
    return revert_list[para]
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

local function remove_exceeds_level(data, max_level)
    if type(data) ~= 'table' then
        return
    end
    for level in pairs(data) do
        if level > max_level then
            data[level] = nil
        end
    end
end

local function can_remove(is_slk, level, key)
    if not is_slk then
        return true
    end
    if level <= 4 then
        return false
    end
    if keydata.profile and keydata.profile[key] then
        return false
    end
    return true
end

local function remove_same(key, data, default, obj, is_slk)
    local dest = default[key]
    if type(dest) == 'table' then
        for i = 1, #data do
            if data[i] == dest[i] and can_remove(is_slk, i, key) then
                data[i] = nil
            end
        end
        if not next(data) then
            obj[key] = nil
        end
    else
        if not is_slk and data == dest then
            obj[key] = nil
        end
    end
end

local function remove_nil_value(key, data, default)
    if type(data) ~= 'table' then
        return
    end
    local len = 0
    for n in pairs(data) do
        if n > len then
            len = n
        end
    end
    local dest = default[key]
    local tp = type(data[len])
    for i = 1, len do
        if not data[i] then
            if tp == 'number' then
                data[i] = dest[#dest]
            end
        end
    end
end

local function clean_obj(name, obj, type, default, config)
    local para = obj._lower_para
    local max_level = obj._max_level
    local default = default[para]
    local is_remove_exceeds_level = config.remove_exceeds_level
    local is_remove_same = config.remove_same
    local is_remove_nil_value  = config.remove_nil_value
    local is_slk = config.target_format == 'slk' and type ~= 'doodad'
    for key, data in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            if is_remove_exceeds_level and max_level then
                remove_exceeds_level(data, max_level)
            end
            if is_remove_same then
                remove_same(key, data, default, obj, is_slk)
            end
            if is_remove_nil_value then
                remove_nil_value(key, data, default)
            end
        end
    end
end

local function find_para(name, obj, default, type)
    if obj['_true_origin'] then
        local para = obj['_lower_para']
        return para
    end
    if default[name] then
        return name
    end
    local para = obj['_lower_para']
    if para then
        local list = get_revert_list(default, para)
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
    local para
    local count
    local find_times = config.find_id_times
    local maybe = find_para(name, obj, default, ttype)
    if type(maybe) ~= 'table' then
        obj._lower_para = maybe
        return
    end

    for try_name in pairs(maybe) do
        local new_count = try_obj(obj, default[try_name])
        if not count or count > new_count or (count == new_count and para > try_name) then
            count = new_count
            para = try_name
        end
        find_times = find_times - 1
        if find_times == 0 then
            break
        end
    end

    obj._lower_para = para
end

local function processing(w2l, type, chunk, target_progress)
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
    
    local clock = os.clock()
    progress:target(target_progress - 1)
    for i, name in ipairs(names) do
        parse_obj(name, chunk[name], default, config, type)
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('搜索最优模板[%s] (%d/%d)'):format(chunk[name]._id, i, #names))
            progress(i / #names)
        end
    end
    progress:target(target_progress)
    for i, name in ipairs(names) do
        clean_obj(name, chunk[name], type, default, config)
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('清理数据[%s] (%d/%d)'):format(chunk[name]._id, i, #names))
            progress(i / #names)
        end
    end
end

return function (w2l, slk)
    local count = 0
    for type, name in pairs(w2l.info.template.obj) do
        count = count + 1
        local target_progress = 17 + 7 * count
        processing(w2l, type, slk[type], target_progress)
    end
end
