local tonumber = tonumber

local current_chunk

local function parse(txt, line)
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
        txt[current_chunk][key] = tonumber(value) or value
        return
    end
end

return function (file_name)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end
    current_chunk = nil
    local txt = {}
	for line in io.lines2(file_name) do
        parse(txt, line)
    end
    return txt
end
