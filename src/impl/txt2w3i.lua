local function txt2w3i(self, file_name_in, file_name_out)
	local file = io.load(file_name_in)
	if not file then
		print('文件错误:' .. file_name_in:string())
		return
	end

	local func, err = load(file)
	if not func then
		print(err)
		return
	end

	local pack = func()
	
	local function read(t0)
		local pack = t0 or pack
		pack.index = (pack.index or 0) + 1
		return pack[pack.index][2]
	end
	
	local function readValue(n, t0)
		if not n then
			return read(t0)
		end
	
		local t	= {}
		for i = 1, n do
			t[i]	= read(t0)
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
	
	local hexs = {}
	local function push(format)
		return function (...)
			--print(format, ...)
			table.insert(hexs, format:pack(...))
		end
	end
	
	--文件头
	push 'lllzzzz' (readValue(7))
	
	--镜头范围
	push 'ffffffff' (table.unpack(readValue()))
	
	--镜头范围扩充
	push 'llll' (table.unpack(readValue()))
	
	--地图长宽
	push 'll' (readValue(2))
	
	--地图标记
	push 'l' (packFlag(readValue(22)))
	
	--地形类型开始
	push 'c1' (readValue():set_len(1))
	push 'lz' (readValue(2))
	
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
	push 'BBBB' (table.unpack(readValue()))
	
	--全局天气
	push 'c4' (readValue():set_len(4))
	push 'z' (readValue())
	push 'c1' (readValue():set_len(1))
	
	--水面颜色
	push 'BBBB' (table.unpack(readValue()))
	
	--玩家
	local count = readValue()
	push 'l' (count)
	for _, player in ipairs{readValue(count)} do
		push 'llllz' (readValue(5, player))
		--出生点
		push 'ff' (table.unpack(readValue(1, player)))
		--结盟优先权
		push 'll' (readValue(2, player))
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
		push 'l' (readValue())
		push 'c4' (readValue():set_len(4))
		push 'll' (readValue(2))
	end
	
	--科技
	local count = readValue()
	push 'l' (count)
	for i = 1, count do
		push 'l' (readValue())
		push 'c4' (readValue():set_len(4))
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
				push 'c4' (readValue(1):set_len(4))
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
				push 'l' (readValue())
				push 'c4' (readValue():set_len(4))
			end
		end
	end
	
	io.save(file_name_out, table.concat(hexs))		
end

return txt2w3i

