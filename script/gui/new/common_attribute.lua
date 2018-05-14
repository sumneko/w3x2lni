local function color(self, t, data, bind)
    if t.bind and t.bind.color then
        bind.color = data:bind(t.bind.color, function()
            self:setbackgroundcolor(bind.color:get())
        end)
        self:setbackgroundcolor(bind.color:get())
    else
        if t.color then
            if type(t.color) == 'table' then
                self:setbackgroundcolor(t.color.normal)
                function self:onmouseleave()
                    self:setbackgroundcolor(t.color.normal)
                end
                function self:onmouseenter()
                    self:setbackgroundcolor(t.color.hover)
                end
            else
                self:setbackgroundcolor(t.color)
            end
        end
    end
end
local function visible(self, t, data, bind)
    if t.bind and t.bind.visible then
        bind.visible = data:bind(t.bind.visible, function()
            self:setvisible(bind.visible:get())
        end)
        self:setvisible(bind.visible:get())
    else
        if t.visible ~= nil then
            self:setvisible(t.visible)
        end
    end
end

return {
    color = color,
    visible = visible,
}
