local mt = {}

mt.info = {
    name = '示例',
    version = 1.0,
    author = '最萌小汐',
    description = '在slk时，将所有单位的名字加上前缀"被插件修改过的"。',
}

function mt:on_full(w2l)
    if w2l.config.mode == 'slk' then
        for id, obj in pairs(w2l.slk.unit) do
            obj.name = '被插件修改过的' .. obj.name
        end
    end
end

return mt
