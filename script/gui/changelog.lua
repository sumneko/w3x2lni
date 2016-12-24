local window
local canvas

local color  = {
	UI = {111, 77, 150},
	SLK = {0, 173, 60},
	OBJ = {217, 163, 60},
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
	log('UI',  '详情里的tip尽可能不会被截断')
	log('UI',  '重要的详情现在会更加显眼')
	log('SLK', '无法放在txt中字符串会放在wts里')
	log('OBJ', '修正读取0级技会出错的问题')
end
