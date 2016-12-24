local window
local canvas

local color  = {
	NEW = {0, 173, 60},
	CHG = {217, 163, 60},
	FIX = {200, 30, 30},
	UI = {111, 77, 150},
}

local function version(msg)
	canvas:layout_space(25, 1)
	canvas:layout_space_push(0, 0, 80, 25) 
	window:set_style('button.color', 81, 85, 97)
	canvas:button(msg)
end

local function log(type, msg)
	window:set_style('button.color', table.unpack(color[type]))
	canvas:layout_space(25, 2)
	canvas:layout_space_push( 0, 0,  40, 25) canvas:button(type)
	canvas:layout_space_push(50, 0, 320, 25) canvas:text(msg, NK_TEXT_LEFT)
end

return function(window_, canvas_)
    window = window_
    canvas = canvas_
	version('1.0.1')
	log('NEW', '支持模型压缩')
	log('NEW', '无法放在txt中的字符串会放在wts里')
	log('NEW', '增加部分选项的提示')
	log('CHG', '重要的详情现在会更加显眼')
	log('FIX', '修正无法读取南瓜头生成的txt的问题')
	log('FIX', '修正读取0级技能会出错的问题')
	log('FIX', '修正详情里的tip被截断的问题')
end
