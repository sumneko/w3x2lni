local gui = require 'yue.gui'
local ext = require 'yue-ext'
require 'filesystem'

local mini = {}

function mini:select()
    local win = gui.Window.create  { frame = false }
    win:settitle('w3x2lni-mini')
    ext.register_window('w3x2lni-mini')

    local view = gui.Container.create()
    view:setstyle { Border = 2 }
    view:setbackgroundcolor('#222222')
    view:setmousedowncanmovewindow(true)

    local lni = gui.Button.create('转为Lni')
    lni:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    lni:setbackgroundcolor('#00add9')
    lni:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(lni)

    local slk = gui.Button.create('转为Slk')
    slk:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    slk:setbackgroundcolor('#00ad3c')
    slk:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(slk)

    local obj = gui.Button.create('转为Obj')
    obj:setstyle { Height = 100, Width = 392, AlignItems = 'center', Margin = 2 }
    obj:setbackgroundcolor('#d9a33c')
    obj:setfont(gui.Font.create('黑体', 20, "normal", "normal"))
    view:addchildview(obj)

    win:setcontentview(view)
    win:sethasshadow(true)
    win:setresizable(false)
    win:setmaximizable(false)
    win:setminimizable(false)
    win:setalwaysontop(true)
    win:setcontentsize { width = 400, height = 316 }
    win:center()
    win:activate()
    ext.hide_in_taskbar()

    self._window = win
    self._view = view

    function lni:onclick()
        win:close()
        arg[#arg+1] = '-lni'
        require 'gui.mini'
    end

    function slk:onclick()
        win:close()
        arg[#arg+1] = '-slk'
        require 'gui.mini'
    end

    function obj:onclick()
        win:close()
        arg[#arg+1] = '-obj'
        require 'gui.mini'
    end
end

local function getexe()
	local i = 0
	while arg[i] ~= nil do
		i = i - 1
	end
	return fs.path(arg[i + 1])
end

mini:select()
gui.MessageLoop.run()
