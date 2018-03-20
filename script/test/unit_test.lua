require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local core = require 'tool.sandbox_core'

local std_print = print
local std_error = error
local function print(...)
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i]))
    end
    std_print(table.unpack(tbl))
end

local function assert(ok, msg, ...)
    if ok then
        return ok, msg, ...
    end
    std_error(uni.u2a(msg), 2)
end

local function error(msg)
    std_error(uni.u2a(msg), 2)
end

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

local function add_loader(w2l)
    local mpq_path = fs.current_path():parent_path() / 'data' / 'mpq'
    local prebuilt_path = fs.current_path():parent_path() / 'data' / 'prebuilt'

    function w2l:mpq_load(filename)
        return w2l.mpq_path:each_path(function(path)
            return io.load(mpq_path / path / filename)
        end)
    end
    
    function w2l:prebuilt_load(filename)
        return w2l.mpq_path:each_path(function(path)
            return io.load(prebuilt_path / path / filename)
        end)
    end
end

local function load_obj(type, id, path)
    local w2l = core()

    add_loader(w2l)

    local target_name = w2l.info.obj[type]
    function w2l:map_load(filename)
        if filename == target_name then
            return io.load(path / filename)
        end
    end

    w2l:frontend()
    return { w2l.slk[type][id], 'obj' }
end

local function load_lni(type, id, path)
    local w2l = core()

    add_loader(w2l)

    local target_name = w2l.info.lni[type]
    function w2l:map_load(filename)
        if filename == target_name then
            return io.load(path / (type .. '.ini'))
        end
    end

    w2l:frontend()
    return { w2l.slk[type][id], 'lni' }
end

local function load_slk(type, id, path)
    local w2l = core()

    add_loader(w2l)

    w2l:set_config {
        read_slk = true,
    }

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
    
    function w2l:map_load(filename)
        if target_names[filename] then
            pack_keys(filename)
            return io.load(path / target_names[filename])
        end
    end

    w2l:frontend()
    return { w2l.slk[type][id], 'slk', enable_keys }
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

local mt = {}
mt.__index = mt

function mt:init(type, id)
    self._type = type
    self._id = id
end

function mt:load(mode)
    local name = self._path:filename():string()
    local dump
    if mode == 'obj' then
        dump = load_obj(self._type, self._id, self._path)
    elseif mode == 'lni' then
        dump = load_obj(self._type, self._id, self._path)
    elseif mode == 'slk' then
        dump = load_slk(self._type, self._id, self._path)
    end
    assert(dump, ('\n\n<%s>[%s.%s] 没有读取到%s'):format(name, self._type, self._id, mode))
    return dump
end

function mt:compare_dump(dump1, dump2)
    local name = self._path:filename():string()
    eq_test(dump1[1], dump2[1], dump1[3] or dump2[3], function (msg)
        error(('\n\n<%s>[%s.%s]\n%s 与 %s 不等：%s'):format(name, self._type, self._id, dump1[2], dump2[2], msg))
    end)
end

local function test_env(path)
    local o = setmetatable({ _path = path }, mt)
    return setmetatable({}, {
        __index = function (self, k)
            local f = o[k]
            if not f then
                return nil
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
        return
    end
    assert(load(buf, '@'..uni.u2a((path / 'test.lua'):string()), 't', test_env(path)))()
end

local test_dir = fs.current_path() / 'test' / 'unit_test'
for path in test_dir:list_directory() do
    do_test(path)
end

print('单元测试完成')
