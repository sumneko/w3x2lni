local table_insert = table.insert
local pairs = pairs
local setmetatable = setmetatable

local x, y, k

local function read_line(slk, line)
	if line:byte(1) ~= 67 then
		return
	end
	for str in line:gmatch '[^;]+' do
		local key = str:byte(1)
		if key == 88 then
			x = tonumber(str:sub(2, -1))
		elseif key == 89 then
			y = tonumber(str:sub(2, -1))
		elseif key == 75 then
			if str:byte(2) == 34 and str:byte(-1) == 34 then
				k = str:sub(3, -2)
			else
				k = tonumber(str:sub(2, -1))
			end
		end
	end
	if not slk[x] then
		slk[x] = {}
	end
	slk[x][y] = k
end

local function read_slk(w2l, content)
	if not content then
		return
	end

	local data = {}
	x, y, k = nil, nil, nil

	-- 解析meta文件
	for line in content:gmatch '%C+' do
		read_line(data, line)
	end

	-- 组装成table
	local t_mt = {}
	local list = {}
	function t_mt:__pairs()
		local i = 0
		return function()
			i = i + 1
			if not list[i] then
				return nil
			end
			return list[i], self[list[i]]
		end
	end
	
    local tbl = setmetatable({}, t_mt)
	for y, id in pairs(data[1]) do
        if y ~= 1 then
            tbl[id] = {}
            for x, list in pairs(data) do
                local key = list[1]
				if key then
                	tbl[id][key] = list[y]
				end
            end
			table_insert(list, id)
        end
	end
    return tbl
end

return read_slk
