local mt = {}
mt.__index = mt

function mt:add(format, ...)
    self.hexs[#self.hexs+1] = (format):pack(...)
end

function mt:add_head()
    self:add('c4', 'HM3W')
    self:add('c4', '\0\0\0\0')
end

local function convert_mpq_to_map(content)
    local tbl = setmetatable({}, mt)

    tbl:add_head()
    tbl:add_name()
end

return function (self, map_path, max_file_count)
    local mpq = mpq_create(map_path, max_file_count+1)
    if not mpq then
        return nil
    end
    mpq:close()
    local file = io.load(map_path)
    local content = convert_mpq_to_map(file)
    io.save(map_path, content)
    return mpq_open(map_path)
end
