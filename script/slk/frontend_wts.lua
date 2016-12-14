local table_insert = table.insert

local mt = {}
mt.__index = mt

function mt:load(content, only_short, read_only)
	local wts = self.wts
	return content:gsub('TRIGSTR_(%d+)', function(i)
		local str_data = wts[i]
		if not str_data then
			message('警告: 没有找到字符串:', i)
			return
		end
		local text = str_data.text
		if only_short and #text > 256 then
			return
		end
		str_data.converted = not read_only
		return text
	end)
end

function mt:insert(value)
	local wts = self.wts
	for i = self.lastindex, 999999 do
		local index = ('%03d'):format(i)
		if not wts[index] then
			self.lastindex = i + 1
			wts[index] = {
				index  = i,
				text   = value,
			}
			table_insert(wts, wts[index])
			return 'TRIGSTR_' .. i
		end
	end
	message('错误: 保存在wts里的字符串太多了')
end

function mt:save(data)
	for key, value in pairs(data) do
		if type(value) == 'string' then
			if #value >= 1024 then
				data[key] = self:insert(value)
			end
		elseif type(value) == 'table' then
			self:save(value)
		end
	end
end

function mt:refresh()
	local lines	= {}
	for i, t in ipairs(self.wts) do
		if t and not t.converted then
			table_insert(lines, ('STRING %d\r\n{\r\n%s\r\n}'):format(t.index, t.text))
		end
	end

	return table.concat(lines, '\r\n\r\n')
end

-- TODO: 待重构，数据和操作分离 
return function (w2l, archive)
	local buf = archive:get('war3map.wts')
	if not buf then
		return
	end
	local tbl = {}
	for string in buf:gmatch 'STRING.-%c*%}' do
		local i, s = string:match 'STRING (%d+).-%{\r\n(.-)%\r\n}'
		local t	= {
			index	= i,
			text	= s,
		}
		table_insert(tbl, t)
		tbl[('%03d'):format(i)] = t	--这里的索引是字符串
	end
	return setmetatable({ wts = tbl, lastindex = 0 }, mt)
end
