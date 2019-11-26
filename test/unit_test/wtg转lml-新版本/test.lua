local lang = require 'share.lang'
local util = require 'share.utility'
lang:set_lang('zhCN')

--- 递归判断A与B是否相等
---@param a any
---@param b any
---@return boolean
local function equal(a, b)
    local tp1 = type(a)
    local tp2 = type(b)
    if tp1 ~= tp2 then
        return false
    end
    if tp1 == 'table' then
        local mark = {}
        for k, v in pairs(a) do
            mark[k] = true
            local res = equal(v, b[k])
            if not res then
                return false
            end
        end
        for k in pairs(b) do
            if not mark[k] then
                return false
            end
        end
        return true
    elseif tp1 == 'number' then
        return math.abs(a - b) <= 1e-10
    else
        return a == b
    end
end


local w2l = w3x2lni()
w2l:set_setting { mode = 'lni',  data_ui = '${DATA}'}

local targetfiles = packDir 'trigger'
local targetfiles2 = {}
for path, buf in pairs(targetfiles) do
    path = path:gsub('/', '\\')
    buf = buf:gsub('\r\n', '\n')
    targetfiles2[path] = buf
end
local wtg = read 'war3map.wtg'
local wct = read 'war3map.wct'
local wtg_data = w2l:frontend_wtg(wtg)
local wct_data = w2l:frontend_wct(wct)
local files = w2l:backend_lml(wtg_data, wct_data)
local files2 = {}
for path, buf in pairs(files) do
    path = path:gsub('/', '\\')
    buf = buf:gsub('\r\n', '\n')
    files2[path] = buf
end
assert(equal(files2, targetfiles2))


local w2l = w3x2lni()
w2l:set_setting { mode = 'obj',  data_ui = '${DATA}' }

local wtg_data, wct_data = w2l:frontend_lml(function (filename)
    return read('trigger/' .. filename)
end)
local targetwtg = w2l:backend_wtg(wtg_data):gsub('\r\n', '\n')
local targetwct = w2l:backend_wct(wct_data):gsub('\r\n', '\n')
local wtg = read 'war3map.wtg' :gsub('\r\n', '\n')
local wct = read 'war3map.wct' :gsub('\r\n', '\n')
assert(targetwtg == wtg)
assert(targetwct == wct)
