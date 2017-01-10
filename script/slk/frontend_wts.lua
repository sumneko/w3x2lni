local lpeg = require 'lpeg'

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

return function (w2l, archive)
    local buf = archive:get('war3map.wts')
    if not buf then
        return {}
    end
    local tbl = search_string(buf)
    for _, t in ipairs(tbl) do
        local index, text = t.index, t.text
        if text:find('}', 1, false) then
            message('-report|2警告', '文本不能包含字符"}"')
            message('-tip', (text:sub(1, 1000):gsub('\r\n', ' ')))
        end
        tbl[('%03d'):format(index)] = t    --这里的索引是字符串
    end
    return tbl
end
