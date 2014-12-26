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

--将txt的值根据内部类型转化
local function txt2value(meta_list, value, id)
	local type	= value_type[meta_list[id].type]
	if type == 'int' then
		return value, 0
	elseif type == 'real' then
		return value, 1
	elseif type == 'unreal' then
		return value, 2
	end
	return value, 3
end

local function txt2obj(self, file_name_in, file_name_out, has_level)
	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	local pack = {}
	local chunks, chunk, objs, obj, datas, data
	local funcs
	funcs	= {
		--版本号
		function (line)
			pack.ver	= line:match 'VERSION%=(.+)'
			if pack.ver then
				chunks	= {}
				pack.chunks	= chunks
				table.remove(funcs, 1)
				return true
			end
		end,

		--块
		function (line)
			local obj_count	= line:match '^%s*%[%s*CHUNK%s*%]%s*$'
			if obj_count then
				chunk	= {}
				objs	= {}
				chunk.objs	= objs

				chunk.obj_count	= obj_count

				table.insert(chunks, chunk)
				return true
			end
		end,

		--当前obj的id
		function (line)
			local str	= line:match '^%s*%[%s*(.-)%s*%]%s*$'
			if not str then
				return
			end

			obj	= {}
			datas	= {}
			obj.datas	= datas

			obj.id, obj.origin_id	= str:match '^(.-)%:(.-)$'
			if not obj.id then
				obj.id, obj.origin_id	= str, str
			end

			table.insert(objs, obj)

			return true
		end,

		--当前obj的data
		function (line)
			local _, last, id	= line:find '^%s*(.-)%s*%='
			if not id then
				return
			end

			data = {}

			--检查是否包含等级信息
			if has_level then
				data.level	= id:match '%[(%d+)%]'
				id	= id:sub(1, 4)
			end

			data.id, data.value	= id, line:sub(last + 1)
			data.value, data.type	= txt2value(self.meta_list, data.value, data.id)
			data.value	= data_type_format[data.type]:pack(data.value)

			if data.type == 3 then
				data.value	= data.value:gsub('@@n', '\r\n'):gsub('@@t', '\t')
			end

			table.insert(datas, data)

			return true
		end,
	}

	--解析文本
	for line in content:gmatch '[^\n\r]+' do
		for _, func in ipairs(funcs) do
			if func(line) then
				break
			end
		end
	end

	--生成2进制文件
	local hexs	= {}
	--版本
	table.insert(hexs, ('l'):pack(pack.ver))
	for _, chunk in ipairs(pack.chunks) do
		--obj数量
		table.insert(hexs, ('l'):pack(#chunk.objs))
		for _, obj in ipairs(chunk.objs) do
			--obj的id与数量
			if obj.origin_id == obj.id then
				obj.id	= '\0\0\0\0'
			end
			table.insert(hexs, ('c4c4l'):pack(obj.origin_id, obj.id, #obj.datas))
			for _, data in ipairs(obj.datas) do
				--data的id与类型
				if #data.id ~= 4 then
					print(data.id)
				end
				table.insert(hexs, ('c4l'):pack(data.id, data.type))
				--data的等级与分类
				if has_level then
					table.insert(hexs, ('ll'):pack(data.level or 0, self.meta_list[data.id].data or 0))
				end
				--data的内容
				table.insert(hexs, data.value)
				--添加一个结束标记
				table.insert(hexs, '\0\0\0\0')
			end
		end
	end

	io.save(file_name_out, table.concat(hexs))
end
return txt2obj
