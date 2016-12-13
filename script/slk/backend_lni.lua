local progress = require 'progress'

local table_insert = table.insert
local table_sort = table.sort
local math_type = math.type
local table_concat = table.concat
local string_char = string.char
local type = type

local mt = {}
mt.__index = mt

local function get_len(tbl)
	local n = 0
	for k in pairs(tbl) do
		if type(k) == 'number' and k > n then
			n = k
		end
	end
	return n
end

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
		value = self.w2l:editstring(value)
		if value:match '[\n\r]' then
			return ('[=[\r\n%s]=]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
end

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
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
	local upper_obj = {}
    local keys = {}
	local name = obj._user_id
	local code = obj._origin_id
    for key, data in pairs(obj) do
		if key:sub(1, 1) ~= '_' then
			local id = self:key2id(name, code, key)
			local key = self:get_key(id)
			if key then
				keys[#keys+1] = key
				upper_obj[key] = data
			end
		end
	end
    table_sort(keys)
    local lines = {}
	for _, key in ipairs(keys) do
		local id = self:key2id(name, code, key:lower())
		self:add_data(key, id, upper_obj[key], lines)
	end
    if not lines or #lines == 0 then
        return
    end

	self:add('[%s]', obj['_user_id'])
	self:add('%s = %q', '_id', obj['_origin_id'])
    if obj['_name'] then
        self:add('%s = %q', '_name', obj['_name'])
    end
    for i = 1, #lines do
        self:add(table.unpack(lines[i]))
    end
	self:add ''
end

function mt:add_data(key, id, data, lines)
	local len
	if type(data) == 'table' then
		len = get_len(data)
		if len == 0 then
			return
		end
	end
	if key:match '[^%w%_]' then
		key = ('%q'):format(key)
	end
    lines[#lines+1] = {'-- %s', self:get_comment(id)}
	if not len then
		lines[#lines+1] = {'%s = %s', key, self:format_value(data)}
		return
	end
	if len <= 1 then
		lines[#lines+1] = {'%s = %s', key, self:format_value(data[1])}
		return
	end

	local values = {}
	local is_string
	for i = 1, len do
		if type(data[i]) == 'string' then
			is_string = true
		end
		if len >= 10 then
			values[i] = ('%d = %s'):format(i, self:format_value(data[i]))
		else
			values[i] = self:format_value(data[i])
		end
	end

	if is_string or len >= 10 then
		lines[#lines+1] = {'%s = {\r\n%s,\r\n}', key, table_concat(values, ',\r\n')}
		return
	end
	
	lines[#lines+1] = {'%s = {%s}', key, table_concat(values, ', ')}
end

function mt:key2id(name, code, key)
    local id = code and self.key[code] and self.key[code][key] or self.key[name] and self.key[name][key] or self.key['common'][key]
    if id then
        return id
    end
    return nil
end

function mt:get_key(id)
	local meta  = self.meta[id]
	if not meta then
		return
	end
	local key  = meta.field
	local num   = meta.data
	if num and num ~= 0 then
		key = key .. string_char(('A'):byte() + num - 1)
	end
	if meta._has_index then
		key = key .. ':' .. (meta.index + 1)
	end
	return key
end

function mt:get_comment(id)
	local comment = self.meta[id].displayname
	return self.w2l:editstring(comment)
end

return function (w2l, type, data)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.w2l = w2l

	tbl.meta = w2l:read_metadata(type)
    tbl.key = w2l:keyconvert(type)
    tbl.file_name = type

	tbl:add_chunk(data)

	return table_concat(tbl.lines, '\r\n')
end
