local mt = {}

function mt:mpq_load(filename)
    if self.mpq_loader then
        return self.mpq_loader(filename)
    end
    return nil
end

function mt:map_load(filename)
    if self.map_loader then
        return self.map_loader(filename)
    end
    return nil
end

function mt:map_save(filename, buf)
    if self.map_saver then
        return self.map_saver(filename, buf)
    end
    return false
end

function mt:set_mpq_loader(func)
    self.mpq_loader = func
end

function mt:set_map_loader(func)
    self.map_loader = func
end

function mt:set_map_saver(func)
    self.map_saver = func
end

return mt
