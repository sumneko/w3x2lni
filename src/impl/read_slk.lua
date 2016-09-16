local mt = {}
mt.__index = mt

mt.current_y = 0

function mt:add_table(x, y, k)
	if y then
		self.current_y = y
	else
		y = self.current_y
	end
	if not self[x] then
		self[x] = {}
	end
	if k:sub(1, 1) == '"' and k:sub(-1, -1) == '"' then
		k = k:sub(2, -2)
	else
		k = tonumber(k)
	end
	self[x][y] = k
end

function mt:read_line(line)
	local strs = {}
	for str in line:gmatch '[^;]+' do
		table.insert(strs, str)
	end
	if strs[1] ~= 'C' then
		return
	end
	local x, y, k
	for i = 2, #strs do
		local key = strs[i]:sub(1, 1)
		if key == 'X' then
			x = tonumber(strs[i]:sub(2, -1))
		elseif key == 'Y' then
			y = tonumber(strs[i]:sub(2, -1))
		elseif key == 'K' then
			k = strs[i]:sub(2, -1)
		end
	end
	self:add_table(x, y, k)
end

local function read_slk(file_name)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end

	local data = setmetatable({}, mt)

	-- 解析meta文件
	for line in content:gmatch '%C+' do
		data:read_line(line)
	end

	for key in pairs(mt) do
		data[key] = nil
	end

	-- 组装成table
    local tbl = {}
	local list = {}
	for y, id in pairs(data[1]) do
        if y ~= 1 then
            tbl[id] = {}
            for x, list in pairs(data) do
                local key = list[1] or x
                tbl[id][key] = list[y]
            end
			table.insert(list, id)
        end
	end
    return tbl, list
end

return read_slk
