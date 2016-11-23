-- 规则如下
-- 1.如果当前字符为引号,则匹配到下一个引号,并忽略2端的引号
-- 2.如果当前字符为逗号,则忽略当前字符
-- 3.否则匹配到下一个逗号或引号前的一个字符
local function splite(str)
    local tbl = {}
    local cur = 1
    while cur <= #str do
        if str:sub(cur, cur) == '"' then
            local pos = str:find('"', cur+1, true) or (#str+1)
            tbl[#tbl+1] = str:sub(cur+1, pos-1)
            cur = pos+1
        elseif str:sub(cur, cur) == ',' then
            cur = cur+1
        else
            local pos = str:find('[",]', cur+1) or (#str+1)
            tbl[#tbl+1] = str:sub(cur, pos-1)
            cur = pos
        end
    end
    if tbl[#tbl] == '' and #tbl > 1 then
        table.remove(tbl)
    end
    if #tbl > 1 then
        return tbl
    else
        return tbl[1]
    end
end

return function(txt)
    local lines = {}

    lines[#lines+1] = ('    %s = %s,'):format('int', 0)
    lines[#lines+1] = ('    %s = %s,'):format('bool', 0)
    lines[#lines+1] = ('    %s = %s,'):format('real', 1)
    lines[#lines+1] = ('    %s = %s,'):format('unreal', 2)

    for key, data in pairs(txt) do
        local tbl = splite(data['00'])
        local value = tbl[1]
        local tp
        if tonumber(value) then
            tp = 0
        else
            tp = 3
        end
        lines[#lines+1] = ('    %s = %s,'):format(key, tp)
    end

    table.sort(lines)

    return ('return\r\n{\r\n%s\r\n}\r\n'):format(table.concat(lines, '\r\n'))
end
