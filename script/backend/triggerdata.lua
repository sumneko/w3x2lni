require 'filesystem'
local ui = require 'ui-builder'
local lang = require 'share.lang'
local root = fs.current_path()

local function string_trim (self) 
	return self:gsub("^%s*(.-)%s*$", "%1")
end

local function ydwe_ui_path()
    local ydwe_path = require 'backend.ydwe_path'
    local ydwe = ydwe_path()
    if not ydwe then
        return nil, lang.script.NEED_YDWE_ASSOCIATE
    end
    if fs.exists(ydwe / 'ui') then
        return ydwe / 'ui'
    elseif fs.exists(ydwe / 'ui') then
        return ydwe / 'ui'
    elseif fs.exists(ydwe / 'share' / 'mpq') then
        return ydwe / 'share' / 'mpq'
    end
    return nil, lang.script.NO_TRIGGER_DATA
end

local function trigger_config(mpq_path)
    if not mpq_path or not fs.exists(mpq_path) then
        return
    end
	local list = {}
	local f, err = io.open((mpq_path / 'config'):string(), 'r')
	if not f then
		return { mpq_path, type = 'old' }
    end
	for line in f:lines() do
		table.insert(list, mpq_path / string_trim(line))
	end
    f:close()
    list.type = 'new'
    return list
end

local function load_triggerdata(list)
    if not list or #list == 0 then
        return nil
    end
    local t = nil
    local ok
    for _, path in ipairs(list) do
        if list.type == 'old' then
            t = ui.merge(t, ui.old_reader(function(filename)
                local buf = io.load(path / 'ui' / filename) or io.load(path / filename)
                if buf then
                    ok = true
                end
                return buf
            end))
        else
            t = ui.merge(t, ui.new_reader(function(filename)
                local buf = io.load(path / filename)
                if buf then
                    ok = true
                end
                return buf
            end))
        end
    end
    if not ok then
        return nil
    end
    return t
end

local function ui_path(ui)
    if ui == '${YDWE}' then
        return ydwe_ui_path()
    end
    return root:parent_path() / 'data' / ui / 'we' / 'ui'
end

return function (ui)
    local path, err = ui_path(ui)
    if not path then
        return nil, err
    end
    local list = trigger_config(path)
    if not list then
        return nil, lang.script.NO_TRIGGER_DATA_DIR .. path:string()
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
