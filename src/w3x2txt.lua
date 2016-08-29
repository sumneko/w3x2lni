local mt = {}

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
	'convert_j',
}

function mt:format_value(value, id)
	local type = self.value_type[meta_list[id].type]
	if type == 0 then
		return value
	elseif type == 1 or type == 2 then
		return ('%.4f'):format(value)
	else
		return ('%q'):format(value)
	end
end

function mt:get_value_type(id)
	local type = self.value_type[meta_list[id].type]
	return type or 3
end

local function init_meta(self)
	self.meta_list = setmetatable({}, { __index = function(self, id)
		if id:sub(-1) == '\0' then
			return self[('z'):unpack(id)]
		end
		return 'string'
	end})
	self.value_type = {
		int			= 0,
		bool		= 0,
		deathType	= 0,
		attackBits	= 0,
		teamColor	= 0,
		fullFlags	= 0,
		channelType	= 0,
		channelFlags= 0,
		stackFlags	= 0,
		silenceFlags= 0,
		spellDetail	= 0,
		real		= 1,
		unreal		= 2,
	}
end

local function main()
	-- 加载脚本
	for _, name in ipairs(convertors) do
		local func = require('impl.' .. name)
		mt[name] = function (self, ...)
			print(('正在执行:') .. name)
			return func(self, ...)
		end
	end

	-- 创建meta数据
	init_meta(mt)
end

main()

return mt
