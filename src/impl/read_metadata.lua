local read_slk = require 'impl.read_slk'

local function read_metadata(file_name)
	local tbl = read_slk(file_name)
	if not tbl then
		return
	end
	local meta = {}
	for k, v in pairs(tbl) do
		if meta[k] then
			print('meta表id重复', k)
		end
		meta[k] = v
	end
	return meta
end

return read_metadata
