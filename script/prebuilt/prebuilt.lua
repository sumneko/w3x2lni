require 'filesystem'
require 'utility'
local w3x2lni  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
local order_prebuilt = require 'order.prebuilt'
local default2lni = require 'prebuilt.default2lni'
local prebuilt_metadata = require 'prebuilt.prebuilt_metadata'
local prebuilt_keydata = require 'prebuilt.prebuilt_keydata'
local prebuilt_search = require 'prebuilt.prebuilt_search'
local prebuilt_miscnames = require 'prebuilt.prebuilt_miscnames'

local w2l = w3x2lni()

local std_print = print
function print(...)
    if select(1, ...) == '-progress' then
        return
    end
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i])):gsub('[\r\n]', ' ')
    end
    std_print(table.concat(tbl, ' '))
end
w2l:set_messager(print)
function w2l:map_load(filename)
    return nil
end

local function prebuilt_codemapped(w2l)
    local template = w2l:parse_slk(w2l:mpq_loader(w2l.info.slk.ability[1]))
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
    io.save(w2l.defined / 'codemapped.ini', table.concat(f, '\r\n'))
end

local function prebuilt_typedefine(w2l)
    local uniteditordata = w2l:parse_txt(io.load(w2l.meta / 'uniteditordata.txt'))
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
    io.save(w2l.defined / 'typedefine.ini', table.concat(f, '\r\n'))
end

local mt = {}

function mt:get_config()
    local config = {}
    -- 转换后的目标格式(lni, obj, slk)
    config.target_format = 'lni'
    -- 使用的语言
    config.lang = 'zh-CN'
    -- 是否分析slk文件
    config.read_slk = true
    -- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
    config.find_id_times = 0
    -- 移除与模板完全相同的数据
    config.remove_same = false
    -- 移除超出等级的数据
    config.remove_exceeds_level = true
    -- 移除只在WE使用的文件
    config.remove_we_only = false
    -- 移除没有引用的对象
    config.remove_unuse_object = false
    -- mdx压缩
    config.mdx_squf = false
    -- 转换为地图还是目录(mpq, dir)
    config.target_storage = 'dir'

    return config
end

function mt:dofile(mpq, version, template)
    print('==================')
    print(('       %s      '):format(version))
    print('==================')

    local config = self:get_config()
    config.mpq     = mpq
    config.version = version
    w2l:set_config(config)
    local prebuilt_path = w2l.root / 'data' / 'prebuilt' / w2l.mpq_path:first_path()
    fs.create_directories(prebuilt_path)

	local slk = w2l:build_slk()
    print('正在生成default')
    for _, ttype in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc', 'txt'} do
        io.save(prebuilt_path / (ttype .. '.ini'), default2lni(slk[ttype]))
    end
    
    if template then
        print('正在生成template')
        for _, ttype in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            local data = w2l:frontend_merge(ttype, slk[ttype], {})
            io.save(w2l.template / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
        end
        io.save(w2l.template / 'txt.ini', w2l:backend_txtlni(slk.txt))
    end
end

function mt:complete()
    fs.create_directories(w2l.template)
    fs.create_directories(w2l.defined)

    prebuilt_codemapped(w2l)
    prebuilt_typedefine(w2l)
    prebuilt_miscnames(w2l)
    prebuilt_metadata(w2l)
    prebuilt_keydata(w2l)
    prebuilt_search(w2l)

    self:dofile('default', 'Melee')
    self:dofile('default', 'Custom', 'template')

    -- 生成技能命令映射
    --local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'), 'ability.ini')
    --local order_list = order_prebuilt(skill_data)
    --io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

    print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

return mt
