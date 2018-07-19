require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local core = require 'backend.sandbox_core'
local root = require 'backend.w2l_path'
local config = require 'share.config'

local slk_keys = {
    ['units\\abilitydata.slk']      = {
        'alias','code','Area1','Area2','Area3','Area4','BuffID1','BuffID2','BuffID3','BuffID4','Cast1','Cast2','Cast3','Cast4','checkDep','Cool1','Cool2','Cool3','Cool4','Cost1','Cost2','Cost3','Cost4','DataA1','DataA2','DataA3','DataA4','DataB1','DataB2','DataB3','DataB4','DataC1','DataC2','DataC3','DataC4','DataD1','DataD2','DataD3','DataD4','DataE1','DataE2','DataE3','DataE4','DataF1','DataF2','DataF3','DataF4','DataG1','DataG2','DataG3','DataG4','DataH1','DataH2','DataH3','DataH4','DataI1','DataI2','DataI3','DataI4','Dur1','Dur2','Dur3','Dur4','EfctID1','EfctID2','EfctID3','EfctID4','HeroDur1','HeroDur2','HeroDur3','HeroDur4','levels','levelSkip','priority','reqLevel','Rng1','Rng2','Rng3','Rng4','targs1','targs2','targs3','targs4','UnitID1','UnitID2','UnitID3','UnitID4',
    },
    ['units\\abilitybuffdata.slk']  = {
        'alias',
    },
    ['units\\destructabledata.slk'] = {
        'DestructableID','armor','cliffHeight','colorB','colorG','colorR','deathSnd','fatLOS','file','fixedRot','flyH','fogRadius','fogVis','HP','lightweight','maxPitch','maxRoll','maxScale','minScale','MMBlue','MMGreen','MMRed','Name','numVar','occH','pathTex','pathTexDeath','portraitmodel','radius','selcircsize','selectable','shadow','showInMM','targType','texFile','texID','tilesetSpecific','useMMColor','walkable',
    },
    ['units\\itemdata.slk']         = {
        'itemID','abilList','armor','class','colorB','colorG','colorR','cooldownID','drop','droppable','file','goldcost','HP','ignoreCD','Level','lumbercost','morph','oldLevel','pawnable','perishable','pickRandom','powerup','prio','scale','sellable','stockMax','stockRegen','stockStart','usable','uses',
    },
    ['units\\upgradedata.slk']      = {
        'upgradeid','base1','base2','base3','base4','class','code1','code2','code3','code4','effect1','effect2','effect3','effect4','global','goldbase','goldmod','inherit','lumberbase','lumbermod','maxlevel','mod1','mod2','mod3','mod4','timebase','timemod', 'used',
    },
    ['units\\unitabilities.slk']    = {
        'unitAbilID','abilList','auto','heroAbilList',
    },
    ['units\\unitbalance.slk']      = {
        'unitBalanceID','AGI','AGIplus','bldtm','bountydice','bountyplus','bountysides','collision','def','defType','defUp','fmade','fused','goldcost','goldRep','HP','INT','INTplus','isbldg','level','lumberbountydice','lumberbountyplus','lumberbountysides','lumbercost','lumberRep','mana0','manaN','maxSpd','minSpd','nbrandom','nsight','preventPlace','Primary','regenHP','regenMana','regenType','reptm','repulse','repulseGroup','repulseParam','repulsePrio','requirePlace','sight','spd','stockMax','stockRegen','stockStart','STR','STRplus','tilesets','type','upgrades',
    },
    ['units\\unitdata.slk']         = {
        'unitID','buffRadius','buffType','canBuildOn','canFlee','canSleep','cargoSize','death','deathType','fatLOS','formation','isBuildOn','moveFloor','moveHeight','movetp','nameCount','orientInterp','pathTex','points','prio','propWin','race','requireWaterRadius','targType','turnRate',
    },
    ['units\\unitui.slk']           = {
        'unitUIID','name','armor','blend','blue','buildingShadow','customTeamColor','elevPts','elevRad','file','fileVerFlags','fogRad','green','hideHeroBar','hideHeroDeathMsg','hideHeroMinimap','hideOnMinimap','maxPitch','maxRoll','modelScale','nbmmIcon','occH','red','run','scale','scaleBull','selCircOnWater','selZ','shadowH','shadowOnWater','shadowW','shadowX','shadowY','teamColor','tilesetSpecific','uberSplat','unitShadow','unitSound','walk',
    },
    ['units\\unitweapons.slk']      = {
        'unitWeapID','acquire','atkType1','atkType2','backSw1','backSw2','castbsw','castpt','cool1','cool2','damageLoss1','damageLoss2','dice1','dice2','dmgplus1','dmgplus2','dmgpt1','dmgpt2','dmgUp1','dmgUp2','Farea1','Farea2','Harea1','Harea2','Hfact1','Hfact2','impactSwimZ','impactZ','launchSwimZ','launchX','launchY','launchZ','minRange','Qarea1','Qarea2','Qfact1','Qfact2','rangeN1','rangeN2','RngBuff1','RngBuff2','showUI1','showUI2','sides1','sides2','spillDist1','spillDist2','spillRadius1','spillRadius2','splashTargs1','splashTargs2','targCount1','targCount2','targs1','targs2','weapsOn','weapTp1','weapTp2','weapType1','weapType2',
    },
    ['doodads\\doodads.slk']        = {
        'doodID','file','Name','doodClass','soundLoop','selSize','defScale','minScale','maxScale','maxPitch','maxRoll','visRadius','walkable','numVar','floats','shadow','showInFog','animInFog','fixedRot','pathTex','showInMM','useMMColor','MMRed','MMGreen','MMBlue','vertR01','vertG01','vertB01','vertR02','vertG02','vertB02','vertR03','vertG03','vertB03','vertR04','vertG04','vertB04','vertR05','vertG05','vertB05','vertR06','vertG06','vertB06','vertR07','vertG07','vertB07','vertR08','vertG08','vertB08','vertR09','vertG09','vertB09','vertR10','vertG10','vertB10',
    },
}

