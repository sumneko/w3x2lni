local std_type = type
local mustuse =  {
    ability = { 'avul','adda','aalr','aatk','anbu','ahbu','aobu','aebu','aubu','agbu','abdt','argd','aher','arev','aral','amnz','acsp','sloa','aetl','amov','afir','afih','afio','afin','afiu' },
    buff = { 'bpse','bstn','btlf','bdet','bvul','bspe','bfro','bsha','btrv','bbar','xbdt','xbli','xdis','xfhs','xfhm','xfhl','xfos','xfom','xfol','xfns','xfnm','xfnl','xfus','xfum','xful','bchd','bmil','bpxf','bphx','bhav','barm','bens','bstt','bcor','bspa','buns','bust','biwb','xesn','bivs','buad' },
    destructable = { 'volc' },
}

local mustmark = {
Asac = { 'ushd', 'unit' },
Alam = { 'ushd', 'unit' },
}

local search

local function split(str)
    local r = {}
    str:gsub('[^,]+', function (w) r[#r+1] = w:lower() end)
    return r
end

local mark_known_type

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
            slk.txt[name]._mark = 1
            return true
        end
        return false
    end
    if o._mark then
        return true
    end
    o._mark = 1
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

local function mark(slk, name)
    name = name:lower()
    local o = slk.all[name]
    if o then
        if not mark_known_type(slk, o._type, name) then
            print(name)
            return false
        end
        return true
    end
    local o = slk.txt[name]
    if o then
        o._mark = true
        return true
    end
    print(name)
    return false
end

local function mark_mustuse(slk)
    for type, list in pairs(mustuse) do
        for _, name in ipairs(list) do
            if not mark_known_type(slk, type, name) then
                print(name)
            end
        end
    end
end

local function mark_jass(w2l, archive, slk)
    local list, flag = w2l:backend_searchjass(archive)
    if not list then
        return
    end
    for name in pairs(list) do
        mark(slk, name)
    end
    if flag.creeps or flag.building then
        local maptile = slk.w3i.map_main_ground_type
        local search_marketplace = flag.marketplace and flag.item
        flag.marketplace = nil
        for _, obj in pairs(slk.unit) do
            local need_mark = false
            if obj.race == 'creeps' and obj.tilesets and (obj.tilesets == '*' or obj.tilesets:find(maptile)) then
                if (flag.building and obj.isbldg == 1 and obj.nbrandom == 1) or (flag.creeps and obj.isbldg == 0) then
                    mark_known_type(slk, 'unit', obj)
                end
            end
            if search_marketplace and obj._name == 'marketplace' then
                flag.marketplace = true
                search_marketplace = false
            end
        end
    end
    if flag.item then
        for _, obj in pairs(slk.item) do
            if obj.pickRandom == 1 then
                mark_known_type(slk, 'item', obj)
            end
        end
    elseif flag.marketplace then
        for _, obj in pairs(slk.item) do
            if obj.pickRandom == 1 and obj.sellable == 1 then
                mark_known_type(slk, 'item', obj)
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
        if not mark_known_type(slk, 'destructable', name) then
            mark_known_type(slk, 'doodad', name)
        end
    end
    for name in pairs(doodad) do
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
    local suc, list = pcall(f, archive)
    if not suc then
        print(list)
        return
    end
    if type(list) ~= 'table' then
        return
    end
    for name in pairs(list) do
        mark(slk, name)
    end
end

return function(w2l, archive, slk)
    if not search then
        search = {}
        for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            search[type] = w2l:parse_lni(assert(io.load(w2l.prebuilt / 'key' / (type .. '_type.ini'))))
        end
    end
    mark_mustuse(slk)
    mark_jass(w2l, archive, slk)
    mark_doo(w2l, archive, slk)
    mark_lua(w2l, archive, slk)
end
