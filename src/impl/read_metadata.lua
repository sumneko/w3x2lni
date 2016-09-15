local read_slk = require 'impl.read_slk'

local function read_metadata(self, file_name)
	local tbl = read_slk(file_name)
	if not tbl then
		return
	end
	if not self.meta then
		self.meta = {}
	end
	for k, v in pairs(tbl) do
		if self.meta[k] then
			print('meta表id重复', k)
		end
		self.meta[k] = v
	end
end

return read_metadata
