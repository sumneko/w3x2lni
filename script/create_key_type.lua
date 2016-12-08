return function(txt)
    local lines = {}

    lines[#lines+1] = ('    %s = %s,'):format('int', 0)
    lines[#lines+1] = ('    %s = %s,'):format('bool', 0)
    lines[#lines+1] = ('    %s = %s,'):format('real', 1)
    lines[#lines+1] = ('    %s = %s,'):format('unreal', 2)

    for key, data in pairs(txt) do
        local value = data['00'][1]
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
