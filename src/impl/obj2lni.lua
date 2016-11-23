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
	for i = 1, #names do
		self:count_max_level(datas[names[i]])
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
	if data._max_level <= 1 then
		self:add('%s = %s', name, self:format_value(data[1]))
	else
		local is_string
		for i = 1, data._max_level do
			if type(data[i]) == 'string' then
				is_string = true
			end
			if data._max_level >= 10 then
				data[i] = ('%d = %s'):format(i, self:format_value(data[i]))
			else
				data[i] = self:format_value(data[i])
			end
		end
		if is_string or data._max_level >= 10 then
			self:add('%s = {\r\n%s,\r\n}', name, table_concat(data, ',\r\n'))
		else
			local suc, info = pcall(table_concat, data, ', ')
			if not suc then
				print(obj['_user_id'])
				for k, v in pairs(data) do
					print(k, v)
				end
				error(info)
			end
			self:add('%s = {%s}', name, table_concat(data, ', '))
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
	local template = self.template and (self.template[id] or self.template[uid])
	if not template then
		template = {}
	end
	local all_same = not not self.template
	for i = 1, data._max_level do
		local temp_data
		if type(template[name]) == 'table' then
			if template[name][i] then
				temp_data = template[name][i]
			else
				temp_data = template[name][#template[name]]
			end
		else
			temp_data = template[name]
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
	end
	return all_same
end

function mt:count_max_level(data)
	data._max_level = 1
	for k in pairs(data) do
		if type(k) == 'number' and k > data._max_level then
			data._max_level = k
		end
	end
end

return function (self, data, meta, editstring, template)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self
	tbl.meta = meta
	tbl.template = template
	tbl.has_level = meta._has_level
	tbl.editstring = editstring or {}

	tbl:add_head(data)
	tbl:add_chunk(data)

	return table_concat(tbl.lines, '\r\n')
end
