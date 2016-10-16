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
local read_txt = require 'read_txt'
local create_template = require 'create_template'

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename()
local meta_dir = rootpath / 'meta'
local template_dir = rootpath / 'template'

local function main()
	w3x2txt:init()

	-- 生成key2id
    for file_name, meta in pairs(w3x2txt.config['metadata']) do
		print('正在生成key2id', file_name)
		local metadata = read_metadata(meta_dir / meta)
		local content = w3x2txt:key2id(file_name, metadata)
		io.save(meta_dir / (file_name .. '.ini'), content)
	end

	--读取编辑器文本
	local editstring
	local ini = read_txt(meta_dir / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end

	-- 生成模板lni
	fs.create_directories(template_dir)
	for file_name, meta in pairs(w3x2txt.config['metadata']) do
		print('正在生成模板', file_name)
		local template = create_template(file_name)

		template:set_option('discard_useless_data', true)
		template:set_option('max_level_key', w3x2txt.config['key']['max_level'][file_name])

		local slk = w3x2txt.config['template']['slk'][file_name]
		if type(slk) == 'table' then
			for i = 1, #slk do
				template:add_slk(read_slk(meta_dir / slk[i]))
			end
		else
			template:add_slk(read_slk(meta_dir / slk))
		end

		local txt = w3x2txt.config['template']['txt'][file_name]
		if type(txt) == 'table' then
			for i = 1, #txt do
				template:add_txt(read_txt(meta_dir / txt[i]))
			end
		elseif txt then
			template:add_txt(read_txt(meta_dir / txt))
		end

		local key = lni:loader(io.load(meta_dir / (file_name .. '.ini')), name)
		local data = template:save(key)
		local metadata = read_metadata(meta_dir / w3x2txt.config['metadata'][file_name])
		local content = w3x2txt:obj2lni(data, metadata, editstring)
		io.save(template_dir / (file_name .. '.ini'), content)
	end

	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
