local root = fs.current_path()
local mt = {}
setmetatable(mt, mt)

local function proxy(t)
    return setmetatable(t, { __index = function (_, k)
        error(2)
        t[k] = k
        return k
    end })
end

function mt:load_lng(filename)
    local t = {}
    local buf = io.load(root:parent_path() / 'locale' / self._lang / (filename .. '.lng'))
    if not buf then
        error(1)
        return proxy(t)
    end
    local key
    for line in buf:gmatch '[^\r\n]+' do
        local str = line:match '^%[(.+)%]$'
        if str then
            key = str
        elseif key then
            t[key] = line
        end
    end
    return proxy(t)
end

function mt:__index(filename)
    local t = self:load_lng(filename)
    self[filename] = t
    return t
end

function mt:set_lang(lang)
    self._lang = lang
end

return mt
