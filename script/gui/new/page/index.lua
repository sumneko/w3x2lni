local gui = require 'yue.gui'
local timer = require 'gui.timer'
local lang = require 'share.lang'
local template = require 'gui.new.template'

local view, data = template {
    'container',
    style = { FlexGrow = 1, FlexDirection = 'row', AlignItems = 'center', JustifyContent = 'center' },
    {
        'label',
        text = lang.ui.DRAG_MAP,
        style = { Height = 50, Width = 200 },
        font = { size = 16 },
        bind = {
            color = 'color',
        }
    },
    {
        'button',
        title = lang.ui.VERSION .. (require 'share.changelog')[1].version,
        color = '#333743',
        style = { Position = 'absolute', Bottom = 20, Right = 0, Width = 140 },
        on = {
            click = function()
                window:show_page('about')
            end
        }
    },
    data = {
        color = '#222'
    }
}

local hover = false
local ani = nil
function view:onmouseenter()
    hover = true
    timer.wait(1000, function()
        if hover then
            local n = 2
            ani = timer.count(100, 6, function()
                n = n + 1
                data.color = '#' .. n .. n .. n
            end)
        end
    end)
end
function view:onmouseleave()
    hover = false
    data.color = '#222'
    if ani then ani:remove() end
end

return view
