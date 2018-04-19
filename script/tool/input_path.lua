
require 'filesystem'
local check_lni_mark = require 'tool.check_lni_mark'

return function (path)
    if path then
        path = fs.path(path)
        if not path:is_absolute() then
            if _W2L_DIR then
                path = fs.path(_W2L_DIR) / path
            else
                path = root:parent_path() / path
            end
        end
    elseif _W2L_DIR then
        path = fs.path(_W2L_DIR)
    else
        return nil
    end
    path = fs.canonical(path)
    local cur = path
    while fs.is_directory(cur) do
        if check_lni_mark(cur / '.w3x') then
            path = cur
            break
        end
        cur = cur:parent_path()
    end
    if check_lni_mark(cur) then
        path = path:parent_path()
    end
    return path
end
