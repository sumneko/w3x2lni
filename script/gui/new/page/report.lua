local gui = require 'yue.gui'
local backend = require 'gui.backend'

local function sortpairs(t)
    local sort = {}
    for k, v in pairs(t) do
        sort[#sort+1] = {k, v}
    end
    table.sort(sort, function (a, b)
        return a[1] < b[1]
    end)
    local n = 1
    return function()
        local v = sort[n]
        if not v then
            return
        end
        n = n + 1
        return v[1], v[2]
    end
end

local function get_report()
    local lines = {}
    for type, report in sortpairs(backend.report) do
        if type ~= '' then
            type = type:sub(2)
            lines[#lines+1] = '================'
            lines[#lines+1] = type
            lines[#lines+1] = '================'
            for _, s in ipairs(report) do
                if s[2] then
                    lines[#lines+1] = ('%s - %s'):format(s[1], s[2])
                else
                    lines[#lines+1] = s[1]
                end
            end
            lines[#lines+1] = ''
        end
    end
    local report = backend.report['']
    if report then
        for _, s in ipairs(report) do
            if s[2] then
                lines[#lines+1] = ('%s - %s'):format(s[1], s[2])
            else
                lines[#lines+1] = s[1]
            end
        end
    end
    return table.concat(lines, '\n')
end

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
label:setstyle { FlexGrow = 1, Width = 396 }
label:setfont(Font('黑体', 18))
label:setcolor('#CCC')
label:setalign('start')
report:addchildview(label)

local scroll = gui.Scroll.create()
scroll:setstyle { FlexGrow = 1, Margin = 2, Width = 396, JustifyContent = 'flex-start' }
scroll:setcontentview(report)
scroll:setscrollbarpolicy('never', 'never')
view:addchildview(scroll)

local btn = Button('返回')
btn:setstyle { Bottom = 0, Height = 28, Margin = 5 }
btn:setfont(Font('黑体', 16))
function btn:onclick()
    window:show_page('convert')
end
view:addchildview(btn)

function window:show_report()
    local text = get_report()
    local height = count_report_height(text)
    scroll:setcontentsize { width = 0, height = height }
    label:settext(text)
end

return view
