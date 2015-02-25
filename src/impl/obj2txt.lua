local function obj2txt(self, file_name_in, file_name_out, has_level)
	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	local index = 1

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

		if chunk.obj_count > 0 then
			funcs.next	= funcs.readObj
		end
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
		
		data.value, index	= self.data_type_format[data.type]:unpack(content, index)
		data.value	= self.value2txt(data.value, data.id)

		index	= index + 4	--忽略掉后面4位的标识符

		table.insert(datas, data)
		if data.level then
			if not datas[data.id] then
				datas[data.id] = {}
				table.insert(datas, data)
			end
			datas[data.id][data.level] = data
		else
			table.insert(datas, data)
		end
		
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
	local output = [[
return
{
%s
}
]]

	--转换块
	local function insert_chunks(chunks)
		
		local function insert_chunk(chunk)

			local function insert_obj(obj)

				local lines = string.create_lines(3)
				
				--obj的id
				if obj.id ~= obj.origin_id then
					lines '_id="%s"' (obj.origin_id)
				end

				--先排序
				table.sort(obj.datas,
					function(data1, data2)
						return data1.id < data2.id
					end
				)
				
				for _, data in ipairs(obj.datas) do
					if data.level then
					else
						--数据项
						local line = string.create_lines()
						--数据id
						line ('["' .. data.id .. '"]')
						--数据等级
						if data.level then
							line '[%d]' (data.level)
						end
						line '='
						--数据值
						line(tostring(data.value))

						lines(table.concat(line))
					end
				end

				return table.concat(lines, ',\r\n')
			end
		
			local values = string.create_lines(2)

			--先排序
			table.sort(chunk.objs,
				function(obj1, obj2)
					return obj1.id < obj2.id
				end
			)
			
			for _, obj in ipairs(chunk.objs) do
				values '["%s"]={\r\n%s' (obj.id, insert_obj(obj))
				values '}'
			end
			return table.concat(values, ',\r\n')
		end
	
		local values = string.create_lines(1)
		
		values '%s=%s' ('["VERSION"]', ver)
		values '["ORIGIN"]={\r\n%s' (insert_chunk(chunks[1]))
		values '}'
		values '["CUSTOM"]={\r\n%s' (insert_chunk(chunks[2]))
		values '}'

		return table.concat(values, ',\r\n')
	end

	io.save(file_name_out, output:format(insert_chunks(chunks)):convert_wts() .. '\r\n')

end

return obj2txt
