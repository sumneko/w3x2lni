package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
local uni      = require 'unicode'
local w3x2txt  = require 'w3x2txt'
local lni      = require 'lni'

local root_dir = fs.path(uni.a2u(arg[1]))
local meta_dir = root_dir / 'meta'
local temp_dir = root_dir / 'temp'

local function read_config()
	local config_str = io.load(root_dir / 'config.ini')
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
