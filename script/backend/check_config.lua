local config = require 'share.config'
local lang = require 'share.lang'
local w2l

local function check(type, key, config)
    local effect  = config[type][key]
    local default = config[type]._default._raw[key]
    local global  = config[type]._global._raw[key]
    local map     = config[type]._map._raw[key]
    local raw
    if map ~= nil then
        raw = map
    elseif global ~= nil then
        raw = global
    else
        raw = default
    end
    if effect == raw then
        return
    end
    w2l:failed(lang.script.CONFIG_INVALID_DIR:format(type, key, raw))
end

return function (w2l_, input)
    w2l = w2l_
    config:open_map(input)
    check('global' ,'data_war3', config)
    check('global' ,'data_ui',   config)
    check('global' ,'data_meta', config)
    check('global' ,'data_wes',  config)
end