local mt = {}
mt.__index = mt

local function find_txt(buf, id)
    local start = buf:find('%['..id..'%]')
    if not start then
        return nil
    end
    local stop = buf:find('%c+%[')
    return buf:sub(start, stop)
end

function mt:load_obj(w2l, type, id, path)
    local w2l = self:w3x2lni()

    local target_name = w2l.info.obj[type]
    function w2l.input_ar:get(filename)
        if filename == target_name then
            return io.load(path / filename)
        end
    end

    w2l:frontend()
    return { obj = w2l.slk[type][id], type = 'obj' }
end

function mt:load_lni(w2l, type, id, path)
    local target_name = w2l.info.lni[type]
    function w2l.input_ar:get(filename)
        if filename == 'table\\' .. target_name then
            return io.load(path / target_name)
        end
    end

    w2l:frontend()
    return { obj = w2l.slk[type][id], type = 'lni' }
end

function mt:load_slk(w2l, type, id, path)
    w2l.setting.read_slk = true
    local enable_keys = {}
    local function pack_keys(filename)
        if not slk_keys[filename] then
            return
        end
        for _, key in ipairs(slk_keys[filename]) do
            enable_keys[key] = true
        end
    end

    local target_names = {}
    for _, name in ipairs(w2l.info.txt) do
        target_names[name] = name:sub(7)
    end
    for _, name in ipairs(w2l.info.slk[type]) do
        target_names[name] = name:sub(7)
    end
    
    function w2l.input_ar:get(filename)
        if target_names[filename] then
            pack_keys(filename)
            return io.load(path / target_names[filename])
        end
    end

    w2l:frontend()
    return { obj = w2l.slk[type][id], type = 'slk', keys = enable_keys }
end

