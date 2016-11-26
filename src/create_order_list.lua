local order_id = require 'order_id'

local function load_order(skill_data)
    local data = {}
    for code, skill in pairs(skill_data) do
        local order
        if code == 'AAns' then
            order = skill.DataE
        else
            order = skill.Order
        end
        if order then
            order = order_id[order]
        elseif skill.YDWEtip then
            order = skill.YDWEtip:match '^命令ID是(.)+$'
        end
        if order then
            if data[code] and data[code] ~= order then
                print('命令冲突', code, data[code], order)
            end
            data[code] = order
        end
    end
    return data
end

local function write_order(data)
    local lines = {}
    for name, value in pairs(data) do
        lines[#lines+1] = ('    %s = 0x%X,'):format(name, value)
    end
    table.sort(lines)
    local content = ('return {\r\n%s\r\n}'):format(table.concat(lines, '\r\n'))
    return content
end

return function (skill_data)
    local data = load_order(skill_data)
    local content = write_order(data)
    return content
end
