(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w3x2txt  = require 'w3x2txt'
local lni      = require 'lni'
local read_slk = require 'read_slk'
local read_metadata = require 'read_metadata'
local read_ini = require 'read_ini'
local read_txt = require 'read_txt'
local create_template = require 'create_template'
local create_key_type = require 'create_key_type'
local create_order_list = require 'create_order_list'

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local meta_dir = rootpath / 'src' / 'meta'
local key_dir = rootpath / 'src' / 'key'
local root_dir = rootpath / 'src'
local template_dir = rootpath / 'template'
local skill_dir = rootpath / 'src' / 'skill'

local function main()
	w3x2txt:init()

	-- 生成key_type
	local keydata = read_txt(io.load(meta_dir / 'uniteditordata.txt'))
	local content = create_key_type(keydata)
	io.save(root_dir / 'key_type.lua', content)

	-- 生成key2id
    for file_name, meta in pairs(w3x2txt.config['metadata']) do
		print('正在生成key2id', file_name)
		local metadata = read_metadata(meta_dir / meta)
		local content = w3x2txt:key2id(file_name, metadata)
		io.save(key_dir / (file_name .. '.ini'), content)
	end

	--读取编辑器文本
	local editstring
	local ini = read_ini(meta_dir / 'WorldEditStrings.txt')
	if ini then
		editstring = ini['WorldEditStrings']
	end

	-- 生成模板lni
	fs.create_directories(template_dir)
	for file_name, meta in pairs(w3x2txt.config['metadata']) do
		print('正在生成模板', file_name)
		local template = create_template(file_name)
		local metadata = read_metadata(meta_dir / w3x2txt.config['metadata'][file_name])
		local key = lni:loader(io.load(key_dir / (file_name .. '.ini')), name)

		local slk = w3x2txt.config['template']['slk'][file_name]
		if type(slk) == 'table' then
			for i = 1, #slk do
				template:add_slk(read_slk(io.load(meta_dir / slk[i])))
			end
		else
			template:add_slk(read_slk(io.load(meta_dir / slk)))
		end

		local txt = w3x2txt.config['template']['txt'][file_name]
		if type(txt) == 'table' then
			for i = 1, #txt do
				template:add_txt(read_txt(io.load(meta_dir / txt[i])))
			end
		elseif txt then
			template:add_txt(read_txt(io.load(meta_dir / txt)))
		end

		local data = template:save(metadata, key)
		local content = w3x2txt:obj2lni(data, metadata, editstring, nil, key, w3x2txt.config['key']['max_level'][file_name])
		io.save(template_dir / (file_name .. '.ini'), content)
	end

	-- 生成技能命令映射
	local skill_data = lni:loader(io.load(template_dir / 'war3map.w3a.ini'))
	local order_list = create_order_list(skill_data)
	io.save(skill_dir / 'order_list.lua', order_list)

	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
