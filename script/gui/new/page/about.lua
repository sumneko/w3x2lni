local gui = require 'yue.gui'
local lang = require 'share.lang'
local ui = require 'gui.new.template'
local ev = require 'gui.event'

local template = ui.container {
    style = { FlexGrow = 1 },
    font = { size = 16 },
    ui.container {
        style = { FlexGrow = 1 },
        ui.label {
            text = lang.ui.AUTHOR,
            text_color = '#000',
            style = { MarginTop = 20, Height = 28, Width = 240 },
            bind = {
                color = 'theme'
            }
        },
        ui.label {
            text = lang.ui.FRONTEND .. 'actboy168',
            text_color = '#AAA',
            style = { MarginTop = 5, Height = 28, Width = 240 }
        },
        ui.label {
            text = lang.ui.BACKEND .. lang.ui.SUMNEKO,
            text_color = '#AAA',
            style = { Height = 28, Width = 240 }
        },
        ui.label {
            text = lang.ui.CHANGE_LOG,
            text_color = '#000',
            style = { Height = 28, Width = 240 },
            bind = {
                color = 'theme'
            }
        },
        ui.scroll {
            id = 'changelog',
            style = { FlexGrow = 1 },
            hpolicy = 'never',
            vpolicy = 'never',
            width = 0,
            bind = {
                height = 'height'
            }
        },
    },
    ui.button {
        title = lang.ui.BACK,
        style = { Bottom = 0, Height = 28, Margin = 5 },
        on = {
            click = function()
                window:show_page('index')
            end
        }
    }
}

local view, data, element = ui.create(template, {
    theme = window._color,
    height = 0
})

ev.on('update theme', function()
    data.theme = window._color
end)

local changelog = element.changelog

local color  = {
    NEW = gui.Color.rgb(0, 173, 60),
    CHG = gui.Color.rgb(217, 163, 60),
    FIX = gui.Color.rgb(200, 30, 30),
    UI =  gui.Color.rgb(111, 77, 150),
}

local height = 0
local log = gui.Container.create()
for _, v in ipairs(require 'share.changelog') do
    local label = gui.Label.create(v.version)
    label:setstyle { Margin = 3, Height = 25 }
    label:setbackgroundcolor('#444')
    label:setcolor('#AAA')
    label:setfont(Font { size = 16 })
    log:addchildview(label)

    height = height + 31

    for _, l in ipairs(v) do
        local line = gui.Container.create()
        line:setstyle { Height = 31, FlexDirection = 'row' }

        local label = gui.Label.create(l[1])
        label:setbackgroundcolor(color[l[1]])
        label:setstyle { Margin = 3, Width = 40 }
        label:setfont(Font { name = 'Consolas', size = 18 })
        line:addchildview(label)

        local text = gui.Label.create(l[2])
        text:setcolor('#AAA')
        text:setstyle { Margin = 3, Width = 360, FlexGlow = 1 }
        text:setalign('start')
        text:setfont(Font { size = 16 })
        line:addchildview(text)

        function text:onmouseleave()
            line:setbackgroundcolor('#222')
        end
        function text:onmouseenter()
            line:setbackgroundcolor('#444')
        end

        log:addchildview(line)

        height = height + 31
    end
end
changelog:setcontentview(log)
data.height = height

return view
