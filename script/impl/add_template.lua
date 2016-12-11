local progress = require 'progress'

local table_sort   = table.sort
local string_char  = string.char

local mt = {}
mt.__index = mt

local function copy(tbl)
    local ntbl = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            v = copy(v)
        end
        ntbl[k] = v
    end
    return ntbl
end

local function add_table(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if tbl1[k] then
            if type(tbl1[k]) == 'table' or type(v) == 'table' then
                if type(tbl1[k]) ~= 'table' then
                    tbl1[k] = {tbl1[k]}
                end
                if type(v) ~= 'table' then
                    v = {v}
                end
                add_table(tbl1[k], v)
            end
        else
            tbl1[k] = v
        end
    end
end

function mt:parse_chunk(chunk)
    local names = {}
    for name in pairs(chunk) do
        names[#names+1] = name
    end
    table.sort(names)
    local clock = os.clock()
    for i = 1, #names do
        local name = names[i]
        self:parse_obj(name, chunk[name])
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('搜索最优模板[%s] (%d/%d)'):format(name, i, #names))
        end
    end
end

function mt:parse_obj(name, obj)
    local code
    local count
    local find_times = self.find_id_times
    local maybe = self:find_code(obj)
    if type(maybe) ~= 'table' then
        obj._origin_id = maybe
        return
    end

    for try_name in pairs(maybe) do
        local new_count = self:try_obj(obj, self.default[try_name])
        if not count or count > new_count or (count == new_count and code > try_name) then
            count = new_count
            code = try_name
        end
        find_times = find_times - 1
        if find_times == 0 then
            break
        end
    end

    obj._origin_id = code
end

function mt:try_obj(obj, may_obj)
    local diff_count = 0
    for name, may_data in pairs(may_obj) do
        if name:sub(1, 1) ~= '_' then
            local data = obj[name]
            if type(may_data) == 'table' then
                if type(data) == 'table' then
                    for i = 1, #may_data do
                        if data[i] ~= may_data[i] then
                            diff_count = diff_count + 1
                            break
                        end
                    end
                else
                    diff_count = diff_count + 1
                end
            else
                if data ~= may_data then
                    diff_count = diff_count + 1
                end
            end
        end
    end
    return diff_count
end

function mt:find_code(obj)
    if obj['_true_origin'] then
        local code = obj['_origin_id']
        return code
    end
    local name = obj['_user_id']
    if self.default[name] then
        return name
    end
    local code = obj['_origin_id']
    if code then
        local list = self:get_revert_list(self.default, code)
        if list then
            return list
        end
    end
    if self.type == 'unit' then
        local list = self:get_unit_list(self.default, obj['_name'])
        if list then
            return list
        end
    end
    return self.default
end

function mt:get_revert_list(default, code)
    if not self.revert_list then
        self.revert_list = {}
        for name, obj in pairs(default) do
            local code = obj['_origin_id']
            local list = self.revert_list[code]
            if not list then
                self.revert_list[code] = name
            else
                if type(list) ~= 'table' then
                    self.revert_list[code] = {[list] = true}
                end
                self.revert_list[code][name] = true
            end
        end
    end
    return self.revert_list[code]
end

function mt:get_unit_list(default, name)
    if not self.unit_list then
        self.unit_list = {}
        for name, obj in pairs(default) do
            local _name = obj['_name']
            if _name then
                local list = self.unit_list[_name]
                if not list then
                    self.unit_list[_name] = name
                else
                    if type(list) ~= 'table' then
                        self.unit_list[_name] = {[list] = true}
                    end
                    self.unit_list[_name][name] = true
                end
            end
        end
    end
    return self.unit_list[name]
end

function mt:add_template_data(template, name, data)
	local has_temp = true
	if not template then
		template = {}
		has_temp = false
	end
	local all_same = true
	local template = template[name]
	if type(template) ~= 'table' then
		template = {template}
	end
	for i = data._max_level, 1, -1 do
		local temp_data = template[i] or template[#template]
		if not temp_data and has_temp then
			temp_data = self:to_type(data['_c4id'])
            if not temp_data and i == 1 then
                temp_data = ''
            end
		end
		if data[i] == nil then
			data[i] = temp_data
		else
			if data[i] ~= temp_data then
				all_same = false
			end
		end
        if all_same and (self.config['unpack']['remove_same'] or (data['_slk'] and data['_slk'][i])) and i > 1 then
            data[i] = nil
            data._max_level = i - 1
        elseif has_temp == false and i == data._max_level and data[i] == data[i-1] then
            data[i] = nil
            data._max_level = i - 1
        end
	end
	return all_same and has_temp
end

function mt:find_max_level(id, datas)
	local key = self.max_level_key
	if not key then
		return nil
	end
    if not self.template then
        return 4
    end
	local data = datas[key]
	if data then
        return data[1]
    else
		return self.template[id][key]
	end
end

function mt:count_max_level(skill, name, data, max_level)
	data._max_level = 1
	local meta = self.meta[data['_c4id']]
	if max_level and meta['repeat'] and meta['repeat'] > 0 then
		data._max_level = max_level
	end
	if self.template and self.config['unpack']['remove_over_level'] then
		return
	end
	for k in pairs(data) do
		if type(k) == 'number' and k > data._max_level then
			data._max_level = k
		end
	end
end

function mt:to_type(id, value)
    local tp = self:get_id_type(id)
    if tp == 0 then
        value = math.floor(tonumber(value) or 0)
    elseif tp == 1 or tp == 2 then
        value = (tonumber(value) or 0.0) + 0.0
    elseif tp == 3 then
        if type(value) == 'string' then
            if value:match '^%s*[%-%_]%s*$' then
                value = nil
            end
        end
    end
    return value
end

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:format_name(name)
	local meta  = self.meta[name]
	local name  = meta['field']
	local num   = meta['data']
	if num and num ~= 0 then
		name = name .. string_char(('A'):byte() + num - 1)
	end
	if meta['_has_index'] then
		name = name .. ':' .. (meta['index'] + 1)
	end
	return name
end

return function (w2l, ttype, file_name, data)
    local tbl = setmetatable({}, mt)
    tbl.meta = w2l:read_metadata(ttype)
    tbl.key = w2l:parse_lni(io.load(w2l.key / (ttype .. '.ini')), file_name)
    tbl.default = w2l:parse_lni(io.load(w2l.default / (ttype .. '.ini')))
    tbl.type = ttype
    tbl.find_id_times = w2l.config['unpack']['find_id_times']

    function tbl:get_id_type(id)
        return w2l:get_id_type(id, tbl.meta)
    end

    tbl:parse_chunk(data)
end
