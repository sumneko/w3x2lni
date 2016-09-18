local table_insert = table.insert

local function read_wts(self, file_name_in)
	local content = io.load(self.dir['w3x'] / file_name_in)
	if not content then
		print('文件无效:' .. file_name_in)
		return
	end

	for string in content:gmatch 'STRING.-%c*%}' do
		local i, s = string:match 'STRING (%d+).-%{%c*(.-)%c*%}'
		local t	= {
			string	= string,
			index	= i,
			text	= s,
		}
		table_insert(self.wts_strings, t)
		self.wts_strings[('%03d'):format(i)] = t	--这里的索引是字符串
	end
end

return read_wts
