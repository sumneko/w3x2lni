(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w2l  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
local archive = require 'archive'
local order_prebuilt = require 'order.prebuilt'
local default2lni = require 'prebuilt.default2lni'
local txt2teamplate = require 'prebuilt.txt2teamplate'
local create_key2id = require 'prebuilt.create_key2id'
w2l:initialize()

function message(...)
	if select(1, ...) == '-progress' then
		return
	end
	local tbl = {...}
	local count = select('#', ...)
	for i = 1, count do
		tbl[i] = uni.u2a(tostring(tbl[i]))
	end
	print(table.concat(tbl, ' '))
end

local function add_table(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if tbl1[k] then
            if type(tbl1[k]) == 'table' and type(v) == 'table' then
                add_table(tbl1[k], v)
            else
                tbl1[k] = v
            end
        else
            tbl1[k] = v
        end
    end
end

local function prebuilt_id_type(id_data)
    local lines = {}
    lines[#lines+1] = ('%s = %s'):format('int', 0)
    lines[#lines+1] = ('%s = %s'):format('bool', 0)
    lines[#lines+1] = ('%s = %s'):format('real', 1)
    lines[#lines+1] = ('%s = %s'):format('unreal', 2)

    for key, data in pairs(id_data) do
        local value = data['00'][1]
        local tp
        if tonumber(value) then
            tp = 0
        else
            tp = 3
        end
        lines[#lines+1] = ('%s = %s'):format(key, tp)
    end

    table.sort(lines)

    return '[root]\r\n' .. table.concat(lines, '\r\n')
end

local function pack_table(tbl)
	local lines = {}
	for name, value in pairs(tbl) do
		lines[#lines+1] = ('%s=%s'):format(name, value)
	end
	table.sort(lines)
	return '[root]\r\n' .. table.concat(lines, '\r\n')
end

local function set_config()
	local config = w2l.config
	-- 是否分析slk文件
	config.read_slk = true
	-- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
	config.find_id_times = 0
	-- 移除与模板完全相同的数据
	config.remove_same = false
	-- 移除超出等级的数据
	config.remove_exceeds_level = false
	-- 补全空缺的数据
	config.remove_nil_value = false
	-- 移除只在WE使用的文件
	config.remove_we_only = false
	-- 移除没有引用的对象
	config.remove_unuse_object = false
	-- 转换为地图还是目录(map, dir)
	config.target_storage = dir
end

local function main()
	set_config()
	-- 生成id_type
	local id_data = w2l:parse_txt(io.load(w2l.mpq / 'ui' / 'uniteditordata.txt'))
	local content = prebuilt_id_type(id_data)
	io.save(w2l.prebuilt / 'id_type.ini', content)

	fs.create_directories(w2l.default)
	fs.create_directories(w2l.template)
	fs.create_directories(w2l.key)

	-- 生成key2id
    for type, slk in pairs(w2l.info['template']['slk']) do
		message('正在生成key2id', type)
		local metadata = w2l:read_metadata(type)
        local template = {}
        for i = 1, #slk do
            add_table(template, w2l:parse_slk(io.load(w2l.mpq / slk[i])))
        end
		local content1, content2 = create_key2id(type, metadata, template)
		io.save(w2l.key / (type .. '.ini'), content1)
		io.save(w2l.key / (type .. '_type.ini'), content2)
	end

	-- 生成模板lni
	local ar = archive(w2l.mpq)
	local slk = {}
	w2l:frontend(ar, slk)
	local usable_para = {}
	for ttype in pairs(w2l.info['template']['slk']) do
		message('正在生成模板', ttype)
		local data = slk[ttype]
		io.save(w2l.default / (ttype .. '.ini'), default2lni(ttype, data))
		io.save(w2l.template / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
		for name, obj in pairs(data) do
			usable_para[obj._id] = true
		end
	end

	-- 生成misc的文件
	local data = slk['misc']
	
	local content1, content2 = create_key2id('misc', w2l:read_metadata 'misc', data)
	io.save(w2l.key / 'misc.ini', content1)
	io.save(w2l.key / 'misc_type.ini', content2)

	io.save(w2l.default / 'txt.ini', default2lni('txt', slk.txt))
	io.save(w2l.template / 'txt.ini', txt2teamplate('txt', slk.txt))

	-- 生成技能命令映射
	--local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'))
	--local order_list = order_prebuilt(skill_data)
	--io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
