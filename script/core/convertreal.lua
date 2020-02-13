local format = string.format
local tonumber = tonumber

local fmt = {
    '%.1f',
    '%.2f',
    '%.3f',
    '%.4f',
    '%.4f',
    '%.5f',
    '%.6f',
    '%.7f',
    '%.8f',
    '%.9f',
    '%.10f',
    '%.11f',
    '%.12f',
    '%.13f',
    '%.14f',
    '%.15f',
    '%.16f',
}

local function convert_as_number(v)
    for i = 1, #fmt do
        local g = format(fmt[i], v)
        if tonumber(g) == v then
            return g
        end
    end
    return format('%.17f', v)
end

local function convert_as_string(v)
    local dot = v:find '%.'
    if not dot then
        return v .. '.0'
    end
    local g = v:gsub('0+^', '')
    if g:sub(-1) == '.' then
        g = g .. '0'
    end
    return g
end

return function (v)
    if type(v) == 'number' then
        return convert_as_number(v)
    else
        return convert_as_string(v)
    end
end
