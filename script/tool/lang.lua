require 'filesystem'
require 'utility'
local root = fs.current_path()
local mt = {}
setmetatable(mt, mt)

local lang

local function proxy(t)
    return setmetatable(t, { __index = function (_, k)
        error(2)
        t[k] = k
        return k
    end })
end

local function split(buf)
    local lines = {}
    local start = 1
    while true do
        local pos = buf:find('[\r\n]', start)
        if not pos then
            lines[#lines+1] = buf:sub(start)
            break
        end
        lines[#lines+1] = buf:sub(start, pos-1)
        if buf:sub(pos, pos+1) == '\r\n' then
            start = pos + 2
        else
            start = pos + 1
        end
    end
    return lines
end

function mt:load_lng(filename)
    if not lang then
        self:set_lang 'auto'
    end
    local t = {}
    local buf = io.load(root / 'locale' / lang / (filename .. '.lng'))
    if not buf then
        error(1)
        return proxy(t)
    end
    local key
    local lines = split(buf)
    for _, line in ipairs(lines) do
        local str = line:match '^%[(.+)%]$'
        if str then
            key = str
        elseif key then
            if t[key] then
                t[key] = t[key] .. '\n' .. line
            else
                t[key] = line
            end
        end
    end
    return proxy(t)
end

function mt:__index(filename)
    local t = self:load_lng(filename)
    self[filename] = t
    return t
end

function mt:set_lang(lang_)
    if lang_ == 'auto' then
        local language = require 'ffi.language' ()
        if language:sub(1, 3) == 'zh-' then
            lang = 'zh-CN'
        elseif language:sub(1, 3) == 'en-' then
            lang = 'en-US'
        else
            lang = 'en-US'
        end
    else
        lang = lang_
    end
end

return mt
