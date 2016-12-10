(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w2l  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
local order_prebuilt = require 'order.prebuilt'
local table2lni = require 'table2lni'

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

local function add_table(t1, t2)
    for k, v in pairs(t2) do
        if type(t1[k]) == 'table' and type(v) == 'table' then
            add_table(t1[k], v)
        else
            t1[k] = v
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
	lines[#lines+1] = '[root]'
	for name, value in pairs(tbl) do
		lines[#lines+1] = ('%s=%s'):format(name, value)
	end
	table.sort(lines)
	return '[root]\r\n' .. table.concat(lines, '\r\n')
end


local function main()
	w2l:init()

	-- 生成id_type
	local id_data = w2l:parse_txt(io.load(w2l.mpq / 'ui' / 'uniteditordata.txt'))
	local content = prebuilt_id_type(id_data)
	io.save(w2l.prebuilt / 'id_type.ini', content)

	-- 生成key2id
	for _, type in ipairs(w2l.info.object) do
		local info = w2l.info[type]
		message('正在生成key2id', info.obj)
		local metadata = w2l:read_metadata(info)
        local template = {}
        for i = 1, #info.slk do
            add_table(template, w2l:parse_slk(io.load(w2l.mpq / info.slk[i])))
        end
		local content = w2l:key2id(info.obj, metadata, template)
		io.save(w2l.key / info.lni, content)
	end

	-- 生成模板lni
	fs.create_directories(w2l.default)
	fs.create_directories(w2l.template)
	local usable_code = {}
	for _, type in ipairs(w2l.info.object) do
		local info = w2l.info[type]
		message('正在生成模板', info.obj)
		local data = w2l:slk_loader(info, io.load, function(name)
			return io.load(w2l.mpq / name)
		end)
		io.save(w2l.default / info.lni, table2lni(data))
		io.save(w2l.template / info.lni, w2l:to_lni(info, data, io.load))
		for name in pairs(data) do
			usable_code[name] = true
		end
	end
	io.save(w2l.prebuilt / 'usable_code.ini', pack_table(usable_code))

	-- 生成技能命令映射
	local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'))
	local order_list = order_prebuilt(skill_data)
	io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
