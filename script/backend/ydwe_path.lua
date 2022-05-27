return function()
    local fs = require 'bee.filesystem'
    do return end
    local f = io.popen([[reg query "HKEY_CURRENT_USER\SOFTWARE\Classes\YDWEMap\shell\run_war3\command"]], 'r')
    if not f then
        return
    end
    local command = f:read 'a'
    f:close()
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
