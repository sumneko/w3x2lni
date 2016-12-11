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
    for i = 1, #names do
        local name = names[i]
        self:clean_obj(name, chunk[name])
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('清理数据[%s] (%d/%d)'):format(name, i, #names))
        end
    end
end

function mt:parse_obj(name, obj)
    local code
    local count
    local find_times = self.config['find_id_times']
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

function mt:clean_obj(name, obj)
    local code = obj._origin_id
    local max_level = obj._max_level
    local default = self.default[code]
    local remove_over_level = self.config['remove_over_level']
    local remove_same = self.config['remove_same']
    for key, data in pairs(obj) do
        if remove_over_level and max_level then
            if type(data) == 'table' then
                for level in pairs(data) do
                    if level > max_level then
                        data[level] = nil
                    end
                end
            end
        end
        if remove_same then
            local dest = default[key]
            if type(dest) == 'table' then
                for i = 1, #data do
                    if data[i] == dest[i] then
                        data[i] = nil
                    end
                end
                if not next(data) then
                    obj[key] = nil
                end
            else
                if data == dest then
                    obj[key] = nil
                end
            end
        end
    end
end

return function (w2l, ttype, file_name, data)
    local tbl = setmetatable({}, mt)
    tbl.meta = w2l:read_metadata(ttype)
    tbl.key = w2l:parse_lni(io.load(w2l.key / (ttype .. '.ini')), file_name)
    tbl.default = w2l:parse_lni(io.load(w2l.default / (ttype .. '.ini')))
    tbl.type = ttype
    tbl.config = w2l.config['unpack']

    function tbl:get_id_type(id)
        return w2l:get_id_type(id, tbl.meta)
    end

    tbl:parse_chunk(data)
end
