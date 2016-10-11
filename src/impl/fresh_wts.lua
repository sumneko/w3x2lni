local table_insert = table.insert
local table_concat = table.concat
local ipairs = ipairs

return function (self, wts)
	local lines	= {}
	for i, t in ipairs(wts) do
		if t and not t.converted then
			table_insert(lines, t.string)
		end
	end

	return table_concat(lines, '\r\n\r\n')
end
