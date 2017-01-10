local lpeg = require 'lpeg'

local table_insert = table.insert

local mt = {}
mt.__index = mt

-- 同时有英文逗号和英文双引号的字符串存在txt里会解析出错
-- 包含右大括号的字符串存在wts里会解析出错
-- 超过256字节的字符串存在二进制里会崩溃
function mt:load(content, max, reason)
    local wts = self.wts
    return content:gsub('TRIGSTR_(%d+)', function(i)
        local str_data = wts[i]
        if not str_data then
            message('-report|9其他', '没有找到字符串定义:', ('TRIGSTR_%03d'):format(i))
            return
        end
        local text = str_data.text
        if max and #text > max then
            str_data.mark = true
            message('-report|7保存到wts中的文本', reason)
            message('-tip', '文本保存在wts中会导致加载速度变慢: ', (text:sub(1, 1000):gsub('\r\n', ' ')))
            return
        end
        return text
    end)
end

function mt:insert(value, reason)
    local wts = self.wts
    message('-report|7保存到wts中的文本', reason)
    message('-tip', '文本保存在wts中会导致加载速度变慢: ', (value:sub(1, 1000):gsub('\r\n', ' ')))
    for i = self.lastindex, 999999 do
        local index = ('%03d'):format(i)
        if not wts[index] then
            if value:find('}', 1, false) then
                message('-report|2警告', '文本中的"}"被修改为了"|"')
                message('-tip', (value:sub(1, 1000):gsub('\r\n', ' ')))
                value = value:gsub('}', '|')
            end
            self.lastindex = i + 1
            wts[index] = {
                index  = i,
                text   = value,
                mark   = true,
            }
            table_insert(wts, wts[index])
            return 'TRIGSTR_' .. i
        end
    end
    message('-report|2警告', '保存在wts里的字符串太多了')
    message('-tip', '字符串被丢弃了:' .. (value:sub(1, 1000):gsub('\r\n', ' ')))
end

function mt:refresh()
    local lines    = {}
    for i, t in ipairs(self.wts) do
        if t and t.mark then
            table_insert(lines, ('STRING %d\r\n{\r\n%s\r\n}'):format(t.index, t.text))
        end
    end

    return table.concat(lines, '\r\n\r\n')
end

local function search_string(buf)
    local line_count = 1
    lpeg.locale(lpeg)
    local S = lpeg.S
    local P = lpeg.P
    local R = lpeg.R
    local C = lpeg.C
    local V = lpeg.V
    local Ct = lpeg.Ct
    local Cg = lpeg.Cg
    local Cp = lpeg.Cp

    local function newline()
        line_count = line_count + 1
    end

    local function getline()
        return line_count
    end

    local bom = P'\xEF\xBB\xBF'
    local nl  = (P'\r\n' + S'\r\n') / newline
    local com = P'//' * (1-nl)^0 * nl^-1
    local int = P'0' + R'19' * R'09'^0
    local define = P
    {
        'define',
        define = Ct(V'head' * com^-1 * V'body'),
        head   = P'STRING ' * Cg(int, 'index') * Cg(Cp() / getline, 'line') * nl,
        body   = V'start' * Cg(V'text', 'text') * V'finish',
        start  = P'{' * nl,
        finish = nl * P'}' * nl^0,
        text   = (nl + P(1) - V'finish' * (V'sdefine' + -P(1)))^0,
        sdefine= V'head' * com^-1 * V'sbody',
        sbody  = V'start' * V'stext' * V'finish',
        stext  = (nl + P(1) - V'finish')^0,
    }

    local function err(str)
        return ((1-nl)^1 + P(1)) / function(c)
            error(('line[%d]: %s:\n===========================\n%s\n==========================='):format(line_count, str, c))
        end
    end

    local searcher = Ct(bom^-1 * (nl + com)^0 * (define + err'syntax error')^0)
    local result = searcher:match(buf)
    return result
end

-- TODO: 待重构，数据和操作分离 
return function (w2l, archive)
    local buf = archive:get('war3map.wts')
    local tbl = {}
    if buf then
        tbl = search_string(buf)
        for _, t in ipairs(tbl) do
            local index, text = t.index, t.text
            if text:find('}', 1, false) then
                message('-report|2警告', '文本不能包含字符"}"')
                message('-tip', (text:sub(1, 1000):gsub('\r\n', ' ')))
            end
            tbl[('%03d'):format(index)] = t    --这里的索引是字符串
        end
    end
    return setmetatable({ wts = tbl, lastindex = 0 }, mt)
end
