local type = type
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local find = string.find
local gsub = string.gsub
local format = string.format
local rep = string.rep
local buf
local lml_table

local sp_rep = setmetatable({}, {
    __index = function (self, k)
        self[k] = rep(' ', k)
        return self[k]
    end,
})

local function lml_string(str)
    if type(str) == 'string' then
        if find(str, "[%s%:%'%c]") then
            str = format("'%s'", gsub(str, "'", "''"))
        end
    end
    return str
end

local function lml_value(v, sp)
    if v[2] then
        buf[#buf+1] = format('%s%s: %s\n', sp_rep[sp], lml_string(v[1]), lml_string(v[2]))
    else
        buf[#buf+1] = format('%s%s\n', sp_rep[sp], lml_string(v[1]))
    end
    for i = 3, #v do
        lml_value(v[i], sp+4)
    end
end

local function convert_lml(tbl)
    buf = {}
    for i = 3, #tbl do
        lml_value(tbl[i], 0)
    end
    return table.concat(buf)
end

return function (w2l, tbl)
    local buf = convert_lml(tbl)
    return buf
end
