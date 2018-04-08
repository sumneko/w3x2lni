local gui = require 'yue.gui'
local timer = require 'gui.timer'

local view = gui.Container.create()
view:setstyle { FlexGrow = 1 }

local info = {
    {
        type = 'Lni',
        color = '#00ADD9',
    },
    {
        type = 'Slk',
        color = '#00AD3C',
    },
    {
        type = 'Obj',
        color = '#D9A33C',
    },
}
for i = 1, 3 do
    local data = info[i]
    local btn = Button('转为'..data.type, data.color)
    btn:setfont(Font('黑体', 20))
    btn:setstyle { Margin = 2, FlexGrow = 1 }
    view:addchildview(btn)
    function btn:onmouseenter()
        window:set_theme('W3x2'..data.type, data.color)
    end
end

return view
