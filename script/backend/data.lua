require 'utility'

local root = fs.current_path():parent_path()

return function (dir)
    return function(filename)
        return io.load(root / 'data' / dir / filename)
    end
end
