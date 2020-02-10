local loader

local function sortpairs(t)
    local sort = {}
    for k, v in pairs(t) do
        sort[#sort+1] = {k, v}
    end
    table.sort(sort, function (a, b)
        return a[1] < b[1]
    end)
    local n = 1
    return function()
        local v = sort[n]
        if not v then
            return
        end
        n = n + 1
        return v[1], v[2]
    end
end

local function fmtstring(s)
    if s:find '[^%w_]' then
        return ('%q'):format(s)
    end
    return s
end

local function parse_titles(slk)
    local titleMap = {}
    local cx = 1
    local cy = 1
    for line in slk:gmatch '[^\r\n]+' do
        local pos = 1
        while pos <= #line do
            local char = line:sub(pos, pos)
            if char == 'X' then
                local s, e, n = line:find('(%d*)', pos+1)
                pos = e + 1
                cx = tonumber(n) or 1
            elseif char == 'Y' then
                local s, e, n = line:find('(%d*)', pos+1)
                pos = e + 1
                cy = tonumber(n) or 1
            elseif char == 'K' then
                if line:sub(pos+1, pos+1) == '"' then
                    local s, e, n = line:find('([^"]*)', pos+2)
                    pos = e + 2
                    if cy == 1 then
                        titleMap[n] = cx
                    end
                else
                    local s, e, n = line:find('([^;]*)', pos+1)
                    pos = e + 2
                    if cy == 1 then
                        titleMap[n] = cx
                    end
                end
            else
                pos = pos + 1
            end
        end
    end

    local titles = {}
    for t, i in pairs(titleMap) do
        titles[#titles+1] = t
    end
    table.sort(titles, function (a, b)
        return titleMap[a] < titleMap[b]
    end)

    return titles
end

local function create_slktitle(w2l, slkname, slktitle)
    local slk = loader(slkname)
    local titles = parse_titles(slk)
    slktitle[slkname] = titles
end

local function stringify(f, name, t)
    if not t then
        return
    end
    f[#f+1] = ('%s = {'):format(fmtstring(name))
    for _, v in ipairs(t) do
        f[#f+1] = ('%s,'):format(fmtstring(v))
    end
    f[#f+1] = '}'
end

return function(w2l, loader_)
    loader = loader_
    local slktitle = {}
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        for _, slkname in pairs(w2l.info.slk[type]) do
            create_slktitle(w2l, slkname, slktitle)
        end
    end
    local f = {}
    for k, v in sortpairs(slktitle) do
        stringify(f, k, v)
    end
    return table.concat(f, '\r\n')
end
