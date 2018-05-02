local function create_template(t)
    local name = t[1]
    local create_control = require ('gui.new.template.' .. name)
    local view, addchild = create_control(t)
    for i = 2, #t do
        t[i].font = t[i].font or t.font
        local child = create_template(t[i])
        if addchild then
            addchild(view, child)
        else
            view:addchildview(child)
        end
    end
    return view
end

return create_template
