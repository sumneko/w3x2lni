local mt = {}

mt.info = {
    name = '资源保护',
    version = 1.0,
    author = '最萌小汐',
    description = '没有资源目录时，将模型替换为步兵。'
}

function mt:on_complete_data(w2l)
    if w2l.input_mode == 'lni' and (w2l.config.mode == 'obj' or w2l.config.mode == 'slk') then
        if fs.exists(input / 'resource') then
            return
        end
        
        local ignore = {
            [".mdx"] = true,
            [".mdl"] = true,
            ["model\\dummy.mdl"] = true,
        }
        
        for id, u in pairs(w2l.slk.unit) do
            if u.file and not ignore[u.file:lower()] then
                u.file = [[units\human\Footman\Footman.mdx]]
            end
            if u.art then
                u.art = [[ReplaceableTextures\CommandButtons\BTNFootman.blp]]
            end
        end
    end
    if w2l.config.mode == 'lni' then
        local file_save = w2l.file_save
        function w2l:file_save(type, name, buf)
            if type == 'resource' then
                return
            end
            file_save(self, type, name, buf)
        end
    end
end

return mt
