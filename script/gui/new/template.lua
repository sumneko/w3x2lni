local databinding = require 'gui.new.databinding'

local function create_template(t, data)
    if t.data then
        data = databinding(t.data)
    end
    local name = t[1]
    local create_control = require ('gui.new.template.' .. name)
    local view, addchild = create_control(t, data)
    for i = 2, #t do
        t[i].font = t[i].font or t.font
        local child = create_template(t[i], data)
        if addchild then
            addchild(view, child)
        else
            view:addchildview(child)
        end
    end
    if t.data then
        view.data = data.proxy
    end
    return view
end

return function (t)
    return create_template(t)
end
