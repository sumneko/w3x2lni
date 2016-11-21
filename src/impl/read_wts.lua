local table_insert = table.insert

local mt = {}
mt.__index = mt

function mt:load(content, only_short, read_only)
	local wts = self.wts
	return content:gsub([=[['"]TRIGSTR_(%d+)['"]]=], function(i)
		local str_data = wts[i]
		if not str_data then
			return
		end
		local text = str_data.text
		if only_short and #text > 256 then
			return
		end
		str_data.converted = not read_only
		if text:match '[\n\r]' then
			return ('[=[\r\n%s]=]'):format(text)
		else
			return ('%q'):format(text)
		end
	end)
end

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
	return setmetatable({ wts = tbl }, mt)
end
