
require 'filesystem'
local check_lni_mark = require 'share.check_lni_mark'
local root = fs.current_path()

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
    elseif _W2L_MODE == 'CLI' then
        local cur = fs.path(_W2L_DIR)
        while true do
            if fs.exists(cur / '.w3x') then
                if check_lni_mark(io.load(cur / '.w3x')) then
                    path = cur
                    break
                else
                    return nil, 'lni mark failed'
                end
            end
            if cur == cur:parent_path() then
                break
            end
            cur = cur:parent_path()
        end
        if not path then
            return nil, 'no lni'
        end
    else
        return nil, 'no path'
    end
    if path:filename():string() == '.w3x' then
        if check_lni_mark(io.load(path)) then
            return fs.absolute(path:parent_path())
        else
            return fs.absolute(path), 'lni mark failed'
        end
    end
    return fs.absolute(path)
end
