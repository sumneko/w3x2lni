local function add_table(a, b)
    for k, v in pairs(b) do
        if a[k] then
            if type(a[k]) == 'table' and type(v) == 'table' then
                add_table(a[k], v)
            else
                a[k] = v
            end
        else
            a[k] = v
        end
    end
end

return function (w2l, archive, slk)
    local misc = {}
    for _, name in ipairs {"UI\\MiscData.txt", "Units\\MiscData.txt", "Units\\MiscGame.txt"} do
        add_table(misc, w2l:parse_ini(io.load(w2l.mpq / name)))
    end
    local buf = archive:get('war3mapmisc.txt')
    if buf then
        add_table(misc, w2l:parse_ini(buf))
    end
    slk.misc = misc
end
