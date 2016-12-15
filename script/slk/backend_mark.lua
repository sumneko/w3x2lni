local std_type = type
local mustuse =  {
    unit = { 'Volc','Ntin','hpea','ugol','Hblm','hrtt','Ewar','Oshd','Otch','Nngs','uske','Udre','ugho','Emoo','ewsp','Nplh','uaco','Udea','opeo','Edem','Nbrn','unpl','Nfir','Ofar','htow','Nbst','Obla','Nalc','Hpal','Hamg','Ekee','Npbm','ogre','etol','Ucrl','Ulic','ngol','otbk','nshe','Hmkg' },
    ability = { 'Amic','Avul','Adda','Aalr','Aatk','ANbu','AHbu','AObu','AEbu','AUbu','AGbu','Abdt','Argd','AHer','Arev','ARal','Amnz','ACsp','Sloa','Aetl','Amov','Afir','Afih','Afio','Afin','Afiu' },
    buff = { 'BPSE','BSTN','BTLF','Bdet','Bvul','Bspe','Bfro','Bsha','Btrv','Bbar','Xbdt','Xbli','Xdis','Xfhs','Xfhm','Xfhl','Xfos','Xfom','Xfol','Xfns','Xfnm','Xfnl','Xfus','Xfum','Xful','Bchd','Bmil','Bpxf','Bphx','BHav','Barm','Bens','Bstt','Bcor','Bspa','Buns','BUst','BIwb','Xesn','Bivs','BUad' },
    destructable = { 'DTep','DTrx','DTrf' },
    upgrade = { 'Robk','Rhrt' },
    item = { 'stwp' },
    doodad = { },
}

local mustmark = {
Asac = { 'ushd', 'unit' },
Alam = { 'ushd', 'unit' },
}

local search

local function mark_known_type(slk, type, name)
    local o = slk[type][name]
    if not o then
        return false
    end
    if o._mark then
        return true
    end
    o._mark = 1
    local searchlist = search[type].common
    if searchlist then
        for key, type in pairs(searchlist) do
            if std_type(o[key]) == 'table' then
                for _, name in ipairs(o[key]) do
                    mark_known_type(slk, type, name)
                end
            else
                mark_known_type(slk, type, o[key])
            end
        end
    end
    local searchlist = search[type][o._origin_id]
    if searchlist then
        for key, type in pairs(searchlist) do
            if std_type(o[key]) == 'table' then
                for _, name in ipairs(o[key]) do
                    mark_known_type(slk, type, name)
                end
            else
                mark_known_type(slk, type, o[key])
            end
        end
    end
    local marklist = mustmark[o._origin_id]
    if marklist then
        mark_known_type(slk, marklist[2], marklist[1])
    end
    return true
end

local function mark(slk, name)
    for _, type in ipairs {'ability', 'unit', 'buff', 'item', 'upgrade', 'doodad', 'destructable'} do
        if mark_known_type(slk, type, name) then
            return true
        end
    end
    return false
end

local function mark_mustuse(slk)
    for type, list in pairs(mustuse) do
        for _, name in ipairs(list) do
            mark_known_type(slk, type, name)
        end
    end
end

local function mark_jass(w2l, archive, slk)
    local buf = archive:get('war3map.j')
    if not buf then
        buf = archive:get('scripts\\war3map.j')
        if not buf then
            return
        end
    end
    local list = w2l:backend_jass(buf)
    for name in pairs(list) do
        mark(slk, name)
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

return function(w2l, archive, slk)
    if not search then
        search = {}
        for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
            search[type] = w2l:parse_lni(assert(io.load(w2l.prebuilt / 'key' / (type .. '_type.ini'))))
        end
    end
    mark_mustuse(slk)
    mark_jass(w2l, archive, slk)
    mark_doo(w2l, archive, slk)
    --TODO: 动态化BJ函数的引用
    --TODO: 随机物品、随机建筑、随机野怪、市场
end
