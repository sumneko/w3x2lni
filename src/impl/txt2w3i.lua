local function txt2w3i(self, file_name_in, file_name_out)
	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
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
	push 'z' (readValue())
	push 'z' (readValue())
	push 'z' (readValue())
	
	push 'lz' (readValue(2))
	
	--序幕界面
	push 'z' (readValue())
	push 'z' (readValue())
	push 'z' (readValue())
	
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

return txt2w3i

