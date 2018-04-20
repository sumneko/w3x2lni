local lang = require 'tool.lang'
local root = fs.current_path()

return function (w2l, mpq, version)
    w2l.messager.text(lang.script.CONVERT_ONE .. version)

    w2l:set_config
    {
        mpq     = mpq,
        version = version,
    }
    local prebuilt_path = root:parent_path() / 'data' / 'prebuilt' / w2l.mpq_path:first_path()
    fs.create_directories(prebuilt_path)

    function w2l:prebuilt_save(filename, buf)
        io.save(prebuilt_path / filename, buf)
    end

    w2l:build_slk()

    function w2l:prebuilt_save()
    end
end
