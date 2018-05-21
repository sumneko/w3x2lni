local w2l = w3x2lni()
w2l:set_setting { mode = 'lni' }
w2l.slk = {}
w2l:frontend()
w2l:backend()
for k in pairs(w2l.slk.misc.HERO) do
    if k:sub(1, 1) ~= '_' then
        error('misc中有多余数据')
    end
end
