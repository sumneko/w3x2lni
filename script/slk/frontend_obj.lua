local select = select
local string_lower = string.lower
local string_unpack = string.unpack
local string_match = string.match

local w2l
local wts
local has_level
local metadata
local unpack_buf
local unpack_pos
local force_slk

local function set_pos(...)
	unpack_pos = select(-1, ...)
	return ...
end

local function unpack(str)
	return set_pos(string_unpack(str, unpack_buf, unpack_pos))
end

local character = { 'A','B','C','D','E','F','G','H','I' }

local function get_displaykey(id)
    local meta = metadata[id]
    if not meta then
        return
    end
    local key = meta.field
    local num = meta.data
    if num and num ~= 0 then
        key = key .. character[num]
    end
    if meta._has_index then
        key = key .. ':' .. (meta.index + 1)
    end
    return key
end

local function read_data(obj)
	local data = {}
	local id = string_match(unpack 'c4', '^[^\0]+')
	local meta = metadata[id]
	local key = get_displaykey(id)
	local value_type = unpack 'l'
	local level = 0

	if key then
		key = string_lower(key)
		local check_type = w2l:get_id_type(meta.type)
		if value_type ~= check_type and (value_type == 3 or check_type == 3) then
			message('-report', ('数据类型错误:[%s],应该为[%s],错误的解析为了[%s]'):format(id, value_type, check_type))
		end
	end

	--是否包含等级信息
	if has_level then
		local this_level = unpack 'l'
		level = this_level
		-- 扔掉一个整数
		unpack 'l'
	end

	local value
	if value_type == 0 then
		value = unpack 'l'
	elseif value_type == 1 or value_type == 2 then
		value = unpack 'f'
	else
		local str = unpack 'z'
		value = wts:load(str)
	end
	
	-- 扔掉一个整数
	unpack 'l'

	if not key then
		return
	end
	if meta['repeat'] and meta['repeat'] > 0 then
		if level == 0 then
			level = 1
		end
		if not obj[key] then
			obj[key] = {}
		end
		obj[key][level] = value
	else
		obj[key] = value
	end
end

local function read_obj(chunk, type)
	local parent, name = unpack 'c4c4'
	if name == '\0\0\0\0' then
		name = parent
	end
	if not w2l:is_usable_para(parent) then
		force_slk = true
	end
	local obj = {
		_id = name,
		_parent = parent,
		_type = type,
		_obj = true,
	}

	local count = unpack 'l'
	for i = 1, count do
		read_data(obj)
	end
	if type == 'buff' then
		chunk[string_lower(name)] = obj
	else
		chunk[name] = obj
	end
	obj._max_level = obj[has_level]
    if obj._max_level == 0 then
        obj._max_level = 1
    end
	return obj
end

local function read_version()
	return unpack 'l'
end

local function read_chunk(chunk, type)
	local count = unpack 'l'
	for i = 1, count do
		local obj = read_obj(chunk, type)
	end
end

return function (w2l_, type, wts_, buf)
	w2l = w2l_
	wts = wts_
	has_level = w2l.info.key.max_level[type]
	metadata = w2l:read_metadata(type)
	unpack_buf = buf
	unpack_pos = 1
	force_slk = false
	local data    = {}
	-- 版本号
	read_version()
	-- 默认数据
	read_chunk(data, type)
	-- 自定义数据
	read_chunk(data, type)
	return data, force_slk
end