function mt:load_all(w2l, type, id, path, setting)
    function w2l.input_ar:get(filename)
        return io.load(path / filename)
    end
    
    w2l:frontend()
    return { obj = w2l.slk[type][id], type = 'all' }
end

local function save_obj(w2l, type, id, path)
    local lni_name = w2l.info.obj[type]
    local obj = { obj = nil, type = 'obj' }
    function w2l.output_ar:set(filename, buf)
        if filename == lni_name then
            if type == 'misc' then
                local txt = find_txt(buf, id)
                if txt then
                    obj.obj = txt
                end
            else
                obj.obj = buf
            end
        end
    end

    w2l:backend()

    return obj
end

local function save_lni(w2l, type, id, path)
    local obj = { lni = nil, type = 'lni' }
    function w2l:file_save(tp, name, buf)
        if tp == 'table' and name == type then
            local txt = find_txt(buf, id)
            if txt then
                obj.lni = txt
            end
        end
    end

    w2l:backend()

    return obj
end

local function save_slk(w2l, type, id, path)
    local txt_names = {}
    for _, name in ipairs(w2l.info.txt) do
        txt_names[name] = name:sub(7)
    end
    local slk_names = {}
    for _, name in ipairs(w2l.info.slk[type] or {}) do
        slk_names[name] = name:sub(7)
    end
    local obj_name = w2l.info.obj[type]

    local obj = { slk = nil, txt = nil, type = 'slk' }
    function w2l.output_ar:set(filename, buf)
        if slk_names[filename] then
        elseif txt_names[filename] then
            local txt = find_txt(buf, id)
            if txt then
                obj.txt = txt
            end
        elseif filename == obj_name then
            obj.obj = buf
        end
    end
    
    w2l:backend()

    return obj
end

