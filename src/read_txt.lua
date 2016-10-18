local tonumber = tonumber

local current_chunk

local key_type = {
	int			= 0,
	bool		= 0,
	deathType	= 0,
	attackBits	= 0,
	teamColor	= 0,
	fullFlags	= 0,
	channelType	= 0,
	channelFlags= 0,
	stackFlags	= 0,
	silenceFlags= 0,
	spellDetail	= 0,
	real		= 1,
	unreal		= 2,
}

local function key2id(keys, skill, key)
    local key = key:lower()
    local id = keys[skill] and keys[skill][key] or keys['public'][key]
    if id then
        return id
    end
    return nil
end

local function get_key_type(meta, keys, skill, key)
    local key = key2id(keys, skill, key)
    if not key then
        return 3
    end
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

local function parse(txt, metadata, keys, line)
    if #line == 0 then
        return
    end
    if line:sub(1, 2) == '//' then
        return
    end
    local chunk_name = line:match '%[(.-)%]'
    if chunk_name then
        current_chunk = chunk_name
        if not txt[chunk_name] then
            txt[chunk_name] = {}
        end
        return
    end
    if not current_chunk then
        return
    end
    line = line:gsub('%c+', '')
    local key, value = line:match '^%s*(.-)%s*%=%s*(.-)%s*$'
    if key and value then
        local type = get_key_type(metadata, keys, current_chunk, key)
        if type == 3 then
            if value:sub(1, 1) == '"' and value:sub(-1, -1) == '"' then
                value = value:sub(2, -2)
            end
        else
            value = tonumber(value)
        end
        txt[current_chunk][key] = value
        return
    end
end

return function (file_name, metadata, key)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end
    current_chunk = nil
    local txt = {}
	for line in io.lines2(file_name) do
        parse(txt, metadata, key, line)
    end
    return txt
end
