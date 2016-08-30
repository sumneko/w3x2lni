local read_obj = require 'impl.read_obj'

local function convert_lni(tbl)
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
end

local function obj2txt(self, file_name_in, file_name_out, has_level)
	local content = io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	local data = read_obj(content, has_level)

	local content = convert_lni(data)
	--content = self:convert_wts(content)

	io.save(file_name_out, content)
end

return obj2txt
