local pairs = pairs
local type = type

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

local function table_copy(b)
    local a = {}
    for k, v in pairs(b) do
        if type(v) == 'table' then
            a[k] = table_copy(v)
        else
            a[k] = v
        end
    end
    return a
end

return function (w2l, slk_data, obj_data)
    for name, obj in pairs(obj_data) do
        if not slk_data[name] then
            local code = obj._lower_code
            slk_data[name] = table_copy(slk_data[code])
        end
        table_merge(slk_data[name], obj)
    end
end
