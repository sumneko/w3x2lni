local lang = require 'tool.lang'
local root = fs.current_path()

return function (w2l, mpq, version)
    w2l.messager.text(lang.script.CONVERT_ONE .. version)

    w2l:set_config
    {
        data_war3 = mpq,
        data_wes  = mpq,
        version   = version,
    }
    local prebuilt_path = root:parent_path() / 'data' / mpq / 'prebuilt' / w2l.mpq_path:first_path()
    fs.create_directories(prebuilt_path)

    function w2l:prebuilt_save(filename, buf)
        io.save(prebuilt_path / filename, buf)
    end

    w2l.builded_slk = w2l:build_slk()

    function w2l:prebuilt_save()
    end
end
