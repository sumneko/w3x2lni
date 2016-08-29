local function read_next(meta_list, line)
	local id = line:match [[C;.*X1;.*K"(.-)"]]
	if id then
		meta_list.id  = id
		meta_list[id] = {}
		return
	end
	local x, value = line:match [[C;X(%d+);K["]*(.-)["]*$]]
	if x then
		if meta_list.id == 'ID' then
			meta_list[x] = value
		elseif meta_list[x] == 'type' then
			meta_list[meta_list.id].type = value
		elseif meta_list[x] == 'data' then
			meta_list[meta_list.id].data = value
		end
	end
end

local function read_metadata(self, file_name)
	local content = io.load(file_name)
	if not content then
		print('文件无效:' .. file_name:string())
		return
	end

	-- 解析meta文件的每一行
	for line in content:gmatch '[^\n\r]+' do
		read_next(self.meta_list, line)
	end
end

return read_metadata
