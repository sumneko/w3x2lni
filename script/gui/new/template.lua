local databinding = require 'gui.new.databinding'

local function create_template(t, data)
    local create_control = require ('gui.new.template.' ..  t.class)
    local view, addchild = create_control(t, data)
    for i = 1, #t do
        t[i].font = t[i].font or t.font
        local child = create_template(t[i], data)
        if addchild then
            addchild(view, child)
        else
            view:addchildview(child)
        end
    end
    return view
end

local function create(t, data)
    local data = databinding(data)
    return create_template(t, data), data.proxy
end

local ui = {}

function ui:__index(name)
    local function reg(t)
        t.class = name
        return t
    end
    rawset(self, name, reg)
    return reg
end

return setmetatable({ create = create }, ui)
