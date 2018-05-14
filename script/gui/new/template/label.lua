local gui = require 'yue.gui'
local ev = require 'gui.event'

return function (t, data)
    local label = gui.Label.create('')
    if t.bind and t.bind.text then
        local bind_text
        bind_text = data:bind(t.bind.text, function()
            label:settitle(bind_text:get())
        end)
        label:settext(bind_text:get())
    else
        label:settext(t.text or '')
    end
    if t.style then
        label:setstyle(t.style)
    end
    if t.font then
        label:setfont(Font(t.font))
    end
    if t.bind and t.bind.color then
        local bind_color
        bind_color = data:bind(t.bind.color, function()
            label:setcolor(bind_color:get())
        end)
        label:setcolor(bind_color:get())
    else
        if t.color then
            label:setcolor(t.color)
        else
            label:setcolor(window._color)
            ev.on('update theme', function()
                label:setcolor(window._color)
            end)
        end
    end
    return label
end
