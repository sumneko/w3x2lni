local function read_metadata(self, file_name)
	local meta_list = {}
	self.meta_list = meta_list
	meta_list.default = {type	= 'string'}
	setmetatable(meta_list,
		{
			__index = function(_, id)
				return rawget(meta_list, 'default')
			end
		}
	)

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

return read_metadata
