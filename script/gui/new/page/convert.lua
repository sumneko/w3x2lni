local gui = require 'yue.gui'
local backend = require 'gui.backend'
local timer = require 'gui.timer'
local messagebox = require 'ffi.messagebox'
local lang = require 'share.lang'
local push_error = require 'gui.push_error'
local ui = require 'gui.new.template'
local ev = require 'gui.event'
require 'filesystem'

local worker
local view
local data
local element

local function getexe()
    local i = 0
    while arg[i] ~= nil do
        i = i - 1
    end
    return fs.path(arg[i + 1])
end

local function pack_arg()
    local buf = {}
    buf[1] = window._mode
    buf[2] = '"' .. window._filename:string() .. '"'
    return table.concat(buf, ' ')
end

local function update_show()
    if backend.lastword then
        element.report:setvisible(true)
    else
        element.report:setvisible(false)
    end
    if worker and not element.report:isvisible() then
        element.progress:setvisible(true)
    else
        element.progress:setvisible(false)
    end
end

local function update()
    worker:update()
    data.message = backend.message
    if backend.lastword then
        data.report.text = backend.lastword.content
        if backend.lastword.type == 'failed' or backend.lastword.type == 'error' then
            data.report.color = '#C33'
        elseif backend.lastword.type == 'warning' then
            data.report.color = '#FC3'
        else
            data.report.color = window._color
        end
    end
    data.progress = backend.progress
    update_show()
    if #worker.error > 0 then
        push_error(worker.error)
        worker.error = ''
        return 0, 1
    end
    if worker.exited then
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
        messagebox(lang.ui.ERROR, '%s', r)
        return
    end
    if r then
        t:remove()
    end
end

local template = ui.container {
    style = { FlexGrow = 1, Padding = 1 },
    -- upper
    ui.container {
        style = { FlexGrow = 1, JustifyContent = 'flex-start' },
        -- filename
        ui.button {
            style = { Height = 36, Margin = 8, MarginTop = 16, MarginBottom = 16 },
            bind = {
                title = 'filename',
            },
        },
    },
    -- lower
    ui.container {
        style = { FlexGrow = 1, JustifyContent = 'flex-end' },
        -- message
        ui.label {
            style = { Height = 20, Margin = 2 },
            text_color = '#CCC',
            align = 'start',
            bind = {
                text = 'message',
            },
        },
        -- progress
        ui.progress {
            id = 'progress',
            style = { Height = 30, Margin = 5, Padding = 3, FlexDirection = 'row' },
            bind = {
                value = 'progress',
            },
        },
        -- report
        ui.button {
            id = 'report',
            style = { Height = 30, Margin = 5 },
            bind = {
                title = 'report.text',
                color = 'report.color',
            },
            on = {
                clock = function ()
                    if next(backend.report) then
                        window:show_page 'report'
                    end
                end
            },
        },
        -- start
        ui.button {
            title = '开始',
            style = { Height = 50, Margin = 2 },
            on = {
                click = function ()
                    if worker and not worker.exited then
                        return
                    end
                    element.progress:setvisible(true)
                    element.report:setvisible(false)
                    backend:init(getexe(), fs.current_path())
                    worker = backend:open('backend\\init.lua', pack_arg())
                    backend.message = lang.ui.INIT
                    backend.progress = 0
                    data.progress = backend.progress
                    timer.loop(100, delayedtask)
                    window._worker = worker
                end,
            },
        },
    },
}

view, data, element = ui.create(template, {
    filename = '',
    message  = '',
    report   = {
        text  = '',
        color = window._color,
    },
    progress = 0,
})

function view:on_show()
    update_show()
    data.filename = window._filename:filename():string()
end

ev.on('update theme', function()
    data.report.color = window._color
end)

return view
