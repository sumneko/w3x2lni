local function get_value(t, key)
	local value = t[key]
	if value and type(value) ~= 'table' then
		return value
	end
	local pos = key:find("%d+$")
	if not pos then
		return
	end
	local value = t[key:sub(1, pos-1)]
	if not value or type(value) ~= 'table' then
		return
	end
	local level = tonumber(key:sub(pos))
	if level > t._max_level then
		return
	end
	return value[level]
end

local function switch(value)
    return function (mapping)
        if mapping[value] then
            return mapping[value]()
        elseif mapping.default then
            return mapping.default()
        end
    end
end

local function split(str)
    local r = {}
    str:gsub('[^,]+', function (w) r[#r+1] = w:lower() end)
    return r
end

local function computed_value(slk, str)
    local id, key, per = table.unpack(split(str))
    local o = slk.all[id]
    if not o then
        return
    end
    local res = switch(key) {
        mindmg1 = function ()
            return (get_value(o, 'dmgplus1') or 0) + (get_value(o, 'dice1') or 0)
        end,
        maxdmg1 = function ()
            return (get_value(o, 'dmgplus1') or 0) + (get_value(o, 'dice1') or 0) * (get_value(o, 'sides1') or 0)
        end,
        mindmg2 = function ()
            return (get_value(o, 'dmgplus2') or 0) + (get_value(o, 'dice2') or 0)
        end,
        maxdmg2 = function ()
            return (get_value(o, 'dmgplus2') or 0) + (get_value(o, 'dice2') or 0) * (get_value(o, 'sides2') or 0)
        end,
        realhp = function ()
            return get_value(o, 'hp') or 0
        end,
        default = function ()
            return get_value(o, key)
        end
    }
    if type(res) == 'number' then
        if per == '%' then
            res = res * 100
        end
        return math.floor(res)
    end
    return res
end

local function computed(slk, input)
    return input:gsub('<([^>]*)>', function(str) return computed_value(slk, str) end)
end

return function(w2l, slk)
    for _, o in pairs(slk.ability) do
        if o.researchubertip then
            o.researchubertip = computed(slk, o.researchubertip)
        end
        if o.ubertip then
            for k, v in pairs(o.ubertip) do
                o.ubertip[k] = computed(slk, v)
            end
        end
    end
    for _, o in pairs(slk.upgrade) do
        if o.ubertip then
            for k, v in pairs(o.ubertip) do
                o.ubertip[k] = computed(slk, v)
            end
        end
    end
end
