local key_type = require 'key_type'
local progress = require 'progress'

local table_sort   = table.sort
local string_char  = string.char

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

function mt:parse_chunk(chunk)
    for name, obj in pairs(chunk) do
        if name:sub(1, 1) ~= '_' then
            tbl:parse_obj(name, obj)
        end
    end
end

function mt:parse_obj(name, obj)
    local origin_id
    local count, sames, names, datas
    local user_id = obj['_user_id']
    local find_times = self.config['unpack']['find_id_times']
    local ids = self:find_origin_id(obj)

    for id in pairs(ids) do
        local new_obj = copy(obj)
        if is_slk then
            self:add_slk_data(new_obj, id)
        end
        local new_names, new_datas = self:preload_obj(new_obj, id)
        local new_count = self:try_obj(user_id, id, new_names, new_datas)
        if not count or count > new_count or (origin_id > id and count == new_count) then
            count = new_count
            names = new_names
            datas = new_datas
            origin_id = id
        end
        if not is_slk then
            break
        end
        find_times = find_times - 1
        if find_times == 0 then
            break
        end
    end
    
    datas['_user_id'] = user_id
    datas['_origin_id'] = origin_id
    return datas
end

function mt:preload_obj(obj, id)
    local names = {}
	local datas = {}
    for name, data in pairs(obj) do
		if name:sub(1, 1) ~= '_' then
			data['_c4id'] = name
			local name = self:format_name(name)
            names[#names+1] = name
            datas[name] = data
		end
	end
	local max_level = self:find_max_level(id, datas)
	for i = 1, #names do
		self:count_max_level(obj['_user_id'], names[i], datas[names[i]], max_level)
	end
    return names, datas
end

function mt:try_obj(user_id, origin_id, names, datas)
    local template = self.template and (self.template[user_id] or self.template[origin_id])
	local sames = {}
    local count = 0
	for i = 1, #names do
		local same = self:add_template_data(template, names[i], datas[names[i]])
		if not same then
            count = count + 1
			need_new = true
            datas[names[i]]._not_same = true
		end
	end
    if template then
        for name, data in pairs(template) do
            if not datas[name] and name:sub(1, 1) ~= '_' then
                count = count + 1
                if type(data) ~= 'table' then
                    data = {data}
                end
                datas[name] = copy(data)
                datas[name].name = self:key2id(origin_id, user_id, name)
                datas[name]._max_level = #datas[name]
                datas[name]._not_same = true
            end
        end
    end
	if need_new then
        return count
	end
    return 0, nil
end

function mt:find_origin_id(obj)
    local temp = self.template
    if not temp or obj['_true_origin'] then
        local id = obj['_origin_id']
        return {[id] = true}
    end
    local id = obj['_user_id']
    if temp[id] then
        return {[id] = true}
    end
    local oid = obj['_origin_id']
    if oid then
        local list = self:get_revert_list(temp, oid)
        if list then
            return list
        end
    end
    if self.file_name == 'war3map.w3u' then
        return self:get_unit_list(temp, obj['_name'])
    end
    return temp
end

function mt:get_revert_list(temp, id)
    if not self.revert_list then
        self.revert_list = {}
        for name, obj in pairs(temp) do
            local _id = obj['_id']
            if not self.revert_list[_id] then
                self.revert_list[_id] = {}
            end
            self.revert_list[_id][name] = true
        end
    end
    return self.revert_list[id]
end

function mt:get_unit_list(temp, name)
    if not self.unit_list then
        self.unit_list = {}
        for name, obj in pairs(temp) do
            local _name = obj['_name']
            if _name then
                if not self.unit_list[_name] then
                    self.unit_list[_name] = {}
                end
                self.unit_list[_name][name] = true
            end
        end
    end
    return self.unit_list[name] or temp
end

function mt:add_slk_data(obj, id)
    local temp = self.template
    local temp_skill
    if temp then
        temp_skill = temp[id]
        if not temp_skill then
            return
        end
    else
        temp_skill = obj
    end
    
    for lname, value in pairs(temp_skill) do
        if lname:sub(1, 1) ~= '_' then
            local name
            if temp then
                name = self:key2id(id, id, lname)
            else
                name = lname
            end
            if name then
                if not obj[name] then
                    obj[name] = {
                        ['name'] = name,
                    }
                end
                if not obj[name]['_slk'] then
                    obj[name]['_slk'] = {}
                end
                local max_level
                local meta = self.meta[name]
                if meta['repeat'] and meta['repeat'] > 0 then
                    max_level = 4
                else
                    max_level = 1
                end
                for i = 1, max_level do
                    if obj[name][i] == false then
                        obj[name][i] = obj[name][i-1]
                    end
                    if obj[name][i] == nil then
                        obj[name]['_slk'][i] = true
                        obj[name][i] = self:to_type(name)
                        if not obj[name][i] and i == 1 then
                            obj[name][i] = ''
                        end
                    end
                end
            end
        end
    end
end

function mt:add_template_data(template, name, data)
	local has_temp = true
	if not template then
		template = {}
		has_temp = false
	end
	local all_same = true
	local template = template[name]
	if type(template) ~= 'table' then
		template = {template}
	end
	for i = data._max_level, 1, -1 do
		local temp_data = template[i] or template[#template]
		if not temp_data and has_temp then
			temp_data = self:to_type(data['_c4id'])
            if not temp_data and i == 1 then
                temp_data = ''
            end
		end
		if data[i] == nil then
			data[i] = temp_data
		else
			if data[i] ~= temp_data then
				all_same = false
			end
		end
        if all_same and (self.config['unpack']['remove_same'] or (data['_slk'] and data['_slk'][i])) and i > 1 then
            data[i] = nil
            data._max_level = i - 1
        elseif has_temp == false and i == data._max_level and data[i] == data[i-1] then
            data[i] = nil
            data._max_level = i - 1
        end
	end
	return all_same and has_temp
end

function mt:find_max_level(id, datas)
	local key = self.max_level_key
	if not key then
		return nil
	end
    if not self.template then
        return 4
    end
	local data = datas[key]
	if data then
        return data[1]
    else
		return self.template[id][key]
	end
end

function mt:count_max_level(skill, name, data, max_level)
	data._max_level = 1
	local meta = self.meta[data['_c4id']]
	if max_level and meta['repeat'] and meta['repeat'] > 0 then
		data._max_level = max_level
	end
	if self.template and self.config['unpack']['remove_over_level'] then
		return
	end
	for k in pairs(data) do
		if type(k) == 'number' and k > data._max_level then
			data._max_level = k
		end
	end
end

function mt:get_key_type(key)
    local meta = self.meta
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

function mt:to_type(id, value)
    local tp = self:get_key_type(id)
    if tp == 0 then
        value = math.floor(tonumber(value) or 0)
    elseif tp == 1 or tp == 2 then
        value = (tonumber(value) or 0.0) + 0.0
    elseif tp == 3 then
        if type(value) == 'string' then
            if value:match '^%s*[%-%_]%s*$' then
                value = nil
            end
        end
    end
    return value
end

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:format_name(name)
	local meta  = self.meta[name]
	local name  = meta['field']
	local num   = meta['data']
	if num and num ~= 0 then
		name = name .. string_char(('A'):byte() + num - 1)
	end
	if meta['_has_index'] then
		name = name .. ':' .. (meta['index'] + 1)
	end
	return name
end

return function (w2l, file_name, data, loader)
    local tbl = setmetatable({}, mt)
    tbl.meta = w2l:read_metadata(w2l.dir['mpq'] / w2l.info['metadata'][file_name], loader)
    tbl.key = w2l:parse_lni(io.load(w2l.dir['key'] / (file_name .. '.ini')), file_name)

    tbl:parse_chunk(data)
end
