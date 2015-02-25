local function read_wts(self, file_name_in)

	self.wts_strings	= {}

	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	for string in content:gmatch 'STRING.-%c*%}' do
		local i, s	= string:match 'STRING (%d+).-%{%c*(.-)%c*%}'
		local t	= {
			string	= string,
			index	= i,
			text	= s,
		}
		table.insert(self.wts_strings, t)
		self.wts_strings[('%03d'):format(i)]	= t	--这里的索引是字符串
	end

end

return read_wts
