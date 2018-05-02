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
    local lbl = gui.Label.create('')
    btn:setstyle { Width = 20, Height = 20 }
    lbl:setstyle { Width = 16, Height = 16, Position = 'absolute', Left = 2, Top = 2 }
    btn.select = t.select or false
    btn.hover = t.hover or false
    btn._backgroundcolor1 = '#333743'
    btn._backgroundcolor2 = getActiveColor(btn._backgroundcolor1)
    lbl._backgroundcolor1 = window._color
    lbl._backgroundcolor2 = getActiveColor(lbl._backgroundcolor1)
    local function update_color()
        if btn.select then
            lbl:setvisible(true)
        else
            lbl:setvisible(false)
        end
        if btn.hover then
            btn:setbackgroundcolor(btn._backgroundcolor1)
            lbl:setbackgroundcolor(lbl._backgroundcolor1)
        else
            btn:setbackgroundcolor(btn._backgroundcolor2)
            lbl:setbackgroundcolor(lbl._backgroundcolor2)
        end
    end
    update_color()
    function btn:onmousedown()
        self.select = not self.select
        update_color()
    end
    function btn:onmouseleave()
        self.hover = false
        btn:setbackgroundcolor(btn._backgroundcolor1)
        lbl:setbackgroundcolor(lbl._backgroundcolor1)
    end
    function btn:onmouseenter()
        self.hover = true
        btn:setbackgroundcolor(btn._backgroundcolor2)
        lbl:setbackgroundcolor(lbl._backgroundcolor2)
    end
    function btn:update_theme(c)
        yes_color1 = c
        update_color()
    end
    return btn, lbl
end

return function (t)
    local o = gui.Container.create()
    o:setstyle { FlexDirection = 'row' }
    if t.style then
        o:setstyle(t.style)
    end
    local btn, lbl = btn_checkbox(t)
    o:addchildview(btn)
    o:addchildview(lbl)
    local label = gui.Label.create(t.text)
    label:setcolor('#AAA')
    if t.font then
        label:setfont(Font(t.font.name, t.font.size, t.font.weight, t.font.style))
    end
    label:setalign 'start'
    label:setstyle { FlexGrow = 1, MarginTop = 3 }
    o:addchildview(label)
    return o
end
