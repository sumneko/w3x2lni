local w3x2txt = {}

local wts_strings	= {}

function w3x2txt.read_wts(file_name_in)
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
		table.insert(wts_strings, t)
		wts_strings[('%03d'):format(i)]	= t	--这里的索引是字符串
	end
end

function string.convert_wts(s, only_short)
	return s
	--return s:gsub('TRIGSTR_(%d+)',
	--	function(i)
	--		local s	= wts_strings[i].text:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t')
	--		if only_short and #s > 256 then
	--			return
	--		end
	--		wts_strings[i].converted	= true
	--		return s
	--	end
	--)
end

function w3x2txt.fresh_wts(file_name_out)
	local lines	= {}
	for i, t in ipairs(wts_strings) do
		if t and not t.converted then
			table.insert(lines, t.string)
		end
	end

	io.save(file_name_out, table.concat(lines, '\r\n\r\n'))
end

local convertors = {
	'obj2txt', 'txt2obj',
	'wtg2txt', 'txt2wtg',
	'wct2txt', 'txt2wct',
	'w3i2txt', 'txt2w3i',
	'read_metadata',
	'read_triggerdata',
}

for _, c in ipairs(convertors) do
	w3x2txt['impl_' .. c] = require('impl.' .. c)
	w3x2txt[c] = function (...)
		return w3x2txt['impl_' .. c](w3x2txt, ...)
	end
end

return w3x2txt
