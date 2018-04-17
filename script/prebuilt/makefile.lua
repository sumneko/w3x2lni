local root = fs.current_path()

return function (w2l, mpq, version, template)
    print('==================')
    print(('  %s  %s  '):format(mpq, version))
    print('==================')

    w2l:set_config{
        mpq     = mpq,
        version = version,
    }
    local prebuilt_path = root:parent_path() / 'data' / 'prebuilt' / w2l.mpq_path:first_path()
    fs.create_directories(prebuilt_path)

    print('正在生成data')
    function w2l:prebuilt_save(filename, buf)
        io.save(prebuilt_path / filename, buf)
    end
	local slk = w2l:build_slk()
    
    if template then
        print('正在生成template')
        local template_path = root:parent_path() / 'template'
        for _, ttype in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            local data = w2l:frontend_merge(ttype, slk[ttype], {})
            io.save(template_path / (ttype .. '.ini'), w2l:backend_lni(ttype, data))
        end
        io.save(template_path / 'txt.ini', w2l:backend_txtlni(slk.txt))
    end
end
