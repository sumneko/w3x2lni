require 'filesystem'
require 'utility'
local core  = require 'sandbox_core'
local uni      = require 'ffi.unicode'
local order_prebuilt = require 'order.prebuilt'
local prebuilt_metadata = require 'prebuilt.prebuilt_metadata'
local prebuilt_keydata = require 'prebuilt.prebuilt_keydata'
local prebuilt_search = require 'prebuilt.prebuilt_search'
local prebuilt_miscnames = require 'prebuilt.prebuilt_miscnames'

local root = fs.current_path()
local w2l = core()

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
w2l:set_config{
    mpq     = 'default',
    version = 'Custom',
    lang    = 'ZH-CN',
}

function w2l:mpq_load(filename)
    local mpq_path = root:parent_path() / 'data' / 'mpq'
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

local mt = {}

function mt:dofile(mpq, lang, version, template)
    print('==================')
    print(('  %s  %s  '):format(lang, version))
    print('==================')

    w2l:set_config{
        mpq     = mpq,
        version = version,
        lang    = lang,
    }
    local prebuilt_path = root:parent_path() / 'data' / 'prebuilt' / w2l.mpq_path:first_path()
    fs.create_directories(prebuilt_path)

    print('正在生成default')
    function w2l:prebuilt_save(filename, buf)
        io.save(prebuilt_path / filename, buf)
    end
	local slk = w2l:build_slk()
    
    if template then
        print('正在生成template')
        local template_path = root:parent_path() / 'template'
        for _, ttype in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            local data = w2l:frontend_merge(ttype, slk[ttype], {})
            io.save(template_path / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
        end
        io.save(template_path / 'txt.ini', w2l:backend_txtlni(slk.txt))
    end
end

function mt:complete()
    fs.create_directories(root:parent_path() / 'template')
    fs.create_directories(root / 'core' / 'defined')

    prebuilt_codemapped(w2l)
    prebuilt_typedefine(w2l)
    prebuilt_miscnames(w2l)
    prebuilt_metadata(w2l)
    prebuilt_keydata(w2l)
    prebuilt_search(w2l)

    self:dofile('default', 'zh-CN', 'Melee')
    self:dofile('default', 'zh-CN', 'Custom', 'template')
    self:dofile('default', 'en-US', 'Melee')
    self:dofile('default', 'en-US', 'Custom')

    -- 生成技能命令映射
    --local skill_data = w2l:parse_lni(io.load(w2l.template / 'ability.ini'), 'ability.ini')
    --local order_list = order_prebuilt(skill_data)
    --io.save(w2l.root / 'script' / 'order' / 'order_list.lua', order_list)

    print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

return mt
