local string_lower = string.lower

local w2l
local force_slk

local function add_obj(type, name, level_key, obj)
    local new_obj = {}
    for key, value in pairs(obj) do
        if key ~= '_id' then
            new_obj[string_lower(key)] = value
        end
    end
    new_obj._id = name
    new_obj._para = obj._id
    new_obj._lower_para = string_lower(obj._id)
    new_obj._max_level = obj[level_key]
    new_obj._type = type
    if not w2l:is_usable_para(new_obj._para) then
        new_obj._para = nil
        force_slk = true
    end
	if new_obj._para then
		new_obj._true_origin = true
	end

    return new_obj
end

local function convert(data, type, level_key, lni)
    for name, obj in pairs(lni) do
        data[string_lower(name)] = add_obj(type, name, level_key, obj)
    end
end

return function (w2l_, type, buf)
    w2l = w2l_
    local lni = w2l:parse_lni(buf)
	local level_key = w2l.info.key.max_level[type]
    local data = {}
    force_slk = false

    convert(data, type, level_key, lni)
    return data, force_slk
end
