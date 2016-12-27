local window
local canvas

local color  = {
	NEW = {0, 173, 60},
	CHG = {217, 163, 60},
	FIX = {200, 30, 30},
	UI = {111, 77, 150},
}

local current
local index

local function version_begin()
	canvas:layout_space(25, 4)
	index = 0
end

local function version(ver, text)
	if not current then
		current = text
	end
	if current == text then
		window:set_style('button.color', 131, 135, 147)
	else
		window:set_style('button.color', 81, 85, 97)
	end
	index = index + 1
	canvas:layout_space_push(index * 80 - 80, 0, 80, 25)
	if canvas:button(ver) then
		current = text
	end
end

local function version_end()
	if current then
		current()
	end
end

local function log(type, msg, tip)
	window:set_style('button.color', table.unpack(color[type]))
	canvas:layout_space(25, 2)
	canvas:layout_space_push( 0, 0,  40, 25) canvas:button(type)
	canvas:layout_space_push(50, 0, 320, 25) canvas:text(msg, NK_TEXT_LEFT, tip)
end

return function(window_, canvas_)
	window = window_
	canvas = canvas_
	version_begin()
	version('1.2', function()
		log('NEW', '除buff外的对象不再无视大小写')
		log('NEW', 'listfile完整的地图才会重建地图')
		log('NEW', '只有slk的数据会移除超过等级的部分')
		log('CHG', '变身技能的buff引用改为搜索', 'Amil、AHav')
		log('CHG', '必须保留列表移除一些对象', 'Barm')
		log('FIX', '修正部分技能的引用分析错误的问题', 'Acoi、Acoh')
		log('FIX', '修正lpeg模块加载失败的问题')
		log('FIX', '修正市场没有被搜索到的问题')
		log('FIX', '修正字母相同的不同对象覆盖的问题', 'A00A与A00a')
	end)
	version('1.1', function()
		log('NEW', '支持模型压缩', '有损压缩')
		log('NEW', '无法放在txt中的字符串会放在wts里', '尽量不要同时包含逗号和双引号')
		log('NEW', '增加部分选项的提示')
		log('NEW', '转换成OBJ时会补充必要文件', 'war3mapunits.doo')
		log('CHG', '重要的详情现在会更加显眼')
		log('CHG', '必须保留列表移除一些对象', 'Bbar、Bchd、Buad、Biwb')
		log('FIX', '修正某些格式互转地图不可用的问题')
		log('FIX', '修正无法读取南瓜头生成的txt的问题')
		log('FIX', '修正读取0级技能会出错的问题')
		log('FIX', '修正详情里的tip被截断的问题')
	end)
	version_end()
end
