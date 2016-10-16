local w3x2txt = require 'w3x2txt'

local mt = {}
mt.__index = mt

function mt:add_meta(slk)
    if not self.slk then
        self.slk = slk
        return
    end
    for name, value in pairs(slk) do
        local dest = self.slk[name]
        if not dest then
            self.slk[name] = value
        else
            for k, v in pairs(value) do
                dest[k] = v
            end
        end
    end
end

function mt:save()

end

return function (name, meta)
    local self = setmetatable({}, mt)
    local data = {}

    return self
end
