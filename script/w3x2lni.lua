local lni = require 'lni'
local uni = require 'ffi.unicode'

local mt = {}

mt.dir = {}
function mt:set_dir(name, dir)
	self.dir[name] = dir
end

function mt:read_config()
	self.config = lni:loader(io.load(self.dir['root'] / 'config.ini'), 'config')
    self.info   = lni:loader(io.load(self.dir['root'] / 'script' / 'info.ini'), 'info')
end

function mt:init()
	rootpath = fs.path(uni.a2u(arg[0])):remove_filename()
	self:set_dir('root', rootpath)
	self:set_dir('meta', rootpath / 'script' / 'meta')
	self:set_dir('key', rootpath / 'script' / 'key')
	self:set_dir('template', rootpath / 'template')
	self:set_dir('default', rootpath / 'script' / 'meta' / 'lni')
	self:read_config()
end

local function main()
	-- 加载脚本
	local convertors = {
		'read_wts',
		'to_lni', 'lni2obj',
		'w3i2lni', 'lni2w3i',
		'read_obj',
		'read_w3i',
		'read_slk', 'read_txt',
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
