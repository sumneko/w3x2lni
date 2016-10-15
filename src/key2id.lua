(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\src\\?.lua'
end)()

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'
local lni      = require 'lni'

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename()
local meta_dir = rootpath / 'meta'

local function read_config()
	local config_str = io.load(rootpath / 'config.ini')
	config = lni:loader(config_str, 'config')

	for file_name, meta_name in pairs(config['metadata']) do
		w3x2txt:set_metadata(file_name, meta_name)
	end
end

local function main()
	read_config()
	w3x2txt:set_dir('meta', meta_dir)

    for file_name, meta in pairs(config['metadata']) do
		local metadata = w3x2txt:read_metadata(meta)
		local content = w3x2txt:key2id(file_name, metadata)
		io.save(meta_dir / (file_name .. '.ini'), content)
	end
end

main()