local function eq(v1, v2, enable_keys)
    for k in pairs(v1) do
        if k:sub(1, 1) == '_' then
            goto CONTINUE
        end
        if enable_keys and not enable_keys[k] then
            goto CONTINUE
        end
        if type(v1[k]) ~= type(v2[k]) then
            return false, ('[%s] - [%s](%s):[%s](%s)'):format(k, v1[k], type(v1[k]), v2[k], type(v2[k]))
        end
        if type(v1[k]) == 'table' then
            if #v1[k] ~= #v2[k] then
                return false, ('[%s] - #%s:#%s'):format(k, #v1[k], #v2[k])
            end
            for i = 1, #v1[k] do
                if v1[k][i] ~= v2[k][i] then
                    return false, ('[%s][%s] - [%s](%s):[%s](%s)'):format(k, #v1[k], v1[k][i], type(v1[k][i]), v2[k][i], type(v2[k][i]))
                end
            end
        else
            if v1[k] ~= v2[k] then
                return false, ('[%s] - [%s](%s):[%s](%s)'):format(k, v1[k], type(v1[k]), v2[k], type(v2[k]))
            end
        end
        ::CONTINUE::
    end
    return true
end

local function eq_test(v1, v2, enable_keys, callback)
    local ok, msg = eq(v1, v2, enable_keys)
    if ok then
        return
    end
    callback(msg)
end

local function trim(str)
    if not str then
        return nil
    end
    str = str:gsub('\r\n', '\n'):gsub('[\n]+', '\n')
    if str:sub(-1) == '\n' then
        str = str:sub(1, -2)
    end
    if str:sub(1, 1) == '\n' then
        str = str:sub(2)
    end
    return str
end

function mt:w3x2lni()
    local w2l = core()

    w2l.input_ar = {
        get = function ()
        end,
        set = function ()
        end,
        remove = function ()
        end,
    }
    w2l.output_ar = {
        get = function ()
        end,
        set = function ()
        end,
        remove = function ()
        end,
    }
    local set_setting = w2l.set_setting
    function w2l.set_setting(self, data)
        data = data or {}
        local setting = {}
        for k, v in pairs(config.global) do
            setting[k] = v
        end
        if config[data.mode] then
            for k, v in pairs(config[data.mode]) do
                setting[k] = v
            end
        end
        for k, v in pairs(data) do
            setting[k] = v
        end
        set_setting(self, setting)
    end
    w2l:set_setting()
    
    return w2l
end

function mt:init(type, id)
    self._type = type
    self._id = id
end

function mt:load(mode, setting)
    local w2l = self:w3x2lni()
    local name = self._path:filename():string()
    local dump
    setting = setting or {}
    w2l:set_setting(setting)

    if mode == 'obj' then
        dump = self:load_obj(w2l, self._type, self._id, self._path)
    elseif mode == 'lni' then
        dump = self:load_lni(w2l, self._type, self._id, self._path)
    elseif mode == 'slk' then
        dump = self:load_slk(w2l, self._type, self._id, self._path)
    elseif mode == 'all' then
        dump = self:load_all(w2l, self._type, self._id, self._path)
    end
    assert(dump.obj, ('\n\n<%s>[%s.%s] 没有读取到%s'):format(name, self._type, self._id, mode))
    return dump
end

function mt:save(mode, dump, setting)
    local w2l = self:w3x2lni()
    local name = self._path:filename():string()
    local slk
    setting = setting or {}
    setting.mode = mode
    
    w2l:set_setting(setting)
    w2l.slk = {}
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'destructable', 'doodad', 'misc', 'txt'} do
        w2l.slk[type] = {}
    end
    w2l.slk[self._type] = { [self._id] = dump.obj }

    if mode == 'obj' then
        slk = save_obj(w2l, self._type, self._id, self._path)
    elseif mode == 'lni' then
        slk = save_lni(w2l, self._type, self._id, self._path)
    elseif mode == 'slk' then
        slk = save_slk(w2l, self._type, self._id, self._path)
    end
    assert(slk.slk or slk.txt or slk.obj or slk.lni, ('\n\n<%s>[%s.%s] 没有保存为%s'):format(name, self._type, self._id, mode))
    
    return slk
end

function mt:read(filename)
    return io.load(self._path / filename)
end

function mt:compare_string(str1, str2)
    local name = self._path:filename():string()
    assert(trim(str1) == trim(str2), ('\n\n<%s>[%s.%s] 文本不同：\n\n%s\n'):format(name, self._type, self._id, trim(str1)))
end

function mt:compare_value(v1, v2)
    local name = self._path:filename():string()
    assert(v1 == v2, ('\n\n<%s>[%s.%s] 值不同：\n\n%s\n'):format(name, self._type, self._id, v1))
end

function mt:compare_dump(dump1, dump2)
    local name = self._path:filename():string()
    eq_test(dump1.obj, dump2.obj, dump1.keys or dump2.keys, function (msg)
        error(('\n\n<%s>[%s.%s]\n%s 与 %s 不等：%s'):format(name, self._type, self._id, dump1.type, dump2.type, msg))
    end)
end

local function test_env(path)
    local o = setmetatable({ _path = path }, mt)
    return setmetatable({}, {
        __index = function (self, k)
            local f = o[k]
            if not f then
                return _G[k]
            end
            return function (...)
                return f(o, ...)
            end
        end,
    })
end

local function do_test(path)
    local buf = io.load(path / 'test.lua')
    if not buf then
        return false
    end
    print(('正在测试[%s]'):format(path:filename():string()))
    local debuggerpath = '@'..(path / 'test.lua'):string()
    local env = test_env(path)
    local f = assert(load(buf, debuggerpath, 't', env))
    f()
    return true
end

local test_dir = root / 'test' / 'unit_test'
if arg[1] then
    do_test(test_dir / arg[1])
    print('指定的单元测试完成:' .. arg[1])
else
    local count = 0
    for path in test_dir:list_directory() do
        local suc = do_test(path)
        if not suc then
            error(('单元测试[%s]执行失败'):format(path:stem():string()))
        end
        count = count + 1
    end
    if count == 0 then
        error('没有执行任何单元测试')
    end
    print(('单元测试完成，共测试[%d]个'):format(count))
end
