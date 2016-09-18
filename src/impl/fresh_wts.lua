local table_insert = table.insert
local table_concat = table.concat
local ipairs = ipairs

local function fresh_wts(self, file_name_out)

	local lines	= {}
	for i, t in ipairs(self.wts_strings) do
		if t and not t.converted then
			table_insert(lines, t.string)
		end
	end

	io.save(self.dir['lni'] / file_name_out, table_concat(lines, '\r\n\r\n'))

end

return fresh_wts
