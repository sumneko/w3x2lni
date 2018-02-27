local wtg
local wct

local function sort_pairs(data)
    local keys = {}
    for k in pairs(data) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    local i = 0
    return function ()
        i = i + 1
        local k = keys[i]
        return k, data[k]
    end
end

local function format_value(v)
    local tp = type(v)
    if tp == 'string' then
        if v:find('[\n\r]') then
            v = ('[[\n%s]]'):format(v)
        elseif not v:find('%D') then
            v = ("'%s'"):format(v)
        end
    end
    return v
end

local function write_obj(lines, name, data)
    lines[#lines+1] = ('[%s]'):format(name)
    for k, v in sort_pairs(data) do
        lines[#lines+1] = ('%s = %s'):format(k, format_value(v))
    end
end

local function write_lni(data)
    local lines = {}
    local tbls = {}
    local root = {}
    for name, data in pairs(data) do
        if type(data) == 'table' then
            tbls[name] = data
        else
            root[name] = data
        end
    end
    if next(root) then
        write_obj(lines, 'root', root)
    end
    for name, data in sort_pairs(tbls) do
        write_obj(lines, name, data)
    end

    return table.concat(lines, '\n')
end

local function writer(files)
    for key, data in pairs(files) do
        files[key] = write_lni(data)
    end
    return files
end

local function read_info()
    local data = {}
    if wtg then
        data.wtg = {
            id = wtg.file_id,
            ver = wtg.file_ver,
            unknow = wtg.unknow,
        }
    end
    if wct then
        data.wct = {
            ver = wct.file_ver,
        }
    end
    return data
end

local function read_custom()
    local data = {}
    if wct then
        data.comment = wct.custom.comment
        data.code = wct.custom.code
    end
    return data
end

local function read_vars()
    local data = {}
    if wtg then
        for i, var in ipairs(wtg.vars) do
            data[i] = var
        end
    end
    return data
end

return function (w2l, wtg_, wct_)
    wtg = wtg_
    wct = wct_

    local files = {}

    files['.info'] = read_info()
    files['.自定义代码'] = read_custom()
    files['.变量'] = read_vars()

    return writer(files)
end
