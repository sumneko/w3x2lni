local function label_color(self, t, data, bind)
    local color_hover = ''
    local color_normal = ''
    local hover = false
    local event = false
    local function updatebackgroundcolor()
        self:setbackgroundcolor(hover and color_hover or color_normal)
    end
    local function setbackgroundcolor(color)
        if type(color) == 'table' then
            color_normal = color.normal
            color_hover = color.hover
            if not event then
                event = true
                function self:onmouseleave()
                    hover = false
                    updatebackgroundcolor()
                end
                function self:onmouseenter()
                    hover = true
                    updatebackgroundcolor()
                end
            end
        else
            color_normal = color
            color_hover = color
        end
    end
    if t.bind and t.bind.color then
        bind.color = data:bind(t.bind.color, function()
            setbackgroundcolor(bind.color:get())
        end)
        setbackgroundcolor(bind.color:get())
        updatebackgroundcolor()
    else
        if t.color then
            setbackgroundcolor(t.color)
            updatebackgroundcolor()
        end
    end
end

local function getHoverColor(color)
    if #color == 4 then
        return ('#%01X%01X%01X'):format(
            math.min(tonumber(color:sub(2, 2), 16) + 0x1, 0xF),
            math.min(tonumber(color:sub(3, 3), 16) + 0x1, 0xF),
            math.min(tonumber(color:sub(4, 4), 16) + 0x1, 0xF)
        )
    elseif #color == 7 then
        return ('#%02X%02X%02X'):format(
            math.min(tonumber(color:sub(2, 3), 16) + 0x10, 0xFF),
            math.min(tonumber(color:sub(4, 5), 16) + 0x10, 0xFF),
            math.min(tonumber(color:sub(6, 7), 16) + 0x10, 0xFF)
        )
    else
        return color
    end
end

local function button_color(self, t, data, bind)
    local color_hover = ''
    local color_normal = ''
    local hover = false
    local event = false
    local function updatebackgroundcolor()
        self:setbackgroundcolor(hover and color_hover or color_normal)
    end
    local function setbackgroundcolor(color)
        if type(color) == 'table' then
            color_normal = color.normal
            color_hover = color.hover
        else
            color_normal = color
            color_hover = getHoverColor(color)
        end
        if not event then
            event = true
            function self:onmouseleave()
                hover = false
                updatebackgroundcolor()
            end
            function self:onmouseenter()
                hover = true
                updatebackgroundcolor()
            end
        end
    end
    if t.bind and t.bind.color then
        bind.color = data:bind(t.bind.color, function()
            setbackgroundcolor(bind.color:get())
        end)
        setbackgroundcolor(bind.color:get())
        updatebackgroundcolor()
    else
        if t.color then
            setbackgroundcolor(t.color)
            updatebackgroundcolor()
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
    label_color = label_color,
    button_color = button_color,
    visible = visible,
}
