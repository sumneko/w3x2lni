local stormlib = require 'stormlib'
local create_map = require 'create_map'
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

	for file_name, meta_name in pairs(self.config['metadata']) do
		self:set_metadata(file_name, meta_name)
	end

	return self.config
end

function mt:create_map()
	return create_map(self)
end

function mt:init(rootpath)
	if rootpath then
		rootpath = fs.path(rootpath)
	else
		rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
	end
	self:set_dir('root', rootpath)
	self:set_dir('meta', rootpath / 'src' / 'meta')
	self:set_dir('key', rootpath / 'src' / 'key')
	self:set_dir('template', rootpath / 'template')
	self:read_config()
end

local function main()
	-- 加载脚本
	local convertors = {
		'read_wts', 'fresh_wts',
		'obj2lni', 'lni2obj',
		'w3i2lni', 'lni2w3i',
		'read_obj',
		'read_w3i',
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
