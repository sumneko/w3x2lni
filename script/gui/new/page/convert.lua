local gui = require 'yue.gui'
local backend = require 'gui.backend'
local timer = require 'gui.timer'
require 'filesystem'

local worker
local view
local pb
local label

local function getexe()
    local i = 0
    while arg[i] ~= nil do
        i = i - 1
    end
    return fs.path(arg[i + 1])
end

local function pack_arg()
    local buf = {}
    buf[1] = '"' .. window._filename .. '"'
    buf[2] = '-' .. window._mode
    return table.concat(buf, ' ')
end

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

local function create_report()
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

local function update_progress(value)
    pb:setvalue(value)
    view:schedulepaint()
end

local function update()
    worker:update()
    message:settext(backend.message)
    update_progress(backend.progress)
    if #worker.error > 0 then
        messagebox('错误', worker.error)
        worker.error = ''
        return 0, 1
    end
    if worker.exited then
        create_report()
        if worker.exit_code == 0 then
            return 1000, 0
        else
            return 0, worker.exit_code
        end
    end
end

local function delayedtask(t)
    local ok, r, code = xpcall(update, debug.traceback)
    if not ok then
        t:remove()
        messagebox('错误', r)
        mini:close()
        exitcode = -1
        return
    end
    if r then
        t:remove()
        if r > 0 then
            timer.wait(r, function()
                if code ~= 0 then
                    exitcode = code
                end
                mini:close()
            end)
        else
            if code ~= 0 then
                exitcode = code
            end
            mini:close()
        end
    end
end

view = gui.Container.create()
view:setstyle { FlexGrow = 1, AlignItems = 'center', JustifyContent = 'center', Padding = 2 }

local upper = gui.Container.create()
upper:setstyle { FlexGrow = 1, AlignItems = 'center', JustifyContent = 'flex-start' }
view:addchildview(upper)

local lower = gui.Container.create()
lower:setstyle { FlexGrow = 1, AlignItems = 'center', JustifyContent = 'flex-end' }
view:addchildview(lower)

local filename = Button(window._filename:match '[^/\\]+$', window._color)
filename:setstyle { Width = 392, Height = 50, Margin = 2 }
filename:setfont(Font('黑体', 20))
upper:addchildview(filename)

message = gui.Label.create('')
message:setstyle { Width = 392, Height = 20, Margin = 2 }
message:setfont(Font('黑体', 20))
message:setcolor('#CCC')
lower:addchildview(message)

pb = gui.ProgressBar.create()
pb:setstyle { Width = 392, Height = 20, Margin = 10 }
lower:addchildview(pb)

local start = Button('开始', window._color)
start:setstyle { Width = 392, Height = 50, Margin = 2 }
start:setfont(Font('黑体', 24, 'bold'))
lower:addchildview(start)

function start:onclick()
    if worker and not worker.exited then
        return
    end
    backend:init(getexe(), fs.current_path())
    worker = backend:open('map.lua', pack_arg())
    backend.message = '正在初始化...'
    backend.progress = 0
    timer.loop(100, delayedtask)
end

return view
