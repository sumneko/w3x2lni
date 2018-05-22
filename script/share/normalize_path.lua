require 'filesystem'
local root = fs.current_path()

return function (path)
    path = fs.path(path)
    if not path:is_absolute() then
        if _W2L_DIR then
            path = fs.path(_W2L_DIR) / path
        else
            path = root:parent_path() / path
        end
    end
    return fs.absolute(path)
end
