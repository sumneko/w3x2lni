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

local function search_string(buf, callback)
    local lines = {}
    local current = 1
    while true do
        local start, finish = buf:find('\r\n', current, false)
        if start then
            lines[#lines+1] = buf:sub(current, start-1)
            current = finish + 1
        else
            lines[#lines+1] = buf:sub(current, #buf)
            break
        end
    end
    if lines[1]:sub(1, 3) == '\xEF\xBB\xBF' then
        lines[1] = lines[1]:sub(4)
    end
    for i = #lines, 1, -1 do
        if lines[i] == '' then
            lines[i] = nil
        else
            break
        end
    end
    local count = 1
    while count <= #lines do
        local index = tonumber(lines[count]:match('^STRING (%d+)$'))
        if index then
            if lines[count+1]:sub(1, 2) == '//' then
                count = count + 1
            end
            if lines[count+1] ~= '{' then
                message('-report|2警告', ('wts解析错误:(%d) %s'):format(count, '缺少"{"'))
                message('-tip', lines[count]:sub(1, 1000))
                count = count + 2
                goto CONTINUE
            end
            for i = count+2, #lines do
                if lines[i] == '}' then
                    for j = i+1, #lines+1 do
                        if lines[j] ~= '' then
                            if lines[j] == nil or lines[j]:match('^STRING (%d+)$') then
                                local text = table.concat(lines, '\r\n', count+2, i-1)
                                callback(index, text)
                                count = j
                                goto CONTINUE
                            else
                                break
                            end
                        end
                    end
                end
            end
            message('-report|2警告', ('wts解析错误:(%d) %s'):format(count, '缺少"}"'))
            message('-tip', lines[count]:sub(1, 1000))
            return
        else
            count = count + 1
        end
        ::CONTINUE::
    end
end

-- TODO: 待重构，数据和操作分离 
return function (w2l, archive)
    local buf = archive:get('war3map.wts')
    local tbl = {}
    if buf then
        search_string(buf, function(index, text)
            if text:find('}', 1, false) then
                message('-report|2警告', '文本不能包含字符"}"')
                message('-tip', (text:sub(1, 1000):gsub('\r\n', ' ')))
            end
            local t = {
                index = index,
                text  = text,
            }
            table_insert(tbl, t)
            tbl[('%03d'):format(index)] = t    --这里的索引是字符串
        end)
    end
    return setmetatable({ wts = tbl, lastindex = 0 }, mt)
end
