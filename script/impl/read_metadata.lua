local pairs = pairs
local setmetatable = setmetatable

local mt = {}
mt.__index = mt

local function read_metadata(w2l, file_name)
	local tbl = w2l:read_slk(io.load(file_name))
	if not tbl then
		return
	end

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
	tbl._has_level = true
	return tbl
end

return read_metadata
