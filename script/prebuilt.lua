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
    lines[#lines+1] = '[root]'
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

    return table.concat(lines, '\r\n')
end


local function main()
	w2l:init()

	-- 生成id_type
	local id_data = w2l:parse_txt(io.load(w2l.mpq / 'ui' / 'uniteditordata.txt'))
	local content = prebuilt_id_type(id_data)
	io.save(w2l.root / 'script' / 'prebuilt' / 'id_type.ini', content)

	-- 生成key2id
    for file_name, meta in pairs(w2l.info['metadata']) do
		message('正在生成key2id', file_name)
		local metadata = w2l:read_metadata(w2l.mpq / meta, io.load)
        local slk = w2l.info['template']['slk'][file_name]
        local template = {}
        for i = 1, #slk do
            add_table(template, w2l:parse_slk(io.load(w2l.mpq / slk[i])))
        end
		local content = w2l:key2id(file_name, metadata, template)
		io.save(w2l.key / (file_name .. '.ini'), content)
	end

	-- 生成模板lni
	fs.create_directories(w2l.default)
	fs.create_directories(w2l.template)
	for file_name, meta in pairs(w2l.info['metadata']) do
		message('正在生成模板', file_name)
		local data = w2l:slk_loader(file_name, io.load, function(name)
			return io.load(w2l.mpq / name)
		end)
		w2l:post_process(file_name, data, io.load)
		io.save(w2l.default / (file_name .. '.ini'), table2lni(data))
		io.save(w2l.template / (file_name .. '.ini'), w2l:to_lni(file_name, data, io.load))
		local t = w2l:parse_lni(io.load(w2l.default / (file_name .. '.ini')))
		print(t)
	end

	-- 生成技能命令映射
	local skill_data = w2l:parse_lni(io.load(w2l.template / 'war3map.w3a.ini'))
	local order_list = order_prebuilt(skill_data)
	io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

	message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
