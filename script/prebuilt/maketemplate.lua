local root = fs.current_path()

return function (w2l, mpq, version)
    local template_path = root:parent_path() / 'template' / version
    w2l:set_config
    {
        mpq     = mpq,
        version = version,
    }
    local slk = w2l:get_default(true)
    fs.create_directories(template_path)
    for i, ttype in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
        w2l.progress:start(i / 9)
        local data = w2l:frontend_merge(ttype, slk[ttype], {})
        io.save(template_path / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
        w2l.progress:finish()
    end
    io.save(template_path / 'txt.ini', w2l:backend_txtlni(slk.txt))
end
