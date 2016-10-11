local table_insert = table.insert

return function (self, content)
	local tbl = {}
	for string in content:gmatch 'STRING.-%c*%}' do
		local i, s = string:match 'STRING (%d+).-%{%c*(.-)%c*%}'
		local t	= {
			string	= string,
			index	= i,
			text	= s,
		}
		table_insert(tbl, t)
		tbl[('%03d'):format(i)] = t	--这里的索引是字符串
	end
	return tbl
end
