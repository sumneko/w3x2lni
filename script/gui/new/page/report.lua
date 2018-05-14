local gui = require 'yue.gui'
local backend = require 'gui.backend'
local get_report = require 'share.report'
local lang = require 'share.lang'

local function count_report_height(text)
    local n = 1
    for _ in text:gmatch '\n' do
        n = n + 1
    end
    return n * 21
end

local view = gui.Container.create()
view:setstyle { FlexGrow = 1 }

local report = gui.Container.create()
report:setstyle { FlexGrow = 1 }

local label = gui.Label.create('')
label:setstyle { FlexGrow = 1 }
label:setfont(Font { size = 18 })
label:setcolor('#CCC')
label:setalign('start')
report:addchildview(label)

local scroll = gui.Scroll.create()
scroll:setstyle { FlexGrow = 1, Margin = 2 }
scroll:setcontentview(report)
scroll:setscrollbarpolicy('never', 'never')
view:addchildview(scroll)

local btn = Button(lang.ui.BACK)
btn:setstyle { Bottom = 0, Height = 28, Margin = 5 }
btn:setfont(Font { size = 16 })
function btn:onclick()
    window:show_page('convert')
end
view:addchildview(btn)

function view:on_show()
    local text = get_report(backend.report)
    local height = count_report_height(text)
    scroll:setcontentsize { width = 0, height = height }
    label:settext(text)
end

return view
