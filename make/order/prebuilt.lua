local order_id = require 'order.order_id'

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
            local new_order
            for str in order:gmatch '[^,]+' do
                new_order = order_id[str] or new_order
            end
            order = new_order
        elseif skill.YDWEtip then
            local order = skill.YDWEtip
            if type(order) ~= 'table' then
                order = {order}
            end
            local new_order
            for _, str in ipairs(order) do
                new_order = str:match '^命令ID是(.)+$' or new_order
            end
            order = new_order
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

local function load_order2(skill_data, tp)
    local data = {}
    for code, skill in pairs(skill_data) do
        local order
        order = skill[tp]
        if order then
            local new_order
            for str in order:gmatch '[^,]+' do
                new_order = order_id[str] or new_order
            end
            order = new_order
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

local function write_order(data, name)
    local lines = {}
    for name, value in pairs(data) do
        lines[#lines+1] = ('    %s = 0x%X,'):format(name, value)
    end
    table.sort(lines)
    local content = ('[\'%s\'] = {\r\n%s\r\n},\r\n'):format(name, table.concat(lines, '\r\n'))
    return content
end

return function (skill_data)
    local order, unorder, orderon, orderoff

    local order = write_order(load_order(skill_data), 'Order')
    local unorder = write_order(load_order2(skill_data, 'Unorder'), 'Unorder')
    local orderon = write_order(load_order2(skill_data, 'Orderon'), 'Orderon')
    local orderoff = write_order(load_order2(skill_data, 'Orderoff'), 'Orderoff')

    local content = ('return {\r\n%s%s%s%s}'):format(order, unorder, orderon, orderoff)

    return content
end
