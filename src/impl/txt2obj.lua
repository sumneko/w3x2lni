local index

--string.pack/string.unpack的参数
local data_type_format	= {}
data_type_format[0]	= 'l'	--4字节有符号整数
data_type_format[1] = 'f'	--4字节无符号浮点
data_type_format[2] = 'f'	--4字节有符号浮点
data_type_format[3] = 'z'	--以\0结尾的字符串

setmetatable(data_type_format,
	{
		__index	= function(_, i)
			print(i, ('%x'):format(index - 2))
		end
	}
)

local value_type = {
	int			= 'int',
	bool		= 'int',
	unreal		= 'unreal',
	real		= 'real',
	deathType	= 'int',
	attackBits	= 'int',
	teamColor	= 'int',
	fullFlags	= 'int',
	channelType	= 'int',
	channelFlags= 'int',
	stackFlags	= 'int',
	silenceFlags= 'int',
	spellDetail	= 'int',
}
setmetatable(value_type,
	{
		__index	= function()
			return 'string'
		end,
	}
)

--将key的值根据内部类型转化
local function getKeyType(self, key)
	local type	= value_type[self.meta_list[key].type]
	if type == 'int' then
		return 0
	elseif type == 'real' then
		return 1
	elseif type == 'unreal' then
		return 2
	end
	return 3
end

local function txt2obj(self, file_name_in, file_name_out, has_level)
	local file = io.load(file_name_in)
	if not file then
		print('文件错误:' .. file_name_in:string())
		return
	end

	local func, err = load(file)
	if not func then
		print(err)
		return
	end

	local pack = func()

	--生成2进制文件
	local hexs	= {}
	--版本
	table.insert(hexs, ('l'):pack(pack.VERSION))
	for _, chunk in ipairs{pack.ORIGIN, pack.CUSTOM} do
		--obj数量
		table.insert(hexs, ('l'):pack(table.hash_to_array(chunk)))
		for _, id, obj in pairs(chunk) do
			--obj的id与数量
			local _id
			if #id > 4 then
				id, _id = id:sub(1, 4), id:sub(-4, -1)
			end
			table.hash_to_array(obj)
			local count = 0
			local pos = #hexs + 1
			for _, key, data in pairs(obj) do
				if #key ~= 4 then
					if #key < 4 then
						key = key .. ('\0'):rep(4 - #key)
					else
						print(key)
					end
				end
				--是否有等级
				if type(data) == 'table' then
					for lv in ipairs(data) do
						--data的id与类型
						local key_type = getKeyType(self, key)
						table.insert(hexs, ('c4l'):pack(key, key_type))
						--data的等级与分类
						if has_level then
							table.insert(hexs, ('ll'):pack(lv, self.meta_list[key].data or 0))
						end
						--data的内容
						table.insert(hexs, data_type_format[key_type]:pack(data[lv]))
						--添加一个结束标记
						table.insert(hexs, '\0\0\0\0')
						count = count + 1
					end
				else
					--data的id与类型
					local key_type = getKeyType(self, key)
					table.insert(hexs, ('c4l'):pack(key, key_type))
					--data的等级与分类
					if has_level then
						table.insert(hexs, ('ll'):pack(0, self.meta_list[key].data or 0))
					end
					--data的内容
					table.insert(hexs, data_type_format[key_type]:pack(data))
					--添加一个结束标记
					table.insert(hexs, '\0\0\0\0')
					count = count + 1
				end

			end
			table.insert(hexs, pos, ('c4c4l'):pack(_id or id, _id and id or '\0\0\0\0', count))
		end
	end

	io.save(file_name_out, table.concat(hexs))
end
return txt2obj
