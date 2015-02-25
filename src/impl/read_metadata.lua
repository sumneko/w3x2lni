local function read_metadata(self, file_name)
	if not self.meta_list then
		self.meta_list = {}
		self.meta_list.default = {type	= 'string'}
		setmetatable(self.meta_list,
			{
				__index = function(self, id)
					if id:sub(-1) == '\0' then
						return self[('z'):unpack(id)]
					end
					return rawget(self, 'default')
				end
			}
		)
	end
	local meta_list = self.meta_list
	
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

	local data_type_format	= {}
	self.data_type_format = data_type_format
	data_type_format[0]	= 'l'	--4字节有符号整数
	data_type_format[1] = 'f'	--4字节无符号浮点
	data_type_format[2] = 'f'	--4字节有符号浮点
	data_type_format[3] = 'z'	--以\0结尾的字符串

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
	function self.value2txt(value, id)
		local type	=  value_type[meta_list[id].type]
		if type == 'real' or type == 'unreal' then
			value = ('%.4f'):format(value)
		elseif type == 'string' then
			value = ('%q'):format(value)
		end
		return value
	end

	--将txt的值根据内部类型转化
	function self.txt2value(value, id)
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
end

return read_metadata
