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
local config = require 'tool.config' ()

local root = fs.current_path()
local w2l = core()

w2l:set_messager(function (tp, ...)
    if tp == 'progress' then
        return
    end
    print(...)
end)

function w2l:mpq_load(filename)
    local mpq_path = root:parent_path() / 'data' / w2l.config.data_war3 / 'war3'
    return self.mpq_path:each_path(function(path)
        return io.load(mpq_path / path / filename)
    end)
end

function w2l:wes_load(filename)
    local wes_path = root:parent_path() / 'data' / w2l.config.data_wes / 'we'
    return io.load(wes_path / filename)
end

local function get_codemapped(w2l)
    local template = w2l:parse_slk(io.load(root:parent_path() / 'data' / w2l.config.data_war3 / 'war3' / 'units' / 'abilitydata.slk'))
    local t = {}
    for id, d in pairs(template) do
        t[id] = d.code
    end
    return t
end

local function get_typedefine(w2l)
    local uniteditordata = w2l:parse_txt(io.load(root / 'meta' / 'uniteditordata.txt'))
    local t = {
        int    = 0,
        bool   = 0,
        real   = 1,
        unreal = 2,
    }
    for key, data in pairs(uniteditordata) do
        local value = data['00'][1]
        local tp
        if tonumber(value) then
            tp = 0
        else
            tp = 3
        end
        t[key] = tp
    end
    return t
end

local function loader(name)
    return io.load(root / 'meta' / name)
end

local function main()
    fs.create_directories(root:parent_path() / 'template')
    fs.create_directories(root / 'core' / 'defined')

    local codemapped = get_codemapped(w2l)
    local typedefine = get_typedefine(w2l)

    local meta = prebuilt_metadata(w2l, nil, codemapped, typedefine, loader)
    io.save(fs.current_path() / 'core' / 'defined' / 'metadata.ini', meta)

    config.global.lang = "${AUTO}"
    config.global.data_ui = "${YDWE}"
    config.global.data_meta = "${DEFAULT}"
    config.global.data_wes = "${YDWE}"

    config.global.data_war3 = "zhCN-1.24.4"
    local slk_melee  = makefile(w2l, 'Melee')
    local slk_custom = makefile(w2l, 'Custom')
    
    config.global.data_war3 = "enUS-1.27.1"
    makefile(w2l, 'Melee')
    makefile(w2l, 'Custom')

    config.global.data_war3 = "zhCN-1.24.4"
    maketemplate(w2l, 'Melee',  slk_melee)
    maketemplate(w2l, 'Custom', slk_custom)

    -- 生成技能命令映射
    --local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'), 'ability.ini')
    --local order_list = order_prebuilt(skill_data)
    --io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

    print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
