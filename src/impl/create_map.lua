local mt = {}
mt.__index = mt

function mt:add(format, ...)
    self.hexs[#self.hexs+1] = (format):pack(...)
end

function mt:add_head()
    self:add('c4', 'HM3W')
    self:add('c4', '\0\0\0\0')
end

function mt:add_name()
    self:add('z', self.w3i.map_name)
end

function mt:add_flag()
    self:add('l', self.w3i.map_flag)
end

function mt:add_playercount()
    self:add('l', 23333)
end

local function convert_mpq_to_map(content, w3i)
    local tbl = setmetatable({}, mt)

    tbl.hexs = {}
    tbl.w3i  = w3i

    tbl:add_head()
    tbl:add_name()
    tbl:add_flag()
    tbl:add_playercount()
    
    local head = table.concat(tbl.hexs)
    return head .. string.rep('\0', 512 - #head) .. content
end

return function (self, map_path, max_file_count, w3i)
    local mpq = mpq_create(map_path, max_file_count+8)
    if not mpq then
        return nil
    end
    mpq:close()
    local file = io.load(map_path)
    fs.remove(map_path)
    local content = convert_mpq_to_map(file, w3i)
    io.save(map_path, content)
    return mpq_open(map_path)
end
