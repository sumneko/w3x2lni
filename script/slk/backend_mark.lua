local std_type = type
local mustuse =  {
    ability = { 'avul','adda','aalr','aatk','anbu','ahbu','aobu','aebu','aubu','agbu','abdt','argd','aher','arev','aral','amnz','acsp','sloa','aetl','amov','afir','afih','afio','afin','afiu' },
    buff = { 'bpse','bstn','btlf','bdet','bvul','bspe','bfro','bsha','btrv','bbar','xbdt','xbli','xdis','xfhs','xfhm','xfhl','xfos','xfom','xfol','xfns','xfnm','xfnl','xfus','xfum','xful','bchd','bmil','bpxf','bphx','bhav','barm','bens','bstt','bcor','buns','bust','biwb','xesn','bivs','buad' },
    destructable = { 'volc' },
}

local mustmark = {
Asac = { 'ushd', 'unit' },
Alam = { 'ushd', 'unit' },
Aspa = { 'bspa', 'buff' },
}

local slk
local search
local mark_known_type
local once = {}
local current_root = {'', '%s%s'}

local function slk_object_name(o)
    if o._type == 'buff' then
        return o.bufftip or o.editorname or ''
    elseif o._type == 'upgrade' then
        return o.name[1] or ''
    else
        return o.name or ''
    end
end

local function slk_all(slk, id)
    id = id:lower()
    return slk.ability[id]
           or slk.unit[id]
           or slk.buff[id]
           or slk.item[id]
           or slk.destructable[id]
           or slk.doodad[id]
           or slk.upgrade[id]
end

local function format_marktip(slk, marktip)
    local p = slk_all(slk, marktip[1])
    if not p then
        return marktip[2]:format('<unknown>', marktip[1])
    end
    return marktip[2]:format(slk_object_name(p), p._id)
end

