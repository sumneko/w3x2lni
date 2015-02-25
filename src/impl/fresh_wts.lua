local function fresh_wts(self, file_name_out)

	local lines	= {}
	for i, t in ipairs(self.wts_strings) do
		if t and not t.converted then
			table.insert(lines, t.string)
		end
	end

	io.save(file_name_out, table.concat(lines, '\r\n\r\n'))

end

return fresh_wts
