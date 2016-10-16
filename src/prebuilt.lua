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
local read_slk = require 'read_slk'
local read_metadata = require 'read_metadata'
local create_template = require 'create_template'

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename()
local meta_dir = rootpath / 'meta'
local template_dir = rootpath / 'template'

local function main()
	w3x2txt:init()

	-- 生成key2id
    for file_name, meta in pairs(w3x2txt.config['metadata']) do
		local metadata = read_metadata(meta_dir / meta)
		local content = w3x2txt:key2id(file_name, metadata)
		io.save(meta_dir / (file_name .. '.ini'), content)
	end

	-- 生成模板lni
	fs.create_directories(template_dir)
	for file_name, meta in pairs(w3x2txt.config['template']) do
		local template = create_template(file_name, w3x2txt.config['metadata'][file_name])
		if type(meta) == 'table' then
			for i = 1, #meta do
				template:add_meta(read_slk(meta_dir / meta[i]))
			end
		else
			template:add_meta(read_slk(meta_dir / meta))
		end
		local lni = template:save()
	end
end

main()
