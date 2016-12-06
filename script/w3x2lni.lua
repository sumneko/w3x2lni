local lni = require 'lni'

local mt = {}

mt.dir = {}
function mt:set_dir(name, dir)
	self.dir[name] = dir
end

mt.metadata = {}
function mt:set_metadata(name, metadata)
	self.metadata[name] = metadata
end

function mt:read_config()
	self.config = lni:loader(io.load(self.dir['root'] / 'config.ini'), 'config')
    self.info   = lni:loader(io.load(self.dir['meta'] / 'info.ini'),   'info')

	for file_name, meta_name in pairs(self.info['metadata']) do
		self:set_metadata(file_name, meta_name)
	end
end

function mt:init(rootpath)
	if rootpath then
		rootpath = fs.path(rootpath)
	else
		rootpath = fs.get(fs.DIR_EXE):remove_filename()
	end
	self:set_dir('root', rootpath)
	self:set_dir('meta', rootpath / 'script' / 'meta')
	self:set_dir('key', rootpath / 'script' / 'key')
	self:set_dir('template', rootpath / 'template')
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
