(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w2l  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
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


local function main()
	-- 生成id_type
	local id_data = w2l:parse_txt(io.load(w2l.mpq / 'ui' / 'uniteditordata.txt'))
	local content = prebuilt_id_type(id_data)
	io.save(w2l.prebuilt / 'id_type.ini', content)

	-- 生成key2id
    for type, meta in pairs(w2l.info['metadata']) do
		message('正在生成key2id', type)
		local metadata = w2l:read_metadata(type)
        local slk = w2l.info['template']['slk'][type]
        local template = {}
        for i = 1, #slk do
            add_table(template, w2l:parse_slk(io.load(w2l.mpq / slk[i])))
        end
		local content1, content2 = create_key2id(type, metadata, template)
		io.save(w2l.key / (type .. '.ini'), content1)
		io.save(w2l.key / (type .. '_type.ini'), content2)
	end

	-- 生成模板lni
	fs.create_directories(w2l.default)
	fs.create_directories(w2l.template)
	local usable_para = {}
	local datas, txt = w2l:frontend_slk({}, function(name)
		return io.load(w2l.mpq / name)
	end)
	for ttype in pairs(w2l.info['metadata']) do
		message('正在生成模板', ttype)
		local data = datas[ttype]
		io.save(w2l.default / (ttype .. '.ini'), default2lni(ttype, data))
		io.save(w2l.template / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
		for name, obj in pairs(data) do
			usable_para[obj._id] = true
		end
	end
	io.save(w2l.prebuilt / 'usable_para.ini', pack_table(usable_para))
	io.save(w2l.default / 'txt.ini', default2lni('txt', txt))
	io.save(w2l.template / 'txt.ini', txt2teamplate('txt', txt))

	-- 生成技能命令映射
	--local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'))
	--local order_list = order_prebuilt(skill_data)
	--io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
