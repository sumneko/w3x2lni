local mt = {}
mt.__index = mt

function mt:close()
end

function mt:extract(name, path)
    return fs.copy_file(self.path / name, path, true)
end

function mt:has_file(name)
    return fs.exists(self.path / name)
end

function mt:remove_file(name)
    fs.remove(self.path / name)
end

function mt:load_file(name)
    return io.load(self.path / name)
end

function mt:save_file(name, buf, filetime)
    io.save(self.path / name, buf)
    return true
end

local m = {}
function m.open(path)
    return setmetatable({ path = path }, mt)
end
function m.create(path)
    return setmetatable({ path = path }, mt)
end
return m
