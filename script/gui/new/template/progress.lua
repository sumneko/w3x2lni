local gui = require 'yue.gui'
local ev = require 'gui.event'

return function (t, data)
    local view = gui.Container.create()
    if t.style then
        view:setstyle(t.style)
    end
    view:setbackgroundcolor '#444'
    local bar = gui.Label.create('')
    view:addchildview(bar)
    if t.color then
        bar:setbackgroundcolor(t.color)
    else
        bar:setbackgroundcolor(window._color)
        ev.on('update theme', function()
            bar:setbackgroundcolor(window._color)
        end)
    end
    local function set_progress(n)
        bar:setstyle { FlexGrow = n / 100 }
    end
    local bind = {}
    if t.bind and t.bind.value then
        bind.value = data:bind(t.bind.value, function()
            set_progress(bind.value:get())
        end)
        set_progress(bind.value:get())
    else
        set_progress(t.value or 0)
    end
    return view
end
