local mt = {}
setmetatable(mt, mt)

local start = 0
local target = 0

function mt:target(n)
    start = target
    target = n
    message('-progress', start)
end

function mt:__call(n)
    if n > 1 then
        n = 1
    end
    message('-progress', start + (target - start) * n)
end

return mt