local function split(str)
    local r = {}
    str:gsub('[^,]+', function (w) r[#r+1] = w:lower() end)
    return r
end

local function print(id)
    if once[id] then
        return
    end
    once[id] = true
    message('-report', '简化时没有找到对象:', id)
    message('-tip', format_marktip(slk, current_root))
end

local function mark_value(slk, type, value)
    if type == 'upgrade,unit' then
        if std_type(value) == 'string' then
            for _, name in ipairs(split(value)) do
                if not mark_known_type(slk, 'unit', name) then
                    if not mark_known_type(slk, 'upgrade', name) then
                        if not mark_known_type(slk, 'misc', name) then
                            print(name)
                        end
                    end
                end
            end
        else
            if not mark_known_type(slk, 'unit', value) then
                if not mark_known_type(slk, 'upgrade', value) then
                    if not mark_known_type(slk, 'misc', value) then
                        print(value)
                    end
                end
            end
        end
        return
    end
    if std_type(value) == 'string' then
        for _, name in ipairs(split(value)) do
            if not mark_known_type(slk, type, name) then
                print(name)
            end
        end
    else
        if not mark_known_type(slk, type, value) then
            print(value)
        end
    end
end

local function mark_list(slk, o, list)
    if not list then
        return
    end
    for key, type in pairs(list) do
        local value = o[key]
        if not value then
        elseif std_type(value) == 'table' then
            for _, name in ipairs(value) do
                mark_value(slk, type, name)
            end
        else
            mark_value(slk, type, value)
        end
    end
end

function mark_known_type(slk, type, name)
    name = name:lower()
    local o = slk[type][name]
    if not o then
        if slk.txt[name] then
            slk.txt[name]._mark = current_root
            return true
        end
        return false
    end
    if o._mark then
        return true
    end
    o._mark = current_root
    mark_list(slk, o, search[type].common)
    mark_list(slk, o, search[type][o._code])
    local marklist = mustmark[o._code]
    if marklist then
        if not mark_known_type(slk, marklist[2], marklist[1]) then
            print(marklist[1])
        end
    end
    return true
end

local function mark_mustuse(slk)
    for type, list in pairs(mustuse) do
        for _, name in ipairs(list) do
            current_root = {name, "必须保留的'%s'[%s]引用了它"}
            if not mark_known_type(slk, type, name) then
                print(name)
            end
        end
    end
end

local function mark(slk, name)
    name = name:lower()
    mark_known_type(slk, 'ability', name)
    mark_known_type(slk, 'unit', name)
    mark_known_type(slk, 'buff', name)
    mark_known_type(slk, 'item', name)
    mark_known_type(slk, 'destructable', name)
    mark_known_type(slk, 'doodad', name)
    mark_known_type(slk, 'upgrade', name)
end

local function mark_jass(slk, list, flag)
    if list then
        for name in pairs(list) do
            current_root = {name, "脚本里的'%s'[%s]引用了它"}
            mark(slk, name)
        end
    end
    if flag.creeps or flag.building then
        local maptile = slk.w3i.map_main_ground_type
        local search_marketplace = flag.marketplace and flag.item
        flag.marketplace = nil
        for _, obj in pairs(slk.unit) do
            local need_mark = false
            if obj.race == 'creeps' and obj.tilesets and (obj.tilesets == '*' or obj.tilesets:find(maptile)) then
                if flag.building and obj.isbldg == 1 and obj.nbrandom == 1 then
                    current_root = {obj._id, "保留的野怪建筑'%s'[%s]引用了它"}
                    mark_known_type(slk, 'unit', obj._id)
                elseif flag.creeps and obj.isbldg == 0 then
                    current_root = {obj._id, "保留的野怪单位'%s'[%s]引用了它"}
                    mark_known_type(slk, 'unit', obj._id)
                end
            end
            if search_marketplace and obj._name == 'marketplace' then
                flag.marketplace = true
                search_marketplace = false
                message('-report', '保留市场物品')
                message('-tip', ("使用了市场'%s'[%s]"):format(obj.name, obj._id))
            end
        end
    end
    if flag.item then
        for _, obj in pairs(slk.item) do
            if obj.pickRandom == 1 then
                current_root = {obj._id, "保留的随机物品'%s'[%s]引用了它"}
                mark_known_type(slk, 'item', obj._id)
            end
        end
    elseif flag.marketplace then
        for _, obj in pairs(slk.item) do
            if obj.pickRandom == 1 and obj.sellable == 1 then
                current_root = {obj._id, "保留的市场物品'%s'[%s]引用了它"}
                mark_known_type(slk, 'item', obj._id)
            end
        end
    end
end

local function mark_doo(w2l, archive, slk)
    local destructable, doodad = w2l:backend_searchdoo(archive)
    if not destructable then
        return
    end
    for name in pairs(destructable) do
        current_root = {name, "地图上放置的'%s'[%s]引用了它"}
        if not mark_known_type(slk, 'destructable', name) then
            mark_known_type(slk, 'doodad', name)
        end
    end
    for name in pairs(doodad) do
        current_root = {name, "地图上放置的'%s'[%s]引用了它"}
        mark_known_type(slk, 'doodad', name)
    end
end

local function mark_lua(w2l, archive, slk)
    local buf = archive:get('reference.lua')
    if not buf then
        return
    end
    local env = {
        archive  = archive,
        assert   = assert,
        error    = error,
        ipairs   = ipairs,
        load     = load,
        pairs    = pairs,
        next     = next,
        print    = print,
        select   = select,
        tonumber = tonumber,
        tostring = tostring,
        type     = type,
        pcall    = pcall,
        xpcall   = xpcall,
        math     = math,
        string   = string,
        table    = table,
        utf8     = utf8,
    }
    local f, e = load(buf, 'reference.lua', 't', env)
    if not f then
        print(e)
        return
    end
    local suc, list = pcall(f)
    if not suc then
        print(list)
        return
    end
    if type(list) ~= 'table' then
        return
    end
    for name in pairs(list) do
        current_root = {name, "reference.lua指定保留的'%s'[%s]引用了它"}
        mark(slk, name)
    end
end

return function(w2l, archive, slk_)
    slk = slk_
    if not search then
        search = {}
        for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            search[type] = w2l:parse_lni(assert(io.load(w2l.prebuilt / 'search' / (type .. '.ini'))))
        end
    end
    slk.mustuse = mustuse
    local jasslist, jassflag = w2l:backend_searchjass(archive)
    mark_mustuse(slk)
    mark_jass(slk, jasslist, jassflag)
    mark_doo(w2l, archive, slk)
    mark_lua(w2l, archive, slk)
end
