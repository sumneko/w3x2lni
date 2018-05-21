local w2l = w3x2lni()
w2l:set_setting { mode = 'slk', read_slk = true }
w2l.slk = {}
w2l:frontend()
assert(w2l.slk.misc.HERO._source == 'slk', '来自slk的misc要有标记')
w2l:backend()
local ok = false
for k in pairs(w2l.slk.misc.HERO) do
    if k:sub(1, 1) ~= '_' then
        ok = true
    end
end
assert(ok, 'slk时来自slk的misc不应该清理数据')
