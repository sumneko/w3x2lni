local read_ini = require 'impl.read_ini'

local function read_editstring(self, file_name)
	local tbl = read_ini(file_name)
	if not tbl then
		return
	end
	self.editstring = tbl['WorldEditStrings']
end

return read_editstring
