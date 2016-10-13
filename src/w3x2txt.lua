local mt = {}

function mt:convert_wts(content, wts, only_short, read_only)
	if not wts then
		return content
	end
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
			return ('[[\n%s\n]]'):format(text)
		else
			return ('%q'):format(text)
		end
	end)
end

mt.dir = {}
function mt:set_dir(name, dir)
	self.dir[name] = dir
end

mt.metadata = {}
function mt:set_metadata(name, metadata)
	self.metadata[name] = metadata
end

local function main()
	-- 加载脚本
	local convertors = {
		'read_wts', 'fresh_wts',
		'obj2lni', 'lni2obj',
		'w3i2lni',
		'read_obj', 'read_ini',
		'read_w3i',
		'read_metadata',
		'key2id',
	}
	
	for _, name in ipairs(convertors) do
		local func = require('impl.' .. name)
		mt[name] = function (self, ...)
			print(('正在执行:') .. name)
			return func(self, ...)
		end
	end
end

main()

return mt
