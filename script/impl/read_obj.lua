local math_tointeger = math.tointeger
local string_char = string.char
local select = select

local mt = {}
mt.__index = mt

function mt:set_index(...)
	self.index = select(-1, ...)
	return ...
end

function mt:unpack(str)
	return self:set_index(str:unpack(self.content, self.index))
end

function mt:read_version()
	return self:unpack 'l'
end

function mt:read_chunk(chunk)
	local count = self:unpack 'l'
	for i = 1, count do
		self:read_obj(chunk)
	end
end

function mt:read_obj(chunk)
	local obj = {}
	local code, name = self:unpack 'c4c4'
	if name == '\0\0\0\0' then
		name = code
		if not self:is_usable_code(code) then
			code = nil
			self.force_slk = true
		end
	end
	if code then
		obj._true_origin = true
	end
	obj['_user_id'] = name
	obj['_origin_id'] = code

	local count = self:unpack 'l'
	for i = 1, count do
		self:read_data(obj)
	end
	chunk[name] = obj
	obj._max_level = obj[self.max_level_key]
    if obj._max_level == 0 then
        obj._max_level = 1
    end
end

function mt:get_id_name(id)
	local meta  = self.meta[id]
	local name  = meta.field:lower()
	local num   = meta.data
	if num and num ~= 0 then
		name = name .. string_char(('a'):byte() + num - 1)
	end
	if meta._has_index then
		name = name .. ':' .. (meta.index + 1)
	end
	return name
end

function mt:read_data(obj)
	local data = {}
	local id = self:unpack 'c4' :match '^[^\0]+'
	local key = self:get_id_name(id)
	local value_type = self:unpack 'l'
	local level = 0

	local check_type = self:get_id_type(id)
	if value_type ~= check_type and (value_type == 3 or check_type == 3) then
		message(('数据类型错误:[%s],应该为[%s],错误的解析为了[%s]'):format(id, value_type, check_type))
	end

	--是否包含等级信息
	if self.has_level then
		local this_level = self:unpack 'l'
		level = this_level
		-- 扔掉一个整数
		self:unpack 'l'
	end

	if value_type == 0 then
		value = self:unpack 'l'
	elseif value_type == 1 or value_type == 2 then
		value = self:unpack 'f'
	else
		value = self:unpack 'z'
	end
	
	-- 扔掉一个整数
	self:unpack 'l'

	
	if level == 0 then
		obj[key] = value
	else
		if not obj[key] then
			obj[key] = {}
		end
		obj[key][level] = value
	end
end

return function (w2l, ttype, file_name)
	local tbl     = setmetatable({}, mt)
	tbl.content   = io.load(file_name)
	tbl.index     = 1
	tbl.meta      = w2l:read_metadata(ttype)
	tbl.has_level = w2l.info['key']['max_level'][ttype]
    tbl.max_level_key = w2l.info['key']['max_level'][ttype]

	function tbl:get_id_type(id)
		return w2l:get_id_type(id, self.meta)
	end

	function tbl:is_usable_code(code)
		return w2l:is_usable_code(code)
	end

	local data    = {}

	-- 版本号
	tbl:read_version()
	-- 默认数据
	tbl:read_chunk(data)
	-- 自定义数据
	tbl:read_chunk(data)

	return data, tbl.force_slk
end
