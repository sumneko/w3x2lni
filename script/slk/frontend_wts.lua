local table_insert = table.insert

local mt = {}
mt.__index = mt

-- TODO: 同时有英文逗号和英文双引号的字符串存在txt里会解析出错
--       包含右打括号的字符串存在wts里会解析出错
--       超过256字节的字符串存在二进制里会崩溃
function mt:load(content, max)
    local wts = self.wts
    return content:gsub('TRIGSTR_(%d+)', function(i)
        local str_data = wts[i]
        if not str_data then
            message('-report', '没有找到字符串定义:', ('TRIGSTR_%03d'):format(i))
            return
        end
        local text = str_data.text
        if max and #text > max then
            str_data.mark = true
            return
        end
        return text
    end)
end

function mt:insert(value)
    local wts = self.wts
    for i = self.lastindex, 999999 do
        local index = ('%03d'):format(i)
        if not wts[index] then
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
    message('-report', '保存在wts里的字符串太多了')
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

-- TODO: 待重构，数据和操作分离 
return function (w2l, archive)
    local buf = archive:get('war3map.wts') or ''
    local tbl = {}
    for string in buf:gmatch 'STRING.-%c*%}' do
        local i, s = string:match 'STRING (%d+).-%{\r\n(.-)%\r\n}'
        local t    = {
            index    = i,
            text    = s,
        }
        table_insert(tbl, t)
        tbl[('%03d'):format(i)] = t    --这里的索引是字符串
    end
    return setmetatable({ wts = tbl, lastindex = 0 }, mt)
end
