local gui = require 'yue.gui'
local ev = require 'gui.event'

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

return function (t, data)
    local btn = gui.Button.create('')
    if t.bind and t.bind.title then
        local bind_title
        bind_title = data:bind(t.bind.title, function()
            btn:settitle(bind_title:get())
        end)
        btn:settitle(bind_title:get())
    else
        btn:settitle(t.title or '')
    end
    if t.style then
        btn:setstyle(t.style)
    end
    if t.font then
        btn:setfont(Font(t.font))
    end
    local function update_color()
        btn._backgroundcolor2 = getActiveColor(btn._backgroundcolor1)
        if btn.hover then
            btn:setbackgroundcolor(btn._backgroundcolor1)
        else
            btn:setbackgroundcolor(btn._backgroundcolor2)
        end
    end
    if t.bind and t.bind.color then
        local bind_color
        bind_color = data:bind(t.bind.color, function ()
            btn._backgroundcolor1 = bind_color:get()
            update_color()
        end)
        btn._backgroundcolor1 = bind_color:get()
    elseif t.color then
        btn._backgroundcolor1 = t.color
    else
        btn._backgroundcolor1 = window._color
        ev.on('update theme', function()
            btn._backgroundcolor1 = window._color
            update_color()
        end)
    end
    update_color()
    if t.on and t.on.click then
        function btn:onmousedown()
            t.on.click(self, t)
        end
    end
    function btn:onmouseleave()
        btn.hover = false
        btn:setbackgroundcolor(btn._backgroundcolor1)
    end
    function btn:onmouseenter()
        btn.hover = true
        btn:setbackgroundcolor(btn._backgroundcolor2)
    end
    return btn
end
