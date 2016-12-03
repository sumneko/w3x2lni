(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w3x2lni  = require 'w3x2lni'
local lni      = require 'lni'
local uni      = require 'ffi.unicode'
local read_slk = require 'read_slk'
local read_metadata = require 'read_metadata'
local read_ini = require 'read_ini'
local read_txt = require 'read_txt'
local create_template = require 'create_template'
local create_key_type = require 'create_key_type'
local create_order_list = require 'create_order_list'

local rootpath
if arg[1] then
	rootpath = fs.path(arg[1])
else
	rootpath = fs.get(fs.DIR_EXE):remove_filename()
end
local meta_dir = rootpath / 'script' / 'meta'
local key_dir = rootpath / 'script' / 'key'
local root_dir = rootpath / 'script'
local template_dir = rootpath / 'template'
local skill_dir = rootpath / 'script' / 'skill'

function message(...)
	local tbl = {...}
	local count = select('#', ...)
	for i = 1, count do
		tbl[i] = uni.u2a(tostring(tbl[i]))
	end
	print(table.concat(tbl, ' '))
end

local function add_table(t1, t2)
    for k, v in pairs(t2) do
        if type(t1[k]) == 'table' and type(v) == 'table' then
            add_table(t1[k], v)
        else
            t1[k] = v
        end
    end
end

local function main()
	w3x2lni:init(arg[1])

	-- 生成key_type
	local keydata = read_txt(io.load(meta_dir / 'uniteditordata.txt'))
	local content = create_key_type(keydata)
	io.save(root_dir / 'key_type.lua', content)

	-- 生成key2id
    for file_name, meta in pairs(w3x2lni.info['metadata']) do
		message('正在生成key2id', file_name)
		local metadata = read_metadata(meta_dir / meta)
        local slk = w3x2lni.info['template']['slk'][file_name]
        local template = {}
        for i = 1, #slk do
            add_table(template, read_slk(io.load(meta_dir / slk[i])))
        end
		local content = w3x2lni:key2id(file_name, metadata, template)
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
	for file_name, meta in pairs(w3x2lni.info['metadata']) do
		message('正在生成模板', file_name)
		local template = create_template(file_name)
		local metadata = read_metadata(meta_dir / w3x2lni.info['metadata'][file_name])
		local key = lni:loader(io.load(key_dir / (file_name .. '.ini')), name)

		local slk = w3x2lni.info['template']['slk'][file_name]
        for i = 1, #slk do
            template:add_slk(read_slk(io.load(meta_dir / slk[i])))
        end

		local txt = w3x2lni.info['template']['txt'][file_name]
        for i = 1, #txt do
            template:add_txt(read_txt(io.load(meta_dir / txt[i])))
        end

		local data = template:save(metadata, key)
		local content = w3x2lni:obj2lni(data, metadata, editstring, nil, key, w3x2lni.info['key']['max_level'][file_name], file_name)
		io.save(template_dir / (file_name .. '.ini'), content)
	end

	-- 生成技能命令映射
	local skill_data = lni:loader(io.load(template_dir / 'war3map.w3a.ini'))
	local order_list = create_order_list(skill_data)
	io.save(skill_dir / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
