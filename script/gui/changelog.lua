local window

local color  = {
	UI = {111, 77, 150},
	SLK = {0, 173, 60},
}

local function window_about_line(canvas, type, msg)
	window:set_style('button.color', table.unpack(color[type]))
	canvas:layout_space(25, 2)
	canvas:layout_space_push( 0, 0,  40, 25) canvas:button(type)
	canvas:layout_space_push(50, 0, 320, 25) canvas:text(msg, NK_TEXT_LEFT)
end

return function(window_, canvas)
    window = window_
	canvas:group('说明', function()
		canvas:layout_row_dynamic(25, 1)
		canvas:text('1.1.0', NK_TEXT_LEFT)
		window_about_line(canvas, 'UI', '详情里的tip尽可能不会被截断')
		window_about_line(canvas, 'UI', '重要的详情现在会更加显眼')
		window_about_line(canvas, 'SLK', '无法放在txt中字符串会放在wts里')
	end)
end
