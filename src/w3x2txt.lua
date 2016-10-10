local mt = {}

mt.wts_strings = {}
function mt:convert_wts(str, only_short, read_only)
	return str:gsub('TRIGSTR_(%d+)', function(i)
		local str_data = self.wts_strings[i]
		if not str_data then
			return
		end
		local text = ('%q'):format(str_data.text):sub(2, -2)
		if only_short and #text > 256 then
			return
		end
		str_data.converted = not read_only
		return text
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
		'read_obj',
		'read_metadata',
		'read_editstring',
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
