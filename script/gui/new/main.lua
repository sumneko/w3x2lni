local gui = require 'yue.gui'
local ext = require 'yue-ext'
local timer = require 'gui.timer'
local lang = require 'share.lang'
local config = require 'share.config' (false)
local input_path = require 'share.input_path'
local builder = require 'map-builder'
local war3 = require 'share.war3'
local ev = require 'gui.event'
local ca = require 'gui.new.common_attribute'

lang:set_lang(config.global.lang)
window = {}

ext.on_timer = timer.update
function ext.on_dropfile(filename)
    if window._worker and not window._worker.exited then
        return
    end
    if war3:open(fs.path(filename)) then
        return
    end
    local mappath = input_path(filename)
    local map = builder.load(mappath)
    if not map then
        return
    end
    map:close()
    window._filename = mappath
    window:show_page('select')
end

function window:addcaption(w)
    local caption = gui.Container.create()
    caption:setmousedowncanmovewindow(true)
    caption:setstyle { Height = 40, FlexDirection = 'row', JustifyContent = 'space-between' }
    local title = gui.Label.create('W3x2Lni')
    title:setmousedowncanmovewindow(true)
    title:setstyle { Width = 120 }
    ca.font(title, {font = { name = 'Constantia', size = 24, weight = 'bold' }})
    caption:addchildview(title)
    self._title = title

    local close = gui.Container.create()
    close:setstyle { Margin = 0, Width = 40 }

    local canvas = gui.Canvas.createformainscreen{width=40, height=40}
    local painter = canvas:getpainter()
    painter:setstrokecolor('#000000')
    painter:beginpath()
    painter:moveto(15, 15)
    painter:lineto(25, 25)
    painter:moveto(15, 25)
    painter:lineto(25, 15)
    painter:closepath()
    painter:stroke()
    close._backgroundcolor1 = '#000000'
    close:setbackgroundcolor('#000000')
    function close:onmouseleave()
        self:setbackgroundcolor(self._backgroundcolor1)
    end
    function close:onmouseenter()
        self:setbackgroundcolor('#BE3246')
    end
    ev.on('update theme', function()
        close._backgroundcolor1 = window._color
        close:setbackgroundcolor(close._backgroundcolor1)
        caption:setbackgroundcolor(window._color)
    end)
    function close:onmousedown()
        w:close()
    end
    function close.ondraw(self, painter, dirty)
      painter:drawcanvas(canvas, {x=0, y=0, width=40, height=40})
    end
    caption:addchildview(close)
    return caption
end

function window:create(t)
    local win = gui.Window.create { frame = false }
    function win.onclose()
        gui.MessageLoop.quit()
    end
    win:settitle('w3x2lni')
    ext.register_window('w3x2lni')

    local view = gui.Container.create()
    view:setbackgroundcolor('#222')
    view:setstyle { Padding = 1 }
    local caption = self:addcaption(win)
    view:addchildview(caption)
    win:sethasshadow(true)
    win:setresizable(false)
    win:setmaximizable(false)
    win:setminimizable(false)
    win:setcontentview(view)
    win:setcontentsize { width = t.width, height = t.height }
    win:center()
    win:activate()
    self._window = win
end

function window:set_theme(title, color)
    self._title:settext(title)
    self._color = color
    ev.emit('update theme')
end

function window:show_page(name)
    local view = self._window:getcontentview()
    if self._page then
        self._page:setvisible(false)
    end
    self._page = require('gui.new.page.' .. name)
    self._page:setvisible(true)
    view:addchildview(self._page)
    if self._page.on_show then
        self._page:on_show()
    end
end

local view = window:create {
    width = 400, 
    height = 600,
}

window:set_theme('W3x2Lni', '#00ADD9')
window:show_page('index')

gui.MessageLoop.run()
