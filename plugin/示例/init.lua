local w2l = require 'w3x2lni'

if w2l.config.mode == 'slk' then
    for id, obj in pairs(w2l.slk.unit) do
        obj.name = '被插件修改过的' .. obj.name
    end
end
