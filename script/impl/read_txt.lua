local tonumber = tonumber

-- 规则如下
-- 1.如果第一个字符是逗号,则添加一个空串
-- 2.如果最后一个字符是逗号,则添加一个空标记
-- 3.如果最后一个字符是引号,则忽略该字符
-- 4.如果当前字符为引号,则匹配到下一个引号,并忽略2端的字符
-- 5.如果当前字符为逗号,则忽略该字符.如果上一个字符是逗号,则添加一个空串
-- 6.否则匹配到下一个逗号,并忽略该字符
local function splite(str)
    local tbl = {}
    local cur = 1
    if str:sub(1, 1) == ',' then
        tbl[#tbl+1] = ''
    end
    while cur <= #str do
        if str:sub(cur, cur) == '"' then
            if cur == #str then
                break
            end
            local pos = str:find('"', cur+1, true) or (#str+1)
            tbl[#tbl+1] = str:sub(cur+1, pos-1)
            cur = pos+1
        elseif str:sub(cur, cur) == ',' then
            if str:sub(cur-1, cur-1) == ',' then
                tbl[#tbl+1] = ''
            end
            cur = cur+1
        else
            local pos = str:find(',', cur+1, true) or (#str+1)
            tbl[#tbl+1] = str:sub(cur, pos-1)
            cur = pos+1
        end
    end
    if str:sub(-1, -1) == ',' then
        tbl[#tbl+1] = false
    end
    return tbl
end

local current_chunk

local function parse(txt, line)
    if #line == 0 then
        return
    end
    if line:sub(1, 2) == '//' then
        return
    end
    local chunk_name = line:match '^[%c%s]*%[(.-)%][%c%s]*$'
    if chunk_name then
        current_chunk = chunk_name
        if not txt[chunk_name] then
            txt[chunk_name] = {}
        end
        return
    end
    if not current_chunk then
        return
    end
    line = line:gsub('%c+', '')
    local key, value = line:match '^(.*)%=(.*)$'
    if key and value then
        txt[current_chunk][key] = splite(value)
        return
    end
end

return function (w2l, content)
	if not content then
		return
	end
    current_chunk = nil
    local txt = {}
	for line in content:gmatch '[^\r\n]+' do
        parse(txt, line)
    end
    return txt
end
