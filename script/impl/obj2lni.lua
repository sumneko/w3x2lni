local key_type = require 'key_type'
local progress = require 'progress'

local table_insert = table.insert
local table_sort   = table.sort
local table_concat = table.concat
local math_type    = math.type
local string_char  = string.char
local type = type
local pairs = pairs
local setmetatable = setmetatable

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

local mt = {}
mt.__index = mt

function mt:format_value(value)
	local tp = type(value)
	if tp == 'number' then
		if math_type(value) == 'integer' then
			return ('%d'):format(value)
		else
			return ('%.4f'):format(value)
		end
	elseif tp == 'nil' then
		return 'nil'
	else
		value = self:get_editstring(value)
		if value:match '[\n\r]' then
			return ('[=[\r\n%s]=]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
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

function mt:get_editstring(name)
	while self.editstring[name] do
		name = self.editstring[name]
	end
	return name
end

function mt:get_comment(name)
	local comment = self.meta[name].displayName
	return self:get_editstring(comment)
end

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
end

function mt:add_head(data)
	if data['_版本'] then
		self:add '[头]'
		self:add('版本 = %s', data['_版本'])
	end
end

function mt:add_chunk(chunk)
	local names = {}
	for name, obj in pairs(chunk) do
		if name:sub(1, 1) ~= '_' then
			table_insert(names, name)
		end
	end
	table_sort(names, function(name1, name2)
		local is_origin1 = name1 == chunk[name1]['_origin_id']
		local is_origin2 = name2 == chunk[name2]['_origin_id']
		if is_origin1 and not is_origin2 then
			return true
		end
		if not is_origin1 and is_origin2 then
			return false
		end
		return name1 < name2
	end)
    local clock = os.clock()
	for i = 1, #names do
		self:add_obj(chunk[names[i]])
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('正在转换%s: [%s] (%d/%d)'):format(self.file_name, names[i], i, #names))
            progress(i / #names)
        end
	end
end

function mt:add_obj(obj)
    local is_slk = obj['_slk']
    if is_slk and not obj['_enable'] then
        return
    end
    local orign_id
    local count, sames, names, datas
    local user_id = obj['_user_id']
    local find_times = self.config['unpack']['find_id_times']
    local ids = self:find_origin_id(obj)
    for id in pairs(ids) do
        local new_obj = copy(obj)
        if is_slk then
            self:add_slk_data(new_obj, id)
        end
        local new_names, new_datas = self:preload_obj(new_obj)
        local new_count, new_sames = self:try_obj(user_id, id, new_names, new_datas)
        if not count or count > new_count or (origin_id > id and count == new_count) then
            count = new_count
            sames = new_sames
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
    local lines = {}
	for i = 1, #names do
		if sames and not sames[i] then
			self:add_data(names[i], datas[names[i]], user_id, lines)
		end
	end
    if not lines or #lines == 0 then
        return
    end
	self:add ''
	self:add('[%s]', obj['_user_id'])
	self:add('%s = %q', '_id', origin_id)
    if obj['_name'] then
        self:add('%s = %q', '_name', obj['_name'])
    end
    for i = 1, #lines do
        self:add(table.unpack(lines[i]))
    end
end

function mt:preload_obj(obj)
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
	table_sort(names)
	local max_level = self:find_max_level(datas)
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
		sames[i] = self:add_template_data(template, names[i], datas[names[i]])
		if not sames[i] then
            count = count + 1
			need_new = true
		end
	end
    if template then
        for name in pairs(template) do
            if not datas[name] and name:sub(1, 1) ~= '_' then
                count = count + 1
            end
        end
    end
	if need_new then
        return count, sames
	end
    return 0, nil
end

function mt:add_data(name, data, user_id, lines)
    if #data == 0 then
        return
    end
	if name:match '[^%w%_]' then
		name = ('%q'):format(name)
	end
    lines[#lines+1] = {'-- %s', self:get_comment(data.name)}
	local values = {}
	if data._max_level <= 1 then
		lines[#lines+1] = {'%s = %s', name, self:format_value(data[1])}
	else
		local is_string
		for i = 1, data._max_level do
			if type(data[i]) == 'string' then
				is_string = true
			end
			if data._max_level >= 10 then
				values[i] = ('%d = %s'):format(i, self:format_value(data[i]))
			else
				values[i] = self:format_value(data[i])
			end
		end
		if is_string or data._max_level >= 10 then
			lines[#lines+1] = {'%s = {\r\n%s,\r\n}', name, table_concat(values, ',\r\n')}
		else
			local suc, info = pcall(table_concat, values, ', ')
			if not suc then
                local msg = {}
                msg[#msg+1] = info
				msg[#msg+1] = tostring(user_id)
				for k, v in pairs(values) do
					msg[#msg+1] = tostring(k) .. '\t' .. tostring(v)
				end
				error(table.concat(msg, '\r\n'))
			end
			lines[#lines+1] = {'%s = {%s}', name, table_concat(values, ', ')}
		end
	end
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

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
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

function mt:find_max_level(datas)
	local key = self.max_level_key
	if not key then
		return nil
	end
    if not self.template then
        return 4
    end
	local data = datas[key]
	if not data then
		return nil
	end
	return data[1]
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

return function (self, data, meta, editstring, template, key, max_level_key, file_name)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self
	tbl.meta = meta
	tbl.template = template
	tbl.key = key
	tbl.has_level = meta._has_level
	tbl.editstring = editstring or {}
	tbl.max_level_key = max_level_key
    tbl.file_name = file_name
	tbl.config = self.config

	tbl:add_head(data)
	tbl:add_chunk(data)

	return table_concat(tbl.lines, '\r\n')
end
