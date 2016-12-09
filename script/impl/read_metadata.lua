local pairs = pairs

local metadatas = {}

local function read_metadata(w2l, file_path, loader)
	local file_name = file_path:string()
	if metadatas[file_name] then
		return metadatas[file_name]
	end
	local tbl = w2l:parse_slk(loader(file_path))
	metadatas[file_name] = tbl

	local has_index = {}
	for k, v in pairs(tbl) do
		-- 进行部分预处理
		local name  = v['field']
		local index = v['index']
		if index and index >= 1 then
			has_index[name] = true
		end
	end
	local has_level
	for k, v in pairs(tbl) do
		local name = v['field']
		if has_index[name] then
			v._has_index = true
		end
		if v['repeat'] then
			has_level = true
		end
	end
	tbl._has_level = has_level
	return tbl
end

return read_metadata
