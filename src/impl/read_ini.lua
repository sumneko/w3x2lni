local mt = {}
setmetatable(mt, mt)
mt._parsers = {}

mt.__index = mt

function mt:__newindex(key, value)
    if key == 'parser' then
        table.insert(self._parsers, value)
        return
    end
    rawset(self, key, value)
end

function mt:__call(line)
    for _, parser in ipairs(self._parsers) do
        local suc, new_line = parser(self, line)
        if suc then
            return
        else
            line = new_line or line
        end
    end
end

function mt:parser(line)
    if #line == 0 then
        return true
    end
end

function mt:parser(line)
    if line:sub(1, 2) == '//' then
        return true
    end
end

function mt:parser(line)
    local chunk_name = line:match '%[(.-)%]'
    if chunk_name then
        self.current_chunk = chunk_name
        if not self.ini[chunk_name] then
            self.ini[chunk_name] = {}
        end
        return true
    end
end

function mt:parser(line)
    if not self.current_chunk then
        return true
    end
    line = line:gsub('%c+', '')
    local key, value = line:match '^%s*(.-)%s*%=%s*(.-)%s*$'
    if key and value then
        self.ini[self.current_chunk][key] = value
        return true
    end
end

local function read_ini(file_name)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end

    local self = setmetatable({}, mt)
    self.ini = {}
    
	for line in io.lines2(file_name) do
        self(line)
    end

    return self.ini
end

return read_ini
