local gui = require 'yue.gui'
local ev = require 'gui.event'
local ca = require 'gui.new.common_attribute'
local timer = require 'gui.timer'

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
    local frontend = 0
    local backend = 0
    local ti
    local function set_progress(n)
        if n < backend then
            backend = 0
            frontend = 0
        else
            backend = n
        end
        if not ti then
            ti = timer.loop(30, function ()
                local delta1 = 0
                local delta2 = 0.1 * (frontend - backend) / (100 - backend)
                if frontend < backend then
                    delta1 = (backend - frontend) / 10
                end
                frontend = frontend + math.max(delta1, delta2)
            end)
        end
        if n >= 100 then
            backend = 100
            frontend = 100
            ti:remove()
            ti = nil
        end
        bar:setstyle { FlexGrow = frontend / 100 }
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
    ca.visible(view, t, data, bind)
    return view
end
