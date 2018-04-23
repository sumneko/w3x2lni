require 'filesystem'

fs.current_path(fs.path 'script')

require 'utility'
local makefile = require 'prebuilt.makefile'
local core  = require 'backend.sandbox_core'
local uni      = require 'ffi.unicode'
local order_prebuilt = require 'order.prebuilt'
local prebuilt_metadata = require 'prebuilt.metadata'
local prebuilt_keydata = require 'prebuilt.keydata'
local prebuilt_search = require 'prebuilt.search'
local maketemplate = require 'prebuilt.maketemplate'

local root = fs.current_path()
local w2l = core()

w2l:set_messager(function (tp, ...)
    if tp == 'progress' then
        return
    end
    print(...)
end)

function w2l:mpq_load(filename)
    local mpq_path = root:parent_path() / 'data' / w2l.config.mpq / 'mpq'
    return self.mpq_path:each_path(function(path)
        return io.load(mpq_path / path / filename)
    end)
end

local function prebuilt_codemapped(w2l)
    local info     = w2l:parse_lni(assert(io.load(root / 'core'/ 'info.ini')), 'info')
    local template = w2l:parse_slk(w2l:mpq_load(info.slk.ability[1]))
    local t = {}
    for id, d in pairs(template) do
        t[id] = d.code
    end
    local f = {}
    for k, v in pairs(t) do
        f[#f+1] = ('%s = %s'):format(k, v)
    end
    table.sort(f)
    table.insert(f, 1, '[root]')
    io.save(root / 'core' / 'defined' / 'codemapped.ini', table.concat(f, '\r\n'))
end

local function prebuilt_typedefine(w2l)
    local uniteditordata = w2l:parse_txt(io.load(root / 'meta' / 'uniteditordata.txt'))
    local f = {}
    f[#f+1] = ('%s = %s'):format('int', 0)
    f[#f+1] = ('%s = %s'):format('bool', 0)
    f[#f+1] = ('%s = %s'):format('real', 1)
    f[#f+1] = ('%s = %s'):format('unreal', 2)
    for key, data in pairs(uniteditordata) do
        local value = data['00'][1]
        local tp
        if tonumber(value) then
            tp = 0
        else
            tp = 3
        end
        f[#f+1] = ('%s = %s'):format(key, tp)
    end
    table.sort(f)
    table.insert(f, 1, '[root]')
    io.save(root / 'core' / 'defined' / 'typedefine.ini', table.concat(f, '\r\n'))
end

local function main()
    fs.create_directories(root:parent_path() / 'template')
    fs.create_directories(root / 'core' / 'defined')

    prebuilt_codemapped(w2l)
    prebuilt_typedefine(w2l)
    prebuilt_metadata(w2l)
    prebuilt_keydata(w2l)
    prebuilt_search(w2l)

    makefile(w2l, 'zhCN-1.24.4', 'Melee')
    makefile(w2l, 'zhCN-1.24.4', 'Custom')
    makefile(w2l, 'enUS-1.27.1', 'Melee')
    makefile(w2l, 'enUS-1.27.1', 'Custom')
    maketemplate(w2l, 'zhCN-1.24.4', 'Melee')
    maketemplate(w2l, 'zhCN-1.24.4', 'Custom')

    -- 生成技能命令映射
    --local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'), 'ability.ini')
    --local order_list = order_prebuilt(skill_data)
    --io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

    print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
