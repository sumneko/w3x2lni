local lang = require 'share.lang'
local template = require 'gui.new.template'

local view, data = template {
    'container',
    style = { FlexGrow = 1, Padding = 1 },
    {
        'container',
        style = { JustifyContent = 'flex-start' },
        {
            'button',
            style = { Height = 36, Margin = 8, MarginTop = 16, MarginBottom = 16 },
            font = { size = 20 },
            bind = {
                title = 'filename',
            }
        }
    },
    {
        'container',
        style =  { FlexGrow = 1, JustifyContent = 'center' },
        {
            'button',
            title = lang.ui.CONVERT_TO..'Lni',
            color = '#00ADD9',
            font = { size = 20 },
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Lni', '#00ADD9')
                    window._mode = 'lni'
                    window:show_page 'convert'
                end
            }
        },
        {
            'button',
            title = lang.ui.CONVERT_TO..'Slk',
            color = '#00AD3C',
            font = { size = 20 },
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Slk', '#00AD3C')
                    window._mode = 'slk'
                    window:show_page 'convert'
                end
            }
        },
        {
            'button',
            title = lang.ui.CONVERT_TO..'Obj',
            color = '#D9A33C',
            font = { size = 20 },
            style = { Margin = 8, MarginTop = 2, MarginBottom = 2, Height = 140 },
            on = {
                click = function()
                    window:set_theme('W3x2Obj', '#D9A33C')
                    window._mode = 'obj'
                    window:show_page 'convert'
                end
            }
        }
    },
    data = {
        filename = ''
    }
}

function view:on_show()
    data.filename = window._filename:filename():string()
end

return view
