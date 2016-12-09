(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w2l  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
local create_key_type = require 'create_key_type'
local order_prebuilt = require 'order.prebuilt'
local table2lni = require 'table2lni'

local rootpath = fs.path(uni.a2u(arg[0])):remove_filename()
local mpq_dir = rootpath / 'script' / 'mpq'
local key_dir = rootpath / 'script' / 'key'
local root_dir = rootpath / 'script'
local template_dir = rootpath / 'template'
local default_dir = rootpath / 'script' / 'default'

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
	w2l:init()

	-- 生成key_type
	local keydata = w2l:parse_txt(io.load(mpq_dir / 'ui' / 'uniteditordata.txt'))
	local content = create_key_type(keydata)
	io.save(root_dir / 'key_type.lua', content)

	-- 生成key2id
    for file_name, meta in pairs(w2l.info['metadata']) do
		message('正在生成key2id', file_name)
		local metadata = w2l:read_metadata(mpq_dir / meta, io.load)
        local slk = w2l.info['template']['slk'][file_name]
        local template = {}
        for i = 1, #slk do
            add_table(template, w2l:parse_slk(io.load(mpq_dir / slk[i])))
        end
		local content = w2l:key2id(file_name, metadata, template)
		io.save(key_dir / (file_name .. '.ini'), content)
	end

	-- 生成模板lni
	fs.create_directories(default_dir)
	fs.create_directories(template_dir)
	for file_name, meta in pairs(w2l.info['metadata']) do
		message('正在生成模板', file_name)
		local data = w2l:slk_loader(file_name, io.load, function(name)
			return io.load(w2l.dir['mpq'] / name)
		end)
		w2l:post_process(file_name, data, io.load)
		io.save(default_dir / (file_name .. '.ini'), table2lni(data))
		io.save(template_dir / (file_name .. '.ini'), w2l:to_lni(file_name, data, io.load))
		local t = w2l:parse_lni(io.load(default_dir / (file_name .. '.ini')))
		print(t)
	end

	-- 生成技能命令映射
	local skill_data = w2l:parse_lni(io.load(template_dir / 'war3map.w3a.ini'))
	local order_list = order_prebuilt(skill_data)
	io.save(rootpath / 'script' / 'order' / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
