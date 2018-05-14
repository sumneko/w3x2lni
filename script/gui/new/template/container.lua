local gui = require 'yue.gui'

return function (t, data)
    local o = gui.Container.create()
    if t.style then
        o:setstyle(t.style)
    end
    local bind = {}
    if t.bind and t.bind.color then
        bind.color = data:bind(t.bind.color, function()
            o:setbackgroundcolor(bind.color:get())
        end)
        o:setbackgroundcolor(bind.color:get())
    else
        if t.color then
            if type(t.color) == 'table' then
                o:setbackgroundcolor(t.color.normal)
                function o:onmouseleave()
                    o:setbackgroundcolor(t.color.normal)
                end
                function o:onmouseenter()
                    o:setbackgroundcolor(t.color.hover)
                end
            else
                o:setbackgroundcolor(t.color)
            end
        end
    end
    return o
end
