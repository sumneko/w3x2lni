local lang = require 'share.lang'
local ui = require 'gui.new.template'
local ev = require 'gui.event'

local template = ui.container {
    style = { FlexGrow = 1, Padding = 1 },
    font = { size = 20 },
    ui.container{
        style = { JustifyContent = 'flex-start' },
        ui.button {
            style = { Height = 36, Margin = 8, MarginTop = 16, MarginBottom = 16 },
            bind = {
                title = 'filename',
                color = 'theme'
            }
        }
    },
    ui.container {
        style =  { FlexGrow = 1, JustifyContent = 'center' },
        ui.button {
            title = lang.ui.CONVERT_TO..'Lni',
            color = '#00ADD9',
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Lni', '#00ADD9')
                    window._mode = 'lni'
                    window:show_page 'convert'
                end
            }
        },
        ui.button {
            title = lang.ui.CONVERT_TO..'Slk',
            color = '#00AD3C',
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Slk', '#00AD3C')
                    window._mode = 'slk'
                    window:show_page 'convert'
                end
            }
        },
        ui.button {
            title = lang.ui.CONVERT_TO..'Obj',
            color = '#D9A33C',
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Obj', '#D9A33C')
                    window._mode = 'obj'
                    window:show_page 'convert'
                end
            }
        }
    }
}

local view, data = ui.create(template, {
    filename = '',
    theme = window._color
})

ev.on('update theme', function()
    data.theme = window._color
end)

function view:on_show()
    data.filename = window._filename:filename():string()
end

return view
