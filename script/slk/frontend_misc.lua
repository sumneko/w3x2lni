local function table_merge(a, b)
    for k, v in pairs(b) do
        if a[k] then
            if type(a[k]) == 'table' and type(v) == 'table' then
                table_merge(a[k], v)
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
        table_merge(misc, w2l:parse_ini(io.load(w2l.mpq / name)))
    end
    local buf = archive:get('war3mapmisc.txt')
    if buf then
        table_merge(misc, w2l:parse_ini(buf))
    end
    slk.misc = misc
end
