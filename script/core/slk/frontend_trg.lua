local ui = require 'ui-builder.init'
local lang = require 'lang'
local w2l

local function string_trim (self) 
	return self:gsub("^%s*(.-)%s*$", "%1")
end

local function split(str)
    local r = {}
    str:gsub('[^\n\r]+', function (w) r[#r+1] = w end)
    return r
end

local function trigger_config(path)
	local list = {}
	local f, err = w2l:load_data(path .. 'config')
	if not f then
		return { mpq_path, type = 'old' }
    end
    for _, line in ipairs(split(f)) do
        line = string_trim(line)
        if line ~= '' then
            list[#list+1] = string_trim(line)
        end
	end
    list.type = 'new'
    return list
end

local function load_triggerdata(path, list)
    if not list or #list == 0 then
        return nil
    end
    local t = nil
    local ok
    for _, name in ipairs(list) do
        local reader = list.type == 'old' and ui.old_reader or ui.new_reader
        t = ui.merge(t, reader(function(filename)
            local buf = w2l:load_data(path .. name .. '/' .. filename)
            if buf then
                ok = true
            end
            return buf
        end))
    end
    if not ok then
        return nil
    end
    return t
end

local function trigger_data()
    local path
    if w2l.setting.data_ui == '${YDWE}' then
        local err
        path, err = w2l:ui_ydwe()
        if not path then
            return nil, err
        end
    else
        path = 'we/ui/'
    end
    local list = trigger_config(path)
    if not list then
        return nil, lang.script.NO_TRIGGER_DATA_DIR .. path:string()
    end
    local suc, state = pcall(load_triggerdata, path, list)
    if not suc then
        return nil, lang.script.TRIGGER_DATA_ERROR
    end
    if not state then
        return nil, lang.script.NO_TRIGGER_DATA
    end
    return state
end

return function (w2l_)
    w2l = w2l_
    if not w2l.trg then
        local res, err = trigger_data()
        if not res then
            error(err)
        end
        w2l.trg = res
    end
    return w2l.trg
end
