local current_chunk

local function parse(ini, line)
    if #line == 0 then
        return
    end
    if line:sub(1, 2) == '//' then
        return
    end
    local chunk_name = line:match '%[(.-)%]'
    if chunk_name then
        current_chunk = chunk_name
        if not ini[chunk_name] then
            ini[chunk_name] = {}
        end
        return
    end
    if not current_chunk then
        return
    end
    line = line:gsub('%c+', '')
    local key, value = line:match '^%s*(.-)%s*%=%s*(.-)%s*$'
    if key and value then
        ini[current_chunk][key] = value
        return
    end
end

return function (_, file_name)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end
    current_chunk = nil
    local ini = {}
	for line in io.lines2(file_name) do
        parse(ini, line)
    end
    return ini
end
