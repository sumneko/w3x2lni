	w3x2txt = {}

	local w3x2txt = w3x2txt

	local function main()
		--读取内部类型
		local meta_list	= {}

		meta_list.default	= {
			type	= 'string',
		}
		
		setmetatable(meta_list,
			{
				__index = function(_, id)
					return rawget(meta_list, 'default')
				end
			}
		)

		function w3x2txt.readMeta(file_name)
			local content	= io.load(file_name)
			if not content then
				print('文件无效:' .. file_name:string())
				return
			end

			for line in content:gmatch '[^\n\r]+' do
				local id	= line:match [[C;.*X1;.*K"(.-)"]]
				if id then
					meta_list.id	= id
					meta_list[id]	= {}
					goto continue
				end
				local x, value	= line:match [[C;X(%d+);K["]*(.-)["]*$]]
				if x then
					if meta_list.id == 'ID' then
						meta_list[x]	= value
					elseif meta_list[x] == 'type' then
						meta_list[meta_list.id].type	= value
					elseif meta_list[x] == 'data' then
						meta_list[meta_list.id].data	= value
					end
				end
				:: continue ::
			end
		end

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

		--将值根据内部类型转化为txt
		local function value2txt(value, id)
			local type	= meta_list[id].type
			if type == 'real' or type == 'unreal' then
				value = ('%.4f'):format(value)
			end
			return value
		end

		--将txt的值根据内部类型转化
		local function txt2value(value, id)
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

		function w3x2txt.obj2txt(file_name_in, file_name_out, has_level)
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
				data.value	= value2txt(data.value, data.id)
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

		function w3x2txt.txt2obj(file_name_in, file_name_out, has_level)
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
					data.value, data.type	= txt2value(data.value, data.id)
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
							table.insert(hexs, ('ll'):pack(data.level or 0, meta_list[data.id].data or 0))
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

		local function_state	= {}

		function w3x2txt.readTriggerData(file_name_in)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local funcs
			funcs	= {
				--检查关键字,判断函数域
				function (line)
					local trigger_type	= line:match '^%[(.+)%]$'
					if not trigger_type then
						return
					end

					if trigger_type	== 'TriggerEvents' then
						trigger_type	= 0
					elseif trigger_type	== 'TriggerConditions' then
						trigger_type	= 1
					elseif trigger_type	== 'TriggerActions' then
						trigger_type	= 2
					elseif trigger_type	== 'TriggerCalls' then
						trigger_type	= 3
					else
						funcs.trigger_type	= nil
						return
					end

					funcs.states	= {}
					funcs.trigger_type	= trigger_type
					function_state[trigger_type]	= funcs.states

				end,

				--检查函数
				function (line)
					if not funcs.trigger_type then
						return
					end

					local name, args	= line:match '^([^_].-)%=(.-)$'
					if not name then
						return
					end

					local state	= {}
					state.name	= name
					state.args	= {}

					for arg in args:gmatch '[^%,]+' do
						--排除部分参数
						if not tonumber(arg) and arg ~= 'nothing' then
							table.insert(state.args, arg)
						end
					end
					--类型为调用时,去掉第一个返回值
					if funcs.trigger_type == 3 then
						table.remove(state.args, 1)
					end

					table.insert(funcs.states, state)
					funcs.states[state.name]	= state
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

		end

		function w3x2txt.wtg2txt(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local index	= 1
			local len	= #content

			local chunk	= {}
			local funcs	= {}
			local categories, category, vars, var, triggers, trigger, ecas, eca, args, arg

			--文件头
			function funcs.readHead()
				chunk.file_id,			--文件ID
				chunk.file_ver,			--文件版本
				index	= ('c4l'):unpack(content, index)
			end

			--触发器类别(文件夹)
			function funcs.readCategories()
				--触发器类别数量
				chunk.category_count, index	= ('l'):unpack(content, index)

				--初始化
				categories	= {}
				chunk.categories	= categories

				for i = 1, chunk.category_count do
					funcs.readCategory()
				end
			end

			function funcs.readCategory()
				category	= {}
				category.id, category.name, category.comment, index	= ('lzl'):unpack(content, index)

				table.insert(categories, category)
			end

			--全局变量
			function funcs.readVars()
				--全局变量数量
				chunk.int_unknow_1, chunk.var_count, index	= ('ll'):unpack(content, index)
				
				--初始化
				vars	= {}
				chunk.vars	= vars

				for i = 1, chunk.var_count do
					funcs.readVar()
				end
			end

			function funcs.readVar()
				var	= {}
				var.name,		--变量名
				var.type,		--变量类型
				var.int_unknow_1,	--(永远是1,忽略)
				var.is_array,	--是否是数组(0不是, 1是)
				var.array_size,	--数组大小(非数组是1)
				var.is_default,	--是否是默认值(0是, 1不是)
				var.value,		--初始数值
				index = ('zzllllz'):unpack(content, index)

				table.insert(vars, var)
				vars[var.name]	= var
			end

			--触发器
			function funcs.readTriggers()
				--触发器数量
				chunk.trigger_count, index	= ('l'):unpack(content, index)

				--初始化
				triggers	= {}
				chunk.triggers	= triggers

				for i = 1, chunk.trigger_count do
					funcs.readTrigger()
				end
			end

			function funcs.readTrigger()
				trigger	= {}
				trigger.name,		--触发器名字
				trigger.des,		--触发器描述
				trigger.type,		--类型(0普通, 1注释)
				trigger.enable,		--是否允许(0禁用, 1允许)
				trigger.wct,		--是否是自定义代码(0不是, 1是)
				trigger.init,		--是否初始化(0是, 1不是)
				trigger.run_init,	--地图初始化时运行
				trigger.category,	--在哪个文件夹下
				index	= ('zzllllll'):unpack(content, index)

				table.insert(triggers, trigger)
				--print('trigger:' .. trigger.name)
				--读取子结构
				funcs.readEcas()

			end

			--子结构
			function funcs.readEcas()
				--子结构数量
				trigger.eca_count, index	= ('l'):unpack(content, index)

				--初始化
				ecas	= {}
				trigger.ecas	= ecas

				for i = 1, trigger.eca_count do
					funcs.readEca()
				end
			end

			function funcs.readEca(is_child, is_arg)
				eca	= {}
				local eca	= eca
				
				eca.type,	--类型(0事件, 1条件, 2动作, 3函数调用)
				index	= ('l'):unpack(content, index)

				--是否是复合结构
				if is_child then
					eca.child_id, index	= ('l'):unpack(content, index)
				end

				--是否是参数中的子函数
				if is_arg then
					is_arg.eca	= eca
				else
					table.insert(ecas, eca)
				end
				
				eca.name,	--名字
				eca.enable,	--是否允许(0不允许, 1允许)
				index	= ('zl'):unpack(content, index)

				--print('eca:' .. eca.name)
				--读取参数
				funcs.readArgs(eca)

				--if,loop等复合结构
				eca.child_eca_count, index	= ('l'):unpack(content, index)
				for i = 1, eca.child_eca_count do
					funcs.readEca(true)
				end
			end

			--参数
			function funcs.readArgs(eca)
				--初始化
				args	= {}
				local args	= args
				eca.args	= args

				--print(eca.type, eca.name)
				local state_args	= function_state[eca.type][eca.name].args
				local arg_count	= #state_args

				--print('args:' .. arg_count)

				for i = 1, arg_count do
					funcs.readArg(args)
				end

			end

			function funcs.readArg(args)
				arg	= {}

				arg.type, 			--类型(0预设, 1变量, 2函数, 3代码)
				arg.value,			--值
				arg.insert_call,	--是否需要插入调用
				index	= ('lzl'):unpack(content, index)
				--print('var:' .. arg.value)

				--是否是索引
				table.insert(args, arg)

				--插入调用
				if arg.insert_call == 1 then
					funcs.readEca(false, arg)
					arg.int_unknow_1, index	= ('l'):unpack(content, index) --永远是0
					--print(arg.int_unknow_1)
					return
				end

				arg.insert_index,	--是否需要插入数组索引
				index	= ('l'):unpack(content, index)

				--插入数组索引
				if arg.insert_index == 1 then
					funcs.readArg(args)
				end
			end

			--开始解析
			do
				funcs.readHead()
				funcs.readCategories()
				funcs.readVars()
				funcs.readTriggers()
			end

			--开始转化文本
			local lines	= {}
			
			do
				--版本
				table.insert(lines, ('VERSION=%d'):format(chunk.file_ver))
				table.insert(lines, ('未知1=%s'):format(chunk.int_unknow_1))

				--全局变量
				table.insert(lines, '【Global】')
				for i, var in ipairs(chunk.vars) do
					if var.is_array == 1 then
						if var.value ~= '' then
							table.insert(lines, ('%s %s[%d]=%s'):format(var.type, var.name, var.array_size, var.value))
						else
							table.insert(lines, ('%s %s[%d]'):format(var.type, var.name, var.array_size))
						end
					else
						if var.value ~= '' then
							table.insert(lines, ('%s %s=%s'):format(var.type, var.name, var.value))
						else
							table.insert(lines, ('%s %s'):format(var.type, var.name))
						end
					end
				end

				--触发器类别(文件夹)
				table.insert(lines, '【Category】')
				for _, category in ipairs(chunk.categories) do
					table.insert(lines, ('[%s](%d)%s'):format(
						category.name,
						category.id,
						category.comment == 1 and '*' or ''
					))
				end

				--ECA结构
				local tab	= 1
				local ecas, index, max
				
				local function push_eca(eca, is_arg)
					--print(index, eca, is_arg, max)
					table.insert(lines, ('%s%s[%d]%s%s:%s'):format(
						('\t'):rep(tab),
						eca.child_id and ('(%d)'):format(eca.child_id) or '',
						eca.type,
						eca.child_eca_count == 0 and '' or ('<%d>'):format(eca.child_eca_count),
						(eca.enable == 0 and '*') or (is_arg and '#') or '',
						eca.name
					))
					--参数
					tab = tab + 1
					for _, arg in ipairs(eca.args) do
						if arg.insert_call == 1 then
							push_eca(arg.eca, true)
						else
							table.insert(lines, ('%s[%d]%s:%s'):format(
								('\t'):rep(tab),
								arg.type,
								(arg.insert_index == 1 or arg.insert_call == 1) and '*' or '',
								arg.value:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t')
							))
						end
					end
					tab = tab - 1
					if eca.child_eca_count ~= 0 then
						--print(eca.name, eca.child_eca_count)
						tab	= tab + 1
						for i = 1, eca.child_eca_count do
							local eca	= ecas[index]
							index	= index + 1
							push_eca(eca)
						end
						tab	= tab - 1
					end
					
				end

				--触发器
				table.insert(lines, '【Trigger】')
				for _, trigger in ipairs(chunk.triggers) do
					table.insert(lines, ('<%s>'):format(trigger.name))
					table.insert(lines, ('描述=%s'):format(trigger.des:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t')))
					table.insert(lines, ('类型=%s'):format(trigger.type))
					table.insert(lines, ('允许=%s'):format(trigger.enable))
					table.insert(lines, ('自定义代码=%s'):format(trigger.wct))
					table.insert(lines, ('初始化=%s'):format(trigger.init))
					table.insert(lines, ('初始化运行=%s'):format(trigger.run_init))
					table.insert(lines, ('类别=%s'):format(trigger.category))

					ecas	= trigger.ecas
					index	= 1
					max		= #ecas

					--ECA结构
					while index <= max do
						local eca	= ecas[index]
						index	= index + 1
						push_eca(eca)
					end
				end
				
			end

			io.save(file_name_out, table.concat(lines, '\r\n'):convert_wts(true))

			--io.save(file_name_out, table.concat(lines, '\r\n'))	--貌似wtg文件写入文本会出错
		end

		function w3x2txt.txt2wtg(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local index = 0
			local line
			local function read()
				local _
				_, index, line	= content:find('(%C+)', index + 1)
				if line and line:match '^%s*$' then
					return read()
				end
				return line
			end

			local chunk = {}
			
			--解析文本
			do
				--版本号
				repeat
					read()
					chunk.file_ver	= line:match 'VERSION%=(.+)'
				until chunk.file_ver

				--块
				local chunk_type, trigger
				while read() do
					--local line	= line
					local name	= line:match '^%s*【%s*(%S-)%s*】%s*$'
					if name then
						chunk_type	= name
						if name == 'Global' then
							chunk.vars	= {}
						elseif name == 'Category' then
							chunk.categories	= {}
						elseif name == 'Trigger' then
							chunk.triggers	= {}
						end
						goto continue
					end

					--全局变量
					if chunk_type	== 'Global' then
						
						local type, s	= line:match '^%s*(%S-)%s+(.+)$'
						if not type then
							goto continue
						end

						local var	= {}
						table.insert(chunk.vars, var)

						var.type	= type
						var.name, s	= s:match '^([%w_]+)(.*)$'
						if s then
							var.array_size	= s:match '%[%s*(%d+)%s*%]'
							var.value	= s:match '%=(.-)$'
						end

						--print(var.type, var.name, var.array_size, var.value)
						goto continue
					end

					--触发器类型(文件夹)
					if chunk_type	== 'Category' then
						
						local name, id, comment	= line:match '^%s*%[(.-)%]%(%s*(%d+)%s*%)%s*([%*]*)%s*$'
						if not name then
							goto continue
						end
						
						local category	 = {}
						table.insert(chunk.categories, category)

						category.name, category.id, category.comment	= name, id, comment == '*' and 1 or 0
						--print(name, id)

						goto continue
					end

					--触发器
					if chunk_type	== 'Trigger' then
						--读取ECA(最优先解读)
						local readEca, readArg

						function readEca(is_arg, is_child)
							local eca_args, value	= line:match '^[\t]*(.-)%:(.-)$'

							--print('line:' .. line)
							if value then
								local eca	= {}

								--eca名字
								eca.name	= value

								--eca类型
								eca.type	= tonumber(eca_args:match '%[%s*(%d+)%s*%]')
								
								--是否包含复合结构
								eca.child_eca_count	= eca_args:match '%<%s*(%d+)%s*%>'

								if is_arg then
									--是否是参数
									is_arg.eca	= eca
								elseif is_child then
									--是否是子项
									table.insert(is_child, eca)

									--子项ID
									eca.child_id	= eca_args:match '%(%s*(%d+)%s*%)'
								else
									table.insert(trigger.ecas, eca)
								end

								--是否允许
								eca.enable	= eca_args:match '[%*%#]'

								--读取这个ECA下有多少参数
								--print(eca.type, eca.name)
								local state_args	= function_state
								[eca.type]
								[eca.name]
								.args
								local arg_count	= #state_args
								--print(arg_count)
								eca.args	= {}

								for i = 1, arg_count do
									readArg(eca.args)
								end

								--读取这个ECA下有多少子项
								if eca.child_eca_count then
									eca.child_ecas	= {}
									--print(eca.name, eca.child_eca_count)
									for i = 1, eca.child_eca_count do
										read()
										readEca(false, eca.child_ecas)
									end
								end

								return true
							end
						end

						function readArg(args)
							local arg_args, value 	= read():match '^[\t]*(.-)%:(.-)$'
							if value then
								local arg	= {}
								table.insert(args, arg)

								--类型
								arg.type	= tonumber(arg_args:match '%[%s*([%-%d]+)%s*%]')
								arg.value	= value:gsub('@@n', '\r\n'):gsub('@@t', '\t')
								arg.has_child	= arg_args:match '[%*%#]'

								--有子数据
								if arg.has_child == '*' then
									--数组索引
									arg.insert_index	= 1
									--print(has_child .. ':child_index:' .. arg.value)
									arg.args	= {}
									readArg(arg.args)
								elseif arg.has_child == '#' then
									--函数调用
									arg.insert_call		= 1
									--print(has_child .. ':child_call:' .. arg.value)

									--只有在函数调用时,参数中才会保存函数的名字
									if arg.type ~= 3 then
										arg.value = ''
									end
									
									--函数调用的实际type为2
									arg.type	= 2
									readEca(arg)
								end
							end
						end

						if readEca() then
							goto continue
						end
						
						--尝试读取触发器名字
						local name	= line:match '^%s*%<(.-)%>%s*$'
						if name then
							trigger = {}
							table.insert(chunk.triggers, trigger)

							trigger.name	= name
							trigger.ecas	= {}
							
							goto continue
						end

						--读取触发器参数
						local name, s	= line:match '^(.-)%=(.-)$'
						if name then
							trigger[name]	= s:gsub('@@n', '\r\n'):gsub('@@t', '\t')

							goto continue
						end
					end

					--全局数据
					local name, s	= line:match '^(.-)%=(.-)$'
					if name then
						chunk[name]	= s
					end

					:: continue ::
				end
			end

			--转换2进制
			local pack	= {}
			
			do
				--文件头
				table.insert(pack, ('c4l'):pack('WTG!', chunk.file_ver))

				--触发器类别
					--文件夹计数
					table.insert(pack ,('l'):pack(#chunk.categories))
					
					--遍历文件夹
					for _, category in ipairs(chunk.categories) do
						table.insert(pack, ('lzl'):pack(category.id, category.name, category.comment))
					end

				--全局变量
					--计数
					table.insert(pack, ('ll'):pack(chunk['未知1'], #chunk.vars))

					--遍历全局变量
					for _, var in ipairs(chunk.vars) do
						table.insert(pack, ('zzllllz'):pack(
							var.name,					--名字
							var.type,					--类型
							1,							--永远是1
							var.array_size and 1 or 0,	--是否是数组
							var.array_size or 1,		--数组大小(非数组是1)
							var.value and 1 or 0,		--是否有自定义初始值
							var.value or ''				--自定义初始值
						))
					end

				--触发器
					--计数
					table.insert(pack, ('l'):pack(#chunk.triggers))

					--遍历触发器
					for _, trigger in ipairs(chunk.triggers) do
						
						--触发器参数
						table.insert(pack, ('zzllllll'):pack(
							trigger.name,
							trigger['描述'],
							trigger['类型'],
							trigger['允许'],
							trigger['自定义代码'],
							trigger['初始化'],
							trigger['初始化运行'],
							trigger['类别']
						))

						--ECA
							--计数
							table.insert(pack, ('l'):pack(#trigger.ecas))

							--遍历ECA
							local push_eca, push_arg
							
							function push_eca(eca)
								--类型
								table.insert(pack, ('l'):pack(eca.type))

								--如果是复合结构,插入一个整数
								if eca.child_id then
									table.insert(pack, ('l'):pack(eca.child_id))
								end

								--名字,是否允许
								table.insert(pack, ('zl'):pack(eca.name, eca.enable == '*' and 0 or 1))

								--读取参数
								for _, arg in ipairs(eca.args) do
									push_arg(arg)
								end

								--复合结构
								table.insert(pack, ('l'):pack(eca.child_eca_count or 0))

								if eca.child_eca_count then
									for _, eca in ipairs(eca.child_ecas) do
										push_eca(eca)
									end
								end
							end

							function push_arg(arg)
								table.insert(pack, ('lzl'):pack(
									arg.type,				--类型
									arg.value,				--值
									arg.insert_call or 0	--是否插入函数调用
								))

								--是否要插入函数调用
								if arg.insert_call then
									push_eca(arg.eca)

									table.insert(pack, ('l'):pack(0)) --永远是0
									return
								end

								--是否要插入数组索引
								table.insert(pack, ('l'):pack(arg.insert_index or 0))

								if arg.insert_index then
									for _, arg in ipairs(arg.args) do
										push_arg(arg)
									end
								end
								
							end
							
							for _, eca in ipairs(trigger.ecas) do
								push_eca(eca)
							end
					end

				--打包
				io.save(file_name_out, table.concat(pack))
				
			end
		end

		function w3x2txt.wct2txt(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local index = 1
			local max	= #content
			local chunk	= {}

			--文件版本
			chunk.file_ver, index	= ('l'):unpack(content, index)

			chunk.triggers	= {}

			--自定义代码区的注释
			chunk.comment, index		= ('z'):unpack(content, index)

			--自定义代码区的文本
			local trigger	= {}
			table.insert(chunk.triggers, trigger)

			trigger.size, index	= ('l'):unpack(content, index)
			if trigger.size ~= '0' then
				trigger.content, index	= ('z'):unpack(content, index)
			end

			--触发器数量
			chunk.trigger_count, index	= ('l'):unpack(content, index)
			
			for i = 1, chunk.trigger_count do
				local trigger	= {}
				table.insert(chunk.triggers, trigger)

				--文本长度
				trigger.size, index	= ('l'):unpack(content, index)

				--如果文本长度为0,无文本
				if trigger.size == 0 then
					trigger.content	= ''
				else
					trigger.content, index	= ('z'):unpack(content, index)
				end
			end

			--转换文本
			local lines	= {}

			--文件版本
			table.insert(lines, ('VERSION=%s'):format(chunk.file_ver))
			table.insert(lines, ('########\r\n%s\r\n########'):format(chunk.comment))

			--文本
			for _, trigger in ipairs(chunk.triggers) do
				table.insert(lines, ('########\r\n%s\r\n########'):format(trigger.content))
			end

			io.save(file_name_out, table.concat(lines, '\r\n'):convert_wts())
			
		end

		function w3x2txt.txt2wct(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local chunk	= {}
			local index	= 1
			local max	= #content
			--文件头
			chunk.file_ver	= content:match 'VERSION%=(%d+)'

			--遍历文本
			for chars in content:gmatch '########%c*(.-)%c*########' do
				table.insert(chunk, chars)
			end

			--生成二进制文件
			local pack	= {}

			--文件头
			table.insert(pack, ('l'):pack(chunk.file_ver))
			--自定义区域注释
			table.insert(pack, ('z'):pack(chunk[1]))
			--自定义区域文本大小与文本
			if chunk[2] == '' then
				table.insert(pack, ('l'):pack(0))
			else
				table.insert(pack, ('lz'):pack(#chunk[2] + 1, chunk[2]))
			end
			--触发器数量
			table.insert(pack, ('l'):pack(#chunk - 2))
			--触发器文本大小与文本
			for i = 3, #chunk do
				if chunk[i] == '' then
					table.insert(pack, ('l'):pack(0))
				else
					table.insert(pack, ('lz'):pack(#chunk[i] + 1, chunk[i]))
				end
			end

			io.save(file_name_out, table.concat(pack))
			
		end

		function w3x2txt.w3i2txt(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local chunk	= {}
			local index	= 1

			--文件头
			chunk.file_ver,		--文件版本
			chunk.map_ver,		--地图版本(保存次数)
			chunk.editor_ver,	--编辑器版本
			chunk.map_name,		--地图名称
			chunk.author,		--作者名字
			chunk.des,			--地图描述
			chunk.player_rec,	--推荐玩家
			--镜头范围
			chunk.camera_bound_1,
			chunk.camera_bound_2,
			chunk.camera_bound_3,
			chunk.camera_bound_4,
			chunk.camera_bound_5,
			chunk.camera_bound_6,
			chunk.camera_bound_7,
			chunk.camera_bound_8,
			--镜头范围扩充
			chunk.camera_complement_1,
			chunk.camera_complement_2,
			chunk.camera_complement_3,
			chunk.camera_complement_4,

			chunk.map_width,	--地图宽度
			chunk.map_height,	--地图长度
			
			chunk.map_flag,		--地图标记,后面解读

			chunk.map_main_ground_type,	--地形类型

			chunk.loading_screen_id,	--载入图ID(-1表示导入载入图)
			chunk.loading_screen_path,	--载入图路径
			chunk.loading_screen_text,	--载入界面文本
			chunk.loading_screen_title,	--载入界面标题
			chunk.loading_screen_subtitle,	--载入图子标题

			chunk.game_data_set,	--使用游戏数据设置

			chunk.prologue_screen_path,		--序幕路径
			chunk.prologue_screen_text,		--序幕文本
			chunk.prologue_screen_title,	--序幕标题
			chunk.prologue_screen_subtitle,	--序幕子标题

			chunk.terrain_fog,	--地形迷雾
			chunk.fog_start_z,	--迷雾开始z轴
			chunk.fog_end_z,	--迷雾结束z轴
			chunk.fog_density,	--迷雾密度
			chunk.fog_red,		--迷雾红色
			chunk.fog_green,	--迷雾绿色
			chunk.fog_blue,		--迷雾蓝色
			chunk.fog_alpha,	--迷雾透明
			
			chunk.weather_id,	--全局天气

			chunk.sound_environment,	--环境音效
			chunk.light_environment,	--环境光照

			chunk.water_red,	--水红色
			chunk.water_green,	--水绿色
			chunk.water_blue,	--水蓝色
			chunk.water_alpha,	--水透明

			index	= ('lllzzzzfffffffflllllllc1lzzzzlzzzzlfffBBBBc4zc1BBBB'):unpack(content, index)

			--玩家数据
			chunk.player_count, index	= ('l'):unpack(content, index)
			chunk.players	= {}
			for i = 1, chunk.player_count do
				local player	= {}
				table.insert(chunk.players, player)

				player.id,
				player.type,			--玩家类型(1玩家,2电脑,3野怪,4可营救)
				player.race,			--玩家种族
				player.start_position,	--修正出生点
				player.name,
				player.start_x,
				player.start_y,
				player.ally_low_flag,	--低结盟优先权标记
				player.ally_high_flag,	--高结盟优先权标记
				index	= ('llllzffll'):unpack(content, index)
			end

			--队伍数据
			chunk.force_count, index	= ('l'):unpack(content, index)
			chunk.forces	= {}
			for i = 1, chunk.force_count do
				local force	= {}
				table.insert(chunk.forces, force)

				force.force_flag,	--队伍标记
				force.player_flag,	--包含玩家
				force.name,
				index	= ('llz'):unpack(content, index)
			end

			--可用升级数据
			chunk.upgrade_count, index	= ('l'):unpack(content, index)
			chunk.upgrades	= {}
			for i = 1, chunk.upgrade_count do
				local upgrade	= {}
				table.insert(chunk.upgrades, upgrade)

				upgrade.player_flag,	--包含玩家
				upgrade.id,				--4位ID
				upgrade.level,			--等级
				upgrade.available,		--可用性
				index	= ('lc4ll'):unpack(content, index)
			end

			--可用科技数据
			chunk.tech_count, index	= ('l'):unpack(content, index)
			chunk.techs	= {}
			for i = 1, chunk.tech_count do
				local tech	= {}
				table.insert(chunk.techs, tech)

				tech.player_flag,	--包含玩家
				tech.id,			--4位ID
				index	= ('lc4'):unpack(content, index)
			end

			--随机组
			chunk.group_count, index	= ('l'):unpack(content, index)
			chunk.groups	= {}
			for i = 1, chunk.group_count do
				local group	= {}
				table.insert(chunk.groups, group)

				group.id,
				group.name,
				index	= ('lz'):unpack(content, index)

				--位置
				group.position_count,
				index	= ('l'):unpack(content, index)

				group.positions	= {}
				for i = 1, group.position_count do
					group.positions[i], index	= ('l'):unpack(content, index)
				end

				--设置
				group.line_count,
				index	= ('l'):unpack(content, index)
				
				group.lines	= {}
				for i = 1, group.line_count do
					local line	= {}
					table.insert(group.lines, line)

					line.chance,
					index	= ('l'):unpack(content, index)

					--id列举
					line.ids	= {}
					for i = 1, group.position_count do
						line.ids[i], index	= ('c4'):unpack(content, index)
					end
				end
				
			end

			--物品列表
			chunk.random_item_count, index	= ('l'):unpack(content, index)
			chunk.random_items	= {}

			for i = 1, chunk.random_item_count do
				local random_item	= {}
				table.insert(chunk.random_items, random_item)

				random_item.id,
				random_item.name,
				index	= ('lz'):unpack(content, index)

				--设置
				random_item.set_count, index	= ('l'):unpack(content, index)
				random_item.sets	= {}
				for i = 1, random_item.set_count do
					local set	= {}
					table.insert(random_item.sets, set)

					--物品
					set.item_count, index	= ('l'):unpack(content, index)
					set.items	= {}

					for i = 1, set.item_count do
						local item	= {}
						table.insert(set.items, item)

						item.chance,
						item.id,
						index	= ('lc4'):unpack(content, index)
					end
				end
			end

			--转换txt文件
			local lines	= {}

			local function push(format)
				return function (...)
					table.insert(lines, format:format(...))
				end
			end

			--文件头
			push 'VERSION=%s'	(chunk.file_ver)
			push '地图版本=%s'	(chunk.map_ver)
			push '编辑器版本=%s'	(chunk.editor_ver)
			push '地图名称=%s'	(chunk.map_name)
			push '作者名字=%s'	(chunk.author)
			push '地图描述=%s'	(chunk.des:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '推荐玩家=%s'	(chunk.player_rec:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '镜头范围=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f'	(
				chunk.camera_bound_1,
				chunk.camera_bound_2,
				chunk.camera_bound_3,
				chunk.camera_bound_4,
				chunk.camera_bound_5,
				chunk.camera_bound_6,
				chunk.camera_bound_7,
				chunk.camera_bound_8
			)
			push '镜头范围扩充=%d,%d,%d,%d'	(
				chunk.camera_complement_1,
				chunk.camera_complement_2,
				chunk.camera_complement_3,
				chunk.camera_complement_4
			)
			push '地图宽度=%d'	(chunk.map_width)
			push '地图长度=%d'	(chunk.map_height)
			
			push '关闭预览图=%d'		(chunk.map_flag >> 0 & 1)
			push '自定义结盟优先权=%d'	(chunk.map_flag >> 1 & 1)
			push '对战地图=%d'		(chunk.map_flag >> 2 & 1)
			push '大型地图=%d'		(chunk.map_flag >> 3 & 1)
			push '迷雾区域显示地形=%d'	(chunk.map_flag >> 4 & 1)
			push '自定义玩家分组=%d'	(chunk.map_flag >> 5 & 1)
			push '自定义队伍=%d'		(chunk.map_flag >> 6 & 1)
			push '自定义科技树=%d'	(chunk.map_flag >> 7 & 1)
			push '自定义技能=%d'		(chunk.map_flag >> 8 & 1)
			push '自定义升级=%d'		(chunk.map_flag >> 9 & 1)
			push '地图菜单标记=%d'	(chunk.map_flag >> 10 & 1)
			push '地形悬崖显示水波=%d'	(chunk.map_flag >> 11 & 1)
			push '地形起伏显示水波=%d'	(chunk.map_flag >> 12 & 1)
			push '未知1=%d'			(chunk.map_flag >> 13 & 1)
			push '未知2=%d'			(chunk.map_flag >> 14 & 1)
			push '未知3=%d'			(chunk.map_flag >> 15 & 1)
			push '未知4=%d'			(chunk.map_flag >> 16 & 1)
			push '未知5=%d'			(chunk.map_flag >> 17 & 1)
			push '未知6=%d'			(chunk.map_flag >> 18 & 1)
			push '未知7=%d'			(chunk.map_flag >> 19 & 1)
			push '未知8=%d'			(chunk.map_flag >> 20 & 1)
			push '未知9=%d'			(chunk.map_flag >> 21 & 1)

			push '地形类型=%s'		(chunk.map_main_ground_type)
			
			push '载入图序号=%d'		(chunk.loading_screen_id)
			push '自定义载入图=%s'	(chunk.loading_screen_path)
			push '载入界面文本=%s'	(chunk.loading_screen_text:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '载入界面标题=%s'	(chunk.loading_screen_title:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '载入界面子标题=%s'	(chunk.loading_screen_subtitle:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))

			push '使用游戏数据设置=%d'	(chunk.game_data_set)

			push '自定义序幕图=%s'	(chunk.prologue_screen_path)
			push '序幕界面文本=%s'	(chunk.prologue_screen_text:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '序幕界面标题=%s'	(chunk.prologue_screen_title:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))
			push '序幕界面子标题=%s'	(chunk.prologue_screen_subtitle:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t'))

			push '地形迷雾=%d'		(chunk.terrain_fog)
			push '迷雾z轴起点=%.4f'	(chunk.fog_start_z)
			push '迷雾z轴终点=%.4f'	(chunk.fog_end_z)
			push '迷雾密度=%.4f'		(chunk.fog_density)
			push '迷雾颜色=%d,%d,%d,%d'	(
				chunk.fog_red,
				chunk.fog_green,
				chunk.fog_blue,
				chunk.fog_alpha
			)

			push '全局天气=%s'	(chunk.weather_id)
			push '环境音效=%s'	(chunk.sound_environment)
			push '环境光照=%s'	(chunk.light_environment)

			push '水面颜色=%d,%d,%d,%d'	(
				chunk.water_red,
				chunk.water_green,
				chunk.water_blue,
				chunk.water_alpha
			)

			--玩家
			push '玩家数量=%d'	(chunk.player_count)
			for _, player in ipairs(chunk.players) do
				push '玩家=%d'			(player.id)
				push '类型=%d'			(player.type)
				push '种族=%d'			(player.race)
				push '修正出生点=%d'		(player.start_position)
				push '名字=%s'			(player.name)
				push '出生点=%.4f,%.4f'	(player.start_x, player.start_y)
				push '低结盟优先权标记=%d'	(player.ally_low_flag)
				push '高结盟优先权标记=%d'	(player.ally_high_flag)			
			end

			--队伍
			push '队伍数量=%d'	(chunk.force_count)
			for _, force in ipairs(chunk.forces) do
				push '结盟=%d'			(force.force_flag >> 0 & 1)
				push '结盟胜利=%d'		(force.force_flag >> 1 & 1)
				push '共享视野=%d'		(force.force_flag >> 2 & 1)
				push '共享单位控制=%d'	(force.force_flag >> 3 & 1)
				push '共享高级单位设置=%d'	(force.force_flag >> 4 & 1)

				push '玩家列表=%d'		(force.player_flag)
				push '队伍名称=%s'		(force.name)
			end

			--升级
			push '升级数量=%d'	(chunk.upgrade_count)
			for _, upgrades in ipairs(chunk.upgrades) do
				push '玩家列表=%d'	(upgrade.player_flag)
				push 'ID=%s'		(upgrade.id)
				push '等级=%d'		(upgrade.level)
				push '可用性=%d'		(upgrade.available)
			end

			--科技
			push '科技数量=%d'	(chunk.tech_count)
			for _, tech in ipairs(chunk.techs) do
				push '玩家列表=%d'	(tech.player_flag)
				push 'ID=%s'		(tech.id)
			end

			--随机组
			push '随机组数量=%d'	(chunk.group_count)
			for _, group in ipairs(chunk.groups) do
				push '随机组=%d'		(group.id)
				push '随机组名称=%s'	(group.name)

				push '位置数量=%d'	(group.position_count)
				for _, type in ipairs(group.positions) do
					push '位置类型=%d'	(type)
				end

				push '设置数=%d'		(group.line_count)
				for _, line in ipairs(group.lines) do
					push '几率=%d'	(line.chance)
					for _, id in ipairs(line.ids) do
						push 'ID=%s'	(id)
					end
				end
			end

			--物品列表
			push '物品列表数量=%d'	(chunk.random_item_count)
			for _, random_item in ipairs(chunk.random_items) do
				push '物品列表=%d'		(random_item.id)
				push '物品列表名称=%s'	(random_item.name)

				push '物品设置数量=%d'	(random_item.set_count)
				for _, set in ipairs(random_item.sets) do

					push '物品数量=%d'	(set.item_count)
					for _, item in ipairs(set.items) do
						push '几率=%d'	(item.chance)
						push 'ID=%s'	(item.id)
					end
				end
			end

			io.save(file_name_out, table.concat(lines, '\r\n'):convert_wts())

		end

		function w3x2txt.txt2w3i(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local chunk	= {}

			local index = 0
			local line
			local function read()
				local _
				_, index, line	= content:find('(%C+)', index + 1)
				if line and line:match '^%s*$' then
					return read()
				end
				return line
			end

			local function readValue(n, ...)
				if not n then
					return read():match '^.-%=(.*)$'
				end

				local t	= {}
				local len	= {...}
				for i = 1, n do
					t[i]	= read():match '^.-%=(.*)$'
					if len[i] and len[i] - #t[i] > 0 then
						t[i]	= t[i] .. ('\0'):rep(len[i] - #t[i])
					end
					--print(t[i])
				end
				return table.unpack(t)
			end

			local function packFlag(...)
				local int	= 0
				for i, v in ipairs {...} do
					int	= int + (v << i - 1)
				end
				return int
			end

			local pack = {}
			local function push(format)
				return function (...)
					--print(format, ...)
					table.insert(pack, format:pack(...))
				end
			end

			--文件头
			push 'lllzzzz' (readValue(7))

			--镜头范围
			for v in readValue():gmatch '[^%,]+' do
				push 'f' (v)
			end

			--镜头范围扩充
			for v in readValue():gmatch '[^%,]+' do
				push 'l' (v)
			end

			--地图长宽
			push 'll' (readValue(2))

			--地图标记
			push 'l' (packFlag(readValue(22)))

			--地形类型开始
			push 'c1lz' (readValue(3, 1))

			--载入界面
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))

			push 'lz' (readValue(2))

			--序幕界面
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))
			push 'z' (readValue():gsub('@@n', '\r\n'):gsub('@@t', '\t'))

			--迷雾
			push 'lfff' (readValue(4))

			--迷雾颜色
			for v in readValue():gmatch '[^%,]+' do
				push 'B' (v)
			end

			--全局天气
			push 'c4zc1' (readValue(3, 4, nil, 1))

			--水面颜色
			for v in readValue():gmatch '[^%,]+' do
				push 'B' (v)
			end

			--玩家
			local count = readValue()
			push 'l' (count)
			for i = 1, count do
				push 'llllz' (readValue(5))
				--出生点
				for v in readValue():gmatch '[^%,]+' do
					push 'f' (v)
				end
				--结盟优先权
				push 'll' (readValue(2))
			end

			--队伍
			local count = readValue()
			push 'l' (count)
			for i = 1, count do
				push 'l' (packFlag(readValue(5)))
				push 'lz' (readValue(2))
			end
			
			--升级
			local count = readValue()
			push 'l' (count)
			for i = 1, count do
				push 'lc4ll' (readValue(4, nil, 4))
			end

			--科技
			local count = readValue()
			push 'l' (count)
			for i = 1, count do
				push 'lc4' (readValue(2, nil, 4))
			end

			--随机组
			local count = readValue()
			push 'l' (count)
			for i = 1, count do
				push 'lz' (readValue(2))
				
				local y = readValue()
				push 'l' (y)
				for i = 1, y do
					push 'l' (readValue())
				end

				local x = readValue()
				push 'l' (x)
				for i = 1, x do
					push 'l' (readValue())
					for i = 1, y do
						push 'c4' (readValue(1, 4))
					end
				end
			end

			--物品列表
			local count	= readValue()
			push 'l' (count)
			for i = 1, count do
				push 'lz' (readValue(2))

				local x	= readValue()
				push 'l' (x)
				
				for i = 1, x do
					local y = readValue()
					push 'l' (y)
					
					for i = 1, y do
						push 'lc4' (readValue(2, nil, 4))
					end
				end
			end
			
			io.save(file_name_out, table.concat(pack))		
		end

		local wts_strings	= {}

		function w3x2txt.read_wts(file_name_in)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			for string in content:gmatch 'STRING.-%c*%}' do
				local i, s	= string:match 'STRING (%d+).-%{%c*(.-)%c*%}'
				local t	= {
					string	= string,
					index	= i,
					text	= s,
				}
				table.insert(wts_strings, t)
				wts_strings[('%03d'):format(i)]	= t	--这里的索引是字符串
			end
		end

		function string.convert_wts(s, only_short)
			return s:gsub('TRIGSTR_(%d+)',
				function(i)
					local s	= wts_strings[i].text:gsub('\r\n', '@@n'):gsub('\r', '@@n'):gsub('\n', '@@n'):gsub('\t', '@@t')
					if only_short and #s > 256 then
						return
					end
					wts_strings[i].converted	= true
					return s
				end
			)
		end

		function w3x2txt.fresh_wts(file_name_out)
			local lines	= {}
			for i, t in ipairs(wts_strings) do
				if t and not t.converted then
					table.insert(lines, t.string)
				end
			end

			io.save(file_name_out, table.concat(lines, '\r\n\r\n'))
		end
	end

	main()
	
	return w3x2txt