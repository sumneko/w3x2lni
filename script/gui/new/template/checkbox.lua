local gui = require 'yue.gui'

local function getActiveColor(color)
    if #color == 4 then
        return ('#%01X%01X%01X'):format(
            math.min(tonumber(color:sub(2, 2), 16) + 0x1, 0xF),
            math.min(tonumber(color:sub(3, 3), 16) + 0x1, 0xF),
            math.min(tonumber(color:sub(4, 4), 16) + 0x1, 0xF)
        )
    elseif #color == 7 then
        return ('#%02X%02X%02X'):format(
            math.min(tonumber(color:sub(2, 3), 16) + 0x10, 0xFF),
            math.min(tonumber(color:sub(4, 5), 16) + 0x10, 0xFF),
            math.min(tonumber(color:sub(6, 7), 16) + 0x10, 0xFF)
        )
    else
        return color
    end
end

local function btn_checkbox(t)
    local btn = gui.Button.create('')
    btn:setstyle { Width = 20, Height = 20 }
    btn.select = t.select or false
    btn.hover = t.hover or false
    local yes_color1 = window._color
    local yes_color2 = getActiveColor(yes_color1)
    local no_color1 = '#333743'
    local no_color2 = getActiveColor(no_color1)
    local function update_color()
        if btn.select then
            btn._backgroundcolor1 = yes_color1
            btn._backgroundcolor2 = yes_color2
        else
            btn._backgroundcolor1 = no_color1
            btn._backgroundcolor2 = no_color2
        end
        if btn.hover then
            btn:setbackgroundcolor(btn._backgroundcolor1)
        else
            btn:setbackgroundcolor(btn._backgroundcolor2)
        end
    end
    update_color()
    function btn:onmousedown()
        self.select = not self.select
        update_color()
    end
    function btn:onmouseleave()
        self.hover = false
        self:setbackgroundcolor(self._backgroundcolor1)
    end
    function btn:onmouseenter()
        self.hover = true
        self:setbackgroundcolor(self._backgroundcolor2)
    end
    function btn:update_theme(c)
        yes_color1 = c
        update_color()
    end
    return btn
end

return function (t)
    local o = gui.Container.create()
    local checkbox = btn_checkbox(t)
    o:addchildview(checkbox)
    local label = gui.Label.create(t.text)
    label:setcolor('#AAA')
    label:setfont(Font('黑体', 16))
    label:setstyle { FlexGrow = 1, MarginTop = 3 }
    o:addchildview(label)
    o:setstyle { FlexDirection = 'row' }
    return o
end
