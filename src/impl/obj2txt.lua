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

local function value2txt(meta_list, value, id)
	local type	= meta_list[id].type
	if type == 'real' or type == 'unreal' then
		value = ('%.4f'):format(value)
	end
	return value
end
		
local function obj2txt(self, file_name_in, file_name_out, has_level)
	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	index = 1
	
	local len	= #content
	local lines	= {}

	local ver
	
	local chunks = {}
	local chunk, objs, obj, datas, data

	--解析方法
	local funcs	= {}

	--解析数据头
	function funcs.readHead()
		ver, index	= ('l'):unpack(content, index)

		funcs.next	= funcs.readChunk
	end

	--解析块
	function funcs.readChunk()
		chunk	= {}
		objs	= {}
		chunk.objs	= objs

		chunk.obj_count, index	= ('l'):unpack(content, index)

		table.insert(chunks, chunk)

		funcs.next	= funcs.readObj
	end

	--解析物体
	function funcs.readObj()
		obj	= {}
		datas	={}
		obj.datas	= datas
		obj.origin_id, obj.id, obj.data_count, index	= ('c4c4l'):unpack(content, index)
		if obj.id == '\0\0\0\0' then
			obj.id	= obj.origin_id
		end

		table.insert(objs, obj)

		if obj.data_count > 0 then
			funcs.next	= funcs.readData
		else
			--检查是否将这个chunk中的数据读完了
			if #objs == chunk.obj_count then
				funcs.next	= funcs.readChunk
				return
			end
			funcs.next	= funcs.readObj
		end
	end

	--解析数据
	function funcs.readData()
		data	= {}
		data.id, data.type, index	= ('c4l'):unpack(content, index)

		--是否包含等级信息
		if has_level then
			data.level, _, index	= ('ll'):unpack(content, index)
			if data.level == 0 then
				data.level	= nil
			end
		end
		
		data.value, index	= data_type_format[data.type]:unpack(content, index)
		data.value	= value2txt(self.meta_list, data.value, data.id)
		if data.type == 3 then
			data.value	= data.value:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t')
		end
		index	= index + 4	--忽略掉后面4位的标识符

		table.insert(datas, data)

		--检查是否将这个obj中的数据读完了
		if #datas == obj.data_count then
			--检查是否将这个chunk中的数据读完了
			if #objs == chunk.obj_count then
				funcs.next	= funcs.readChunk
				return
			end
			funcs.next	= funcs.readObj
			return
		end
	end

	funcs.next	= funcs.readHead

	--开始解析
	repeat
		funcs.next()
	until index >= len or not funcs.next

	--转换文本
	--版本
	table.insert(lines, ('%s=%s'):format('VERSION', ver))
	for _, chunk in ipairs(chunks) do
		--chunk标记
		table.insert(lines, '[CHUNK]')
		for _, obj in ipairs(chunk.objs) do
			--obj的id
			if obj.id == obj.origin_id then
				table.insert(lines, ('[%s]'):format(obj.id))
			else
				table.insert(lines, ('[%s:%s]'):format(obj.id, obj.origin_id))
			end
			for _, data in ipairs(obj.datas) do
				--数据项
				local line = {}
				--数据id
				table.insert(line, data.id)
				--数据等级
				if data.level then
					table.insert(line, ('[%d]'):format(data.level))
				end
				table.insert(line, '=')
				--数据值
				table.insert(line, data.value)
				table.insert(lines, table.concat(line))
			end
		end
	end

	io.save(file_name_out, table.concat(lines, '\r\n'):convert_wts())

end

return obj2txt
