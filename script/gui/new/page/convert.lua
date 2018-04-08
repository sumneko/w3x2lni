local gui = require 'yue.gui'

local view = gui.Container.create()
view:setstyle { FlexGrow = 1, JustifyContent = 'space-between', AlignItems = 'center', Padding = 10 }

local filename = Button(window._filename:match '[^/\\]+$', window._color)
filename:setstyle { Width = 380, Height = 50 }
filename:setfont(Font('黑体', 20))
view:addchildview(filename)

local start = Button('开始', window._color)
start:setstyle { Width = 380, Height = 50 }
start:setfont(Font('黑体', 24, 'bold'))
view:addchildview(start)

return view
