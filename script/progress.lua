local mt = {}
setmetatable(mt, mt)

local level = 0
local current = 0
local min_rate = 0
local max_rate = 1
local min = {}
local max = {}

local function refresh_rate()
    min_rate = 0
    max_rate = 1
    for i = level, 1, -1 do
        min_rate = min_rate * (max[i] - min[i]) + min[i]
        max_rate = max_rate * (max[i] - min[i]) + min[i]
    end
    message('-progress', current * (max_rate - min_rate) + min_rate)
end

-- 开启新任务,新任务完成时当前任务的完成进度
function mt:start(n)
    level = level + 1
    min[level] = current
    max[level] = n
    current = 0
    refresh_rate()
end

-- 完成当前任务
function mt:finish()
    current = max[level]
    level = level - 1
    refresh_rate()
end

-- 设置当前任务进度
function mt:__call(n)
    current = n
    message('-progress', current * (max_rate - min_rate) + min_rate)
end

return mt
