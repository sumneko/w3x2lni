local w3x2txt = {}

function string.convert_wts(s, only_short, read_only)
	--return s
	return s:gsub('TRIGSTR_(%d+)',
		function(i)
			local s	= w3x2txt.wts_strings[i]
			if not s then
				return
			end
			local s = ('%q'):format(s.text):sub(2, -2)
			if only_short and #s > 256 then
				return
			end

			w3x2txt.wts_strings[i].converted	= not read_only
			return s
		end
	)
end

local convertors = {
	'read_wts', 'fresh_wts',
	'obj2txt', 'txt2obj',
	'wtg2txt', 'txt2wtg',
	'wct2txt', 'txt2wct',
	'w3i2txt', 'txt2w3i',
	'read_metadata',
	'read_triggerdata',
	'convert_j',
}

for _, c in ipairs(convertors) do
	w3x2txt['impl_' .. c] = require('impl.' .. c)
	w3x2txt[c] = function (...)
		print(('正在执行:') .. c)
		return w3x2txt['impl_' .. c](w3x2txt, ...)
	end
end

return w3x2txt
