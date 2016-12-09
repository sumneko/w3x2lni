local uni = require 'ffi.unicode'
local w3xparser = require 'w3xparser'
local lni = require 'lni-c'
local slk = w3xparser.slk
local txt = w3xparser.txt

local mt = {}

function mt:read_config()
	self.config = lni(io.load(self.root / 'config.ini'), 'config')
    self.info   = lni(io.load(self.root / 'script' / 'info.ini'), 'info')
end

function mt:init()
	self.root = fs.path(uni.a2u(arg[0])):remove_filename()
	self.mpq = self.root / 'script' / 'mpq'
	self.key = self.root / 'script' / 'prebuilt' / 'key'
	self.template = self.root / 'template'
	self.default = self.root / 'script' / 'prebuilt' / 'default'
	self:read_config()
end

function mt:parse_lni(...)
	return lni(...)
end

function mt:parse_slk(buf)
	return slk(buf)
end

function mt:parse_txt(buf)
	return txt(buf)
end

local function main()
	-- 加载脚本
	local convertors = {
		'read_wts',
		'to_lni', 'lni2obj',
		'w3i2lni', 'lni2w3i',
		'read_obj',
		'read_w3i',
		'read_metadata',
		'create_unitsdoo',
		'key2id',
		'add_template',
		'slk_loader',
		'post_process',
	}
	
	for _, name in ipairs(convertors) do
		local func = require('impl.' .. name)
		mt[name] = function (self, ...)
			--message(('正在执行:') .. name)
			return func(self, ...)
		end
	end
end

main()

return mt
