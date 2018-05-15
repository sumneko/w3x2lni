local function BindValue(t, data, bind, name, func)
    if t.bind and t.bind[name] then
        bind[name] = data:bind(t.bind[name], function()
            func(bind[name]:get())
        end)
        func(bind[name]:get())
    else
        if t[name] ~= nil then
            func(t[name])
        end
    end
end

local function GetHoverColor(color)
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

local function label_color(self, t, data, bind)
    local color_hover = ''
    local color_normal = ''
    local event = false
    BindValue(t, data, bind, 'color', function (color)
        if type(color) == 'table' then
            color_normal = color.normal
            color_hover = color.hover
            if not event then
                event = true
                function self:onmouseleave()
                    self:setbackgroundcolor(color_normal)
                end
                function self:onmouseenter()
                    self:setbackgroundcolor(color_hover)
                end
            end
        else
            color_normal = color
            color_hover = color
        end
        self:setbackgroundcolor(color_normal)
    end)
end

local function button_color(self, t, data, bind)
    local color_hover = ''
    local color_normal = ''
    local event = false
    BindValue(t, data, bind, 'color', function (color)
        if type(color) == 'table' then
            color_normal = color.normal
            color_hover = color.hover
        else
            color_normal = color
            color_hover = GetHoverColor(color)
        end
        if not event then
            event = true
            function self:onmouseleave()
                self:setbackgroundcolor(color_normal)
            end
            function self:onmouseenter()
                self:setbackgroundcolor(color_hover)
            end
        end
        self:setbackgroundcolor(color_normal)
    end)
end

local function visible(self, t, data, bind)
    BindValue(t, data, bind, 'visible', function (value)
        self:setvisible(value)
    end)
end

return {
    label_color = label_color,
    button_color = button_color,
    visible = visible,
}
