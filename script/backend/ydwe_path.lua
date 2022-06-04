return function()
    local fs = require 'bee.filesystem'
    local sp = require 'bee.subprocess'
    local p, err = sp.spawn {
        'cmd', '/c',
        'reg', 'query', [[HKEY_CURRENT_USER\SOFTWARE\Classes\YDWEMap\shell\run_war3\command]],
        searchPath = true,
        stdout = true,
    }
    if not p then
        error(err)
        return
    end
    p:wait()
    local command = p.stdout:read 'a'
    if not command then
        return
    end
    local path = command:match '^"([^"]*)"'
    if not path then
        return
    end
    local ydwe = fs.path(path):parent_path()
    if fs.exists(ydwe / 'YDWE.exe') then
        return ydwe
    end
    local ydwe = ydwe:parent_path()
    if fs.exists(ydwe / 'YDWE.exe') then
        return ydwe
    end
end
