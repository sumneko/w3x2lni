local key_type = require 'key_type'

local table_insert = table.insert
local table_sort   = table.sort
local table_concat = table.concat
local math_type    = math.type
local string_char  = string.char
local type = type
local pairs = pairs
local setmetatable = setmetatable

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
	for i = 1, #names do
		self:add_obj(chunk[names[i]])
	end
end

function mt:add_obj(obj)
	local names = {}
	local datas = {}
	local sames = {}
    self:find_origin_id(obj)
    if obj['_slk'] then
        self:add_slk_data(obj)
    end
	for name, data in pairs(obj) do
		if name:sub(1, 1) ~= '_' then
			data['_c4id'] = name
			local name = self:format_name(name)
			table_insert(names, name)
			datas[name] = data
		end
	end
	table_sort(names)
	local need_new = false
	local max_level = self:find_max_level(datas)
	for i = 1, #names do
		self:count_max_level(obj['_user_id'], names[i], datas[names[i]], max_level)
		sames[i] = self:add_template_data(obj['_user_id'], obj['_origin_id'], names[i], datas[names[i]])
		if not sames[i] then
			need_new = true
		end
	end
	if not need_new then
		return
	end
	self:add ''
	self:add('[%s]', obj['_user_id'])
	self:add('%s = %q', '_id', obj['_origin_id'])
	for i = 1, #names do
		if not sames[i] then
			self:add_data(names[i], datas[names[i]], obj)
		end
	end
end

function mt:add_data(name, data, obj)
	if name:match '[^%w%_]' then
		name = ('%q'):format(name)
	end
	self:add('-- %s', self:get_comment(data.name))
	local values = {}
	if data._max_level <= 1 then
		self:add('%s = %s', name, self:format_value(data[1]))
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
			self:add('%s = {\r\n%s,\r\n}', name, table_concat(values, ',\r\n'))
		else
			local suc, info = pcall(table_concat, values, ', ')
			if not suc then
				print(obj['_user_id'])
				for k, v in pairs(values) do
					print(k, v)
				end
				error(info)
			end
			self:add('%s = {%s}', name, table_concat(values, ', '))
		end
	end
end

function mt:find_origin_id(obj)
    local temp = self.template
    if not temp then
        return
    end
    if not obj['_origin_id'] or temp[obj['_user_id']] then
        obj['_origin_id'] = obj['_user_id']
    end
    local id = obj['_origin_id']
    if not temp[id] then
        if not self.temp_reverse then
            self.temp_reverse = {}
            for uid, data in pairs(temp) do
                local oid = data['_id']
                if not temp[oid] and (not self.temp_reverse[oid] or uid < self.temp_reverse[oid]) then
                    self.temp_reverse[oid] = uid
                end
                if not self.temp_first or uid < self.temp_first then
                    self.temp_first = uid
                end
            end
        end
        obj['_origin_id'] = self.temp_reverse[id] or self.temp_first
    end
end

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:add_slk_data(obj)
    local id = obj['_origin_id']
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
                if not obj[name][i] then
                    obj[name]['_slk'][i] = true
                    obj[name][i] = self:to_type(name)
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
        value = value or ''
        if value:match '^%s*[%-%_]%s*$' then
            value = ''
        end
    end
    return value
end

function mt:add_template_data(uid, id, name, data)
	local template = self.template and (self.template[uid] or self.template[id])
	local has_temp = true
	if not template then
		template = {}
		has_temp = false
	end
	local all_same = true
    local max_meta
	local meta = self.meta[data['_c4id']]
	if meta['repeat'] and meta['repeat'] > 0 then
		max_meta = 4
	else
		max_meta = 1
	end
	local template = template[name]
	if type(template) ~= 'table' then
		template = {template}
	end
	for i = data._max_level, 1, -1 do
		local temp_data
		if i > max_meta then
			temp_data = template[max_meta]
		else
			temp_data = template[i]
		end
		if not temp_data then
			temp_data = self:to_type(data['_c4id'])
		end
		if data[i] == nil then
			data[i] = temp_data
		else
			if data[i] ~= temp_data then
				all_same = false
			end
		end
		if all_same and data['_slk'] and data['_slk'][i] and (has_temp or i > 1) then
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
	for k in pairs(data) do
		if type(k) == 'number' and k > data._max_level then
			data._max_level = k
		end
	end
end

return function (self, data, meta, editstring, template, key, max_level_key)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self
	tbl.meta = meta
	tbl.template = template
	tbl.key = key
	tbl.has_level = meta._has_level
	tbl.editstring = editstring or {}
	tbl.max_level_key = max_level_key

	tbl:add_head(data)
	tbl:add_chunk(data)

	return table_concat(tbl.lines, '\r\n')
end
