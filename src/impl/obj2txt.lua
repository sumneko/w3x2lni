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

		--分为原始数据与用户数据2块
		for i = 1, 2 do
			funcs.readChunk()
		end
	end

	--解析块
	function funcs.readChunk()
		chunk	= {}
		objs	= {}
		chunk.objs	= objs

		chunk.obj_count, index	= ('l'):unpack(content, index)

		table.insert(chunks, chunk)

		for i = 1, chunk.obj_count do
			funcs.readObj()
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

		for i = 1, obj.data_count do
			funcs.readData()
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

		if data.level then
			if not datas[data.id] then
				datas[data.id] = {id = data.id, level = true}
				table.insert(datas, datas[data.id])
			end
			table.insert(datas[data.id], data)
		else
			table.insert(datas, data)
		end
	end
	
	--开始解析
	funcs.readHead()

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
				
				--先排序
				table.sort(obj.datas,
					function(data1, data2)
						return data1.id < data2.id
					end
				)
				
				for _, data in ipairs(obj.datas) do
					if data.level then
						local function insert_levels(data)
							local lines = string.create_lines(4)

							for lv, data in ipairs(data) do
								lines '[%d]=%s' (lv, tostring(data.value))
							end

							return table.concat(lines, ',\r\n')
						end
						
						lines '%s={\r\n%s' (data.id, insert_levels(data))
						lines '}'
						
					else
						--数据项
						local line = string.create_lines()
						--数据id
						line (data.id)
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
				--obj的id
				local id = obj.id
				if obj.id ~= obj.origin_id then
					id = id .. '_' .. obj.origin_id
				end
				values '%s={\r\n%s' (id, insert_obj(obj))
				values '},'
			end
			return table.concat(values, '\r\n')
		end
	
		local values = string.create_lines(1)
		
		values '%s=%s,' ('VERSION', ver)
		values 'ORIGIN={\r\n%s' (insert_chunk(chunks[1]))
		values '},'
		values 'CUSTOM={\r\n%s' (insert_chunk(chunks[2]))
		values '},'

		return table.concat(values, '\r\n')
	end

	io.save(file_name_out, output:format(insert_chunks(chunks)):convert_wts() .. '\r\n')

end

return obj2txt
