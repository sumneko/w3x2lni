local w3xparser = require 'w3xparser'
local lni = require 'lni-c'
local slk = w3xparser.slk
local txt = w3xparser.txt
local ini = w3xparser.ini
local pairs = pairs
local string_lower = string.lower

local mt = {}

local metadata
local keydata
local editstring
local default
local miscnames
local wts

function mt:parse_lni(...)
    return lni(...)
end

function mt:parse_slk(buf)
    return slk(buf)
end

function mt:parse_txt(...)
    return txt(...)
end

function mt:parse_ini(buf)
    return ini(buf)
end

function mt:metadata()
    if not metadata then
        metadata = lni(self:loader(self.defined .. '\\metadata.ini'))
    end
    return metadata
end

function mt:keydata()
    if not keydata then
        keydata = lni(self:loader(self.defined .. '\\keydata.ini'))
    end
    return keydata
end

function mt:miscnames()
    if not miscnames then
        miscnames = lni(self:loader(self.defined .. '\\miscnames.ini'))
    end
    return miscnames
end

function mt:editstring(str)
    -- TODO: WESTRING不区分大小写，不过我们把WorldEditStrings.txt改了，暂时不会出现问题
    if not editstring then
        editstring = ini(self:loader('\\WorldEditStrings.txt'))['WorldEditStrings']
    end
    if not editstring[str] then
        return str
    end
    repeat
        str = editstring[str]
    until not editstring[str]
    return str:gsub('%c+', '')
end

local function create_default(w2l)
    local default = {}
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'txt', 'misc'} do
        local str = w2l:loader(w2l.default .. '\\' .. name .. '.ini')
        if str then
            default[name] = lni(str)
        end
    end
    return default
end

function mt:get_default(create)
    if create then
        return create_default(self)
    end
    if not default then
        default = create_default(self)
    end
    return default
end

-- 同时有英文逗号和英文双引号的字符串存在txt里会解析出错
-- 包含右大括号的字符串存在wts里会解析出错
-- 超过256字节的字符串存在二进制里会崩溃

function mt:load_wts(wts, content, max, reason, fmter)
    if not wts then
        return content
    end
    return content:gsub('TRIGSTR_(%d+)', function(i)
        local str_data = wts[tonumber(i)]
        if not str_data then
            print('-report|9其他', '没有找到字符串定义:', ('TRIGSTR_%03d'):format(i))
            return
        end
        local text = str_data.text
        if fmter then
            text = fmter(text)
        end
        if max and #text > max then
            return self:save_wts(wts, text, reason)
        end
        return text
    end)
end

function mt:save_wts(wts, text, reason)
    print('-report|7保存到wts中的文本', reason)
    print('-tip', '文本保存在wts中会导致加载速度变慢: ', (text:sub(1, 1000):gsub('\r\n', ' ')))
    if text:find('}', 1, false) then
        print('-report|2警告', '文本中的"}"被修改为了"|"')
        print('-tip', (text:sub(1, 1000):gsub('\r\n', ' ')))
        text = text:gsub('}', '|')
    end
    local index = #wts.mark + 1
    wts.mark[index] = text
    return ('TRIGSTR_%03d'):format(index-1)
end

function mt:refresh_wts(wts)
    local lines = {}
    for index, text in ipairs(wts.mark) do
        lines[#lines+1] = ('STRING %d\r\n{\r\n%s\r\n}'):format(index-1, text)
    end
    return table.concat(lines, '\r\n\r\n')
end

setmetatable(mt, mt)
function mt:__index(name)
    if package.loaded[name] ~= nil then
        return package.loaded[name]
    end
    if package.searchpath('slk.'..name, package.path) then
        package.loaded[name] = require('slk.'..name)
    elseif package.searchpath('other.'..name, package.path) then
        package.loaded[name] = require('other.'..name)
    end
    return package.loaded[name]
end

progress = require 'progress'

function mt:loader(path)
    local f = io.open(path)
    if f then
        local buf = f:read 'a'
        f:close()
        return buf
    end
    return nil
end

function mt:initialize()
    if self.initialized then
        return
    end
    self.initialized = true
    self.defined = 'defined'
    self.info   = lni(assert(self:loader('info.ini')), 'info')
end

function mt:set_config(config)
    self.config = config
    self.mpq = 'data\\' .. self.config.mpq
    if self.config.version == 'Melee' then
        self.agent = self.mpq
        self.default = self.mpq .. '\\prebuilt\\Melee'
    else
        self.agent = self.mpq .. '\\Custom_V1'
        self.default = self.mpq .. '\\prebuilt\\Custom'
    end
end

function mt:set_messager(prt)
    print = prt
end

function mt:set_progress(func)
    progress = func
end

return mt
