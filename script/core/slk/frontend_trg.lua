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

local function trigger_config()
    local f, err = w2l:data_load('we/ui/config')
    if not f then
        if err:sub(#err-24) == 'No such file or directory' then
            return { mpq_path, type = 'old' }
        end
        return nil, err
    end
	local list = {}
    for _, line in ipairs(split(f)) do
        line = string_trim(line)
        if line ~= '' then
            list[#list+1] = string_trim(line)
        end
	end
    list.type = 'new'
    return list
end

local function load_triggerdata(list)
    if not list or #list == 0 then
        return nil
    end
    local t = nil
    local ok
    for _, name in ipairs(list) do
        local reader = list.type == 'old' and ui.old_reader or ui.new_reader
        t = ui.merge(t, reader(function(filename)
            local buf = w2l:data_load('we/ui/' .. name .. '/' .. filename)
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
    local list, err = trigger_config()
    if not list then
        return nil, err
    end
    local suc, state = pcall(load_triggerdata, list)
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
