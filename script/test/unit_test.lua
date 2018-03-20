require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local core = require 'tool.sandbox_core'

local std_print = print
local std_error = error
local function print(...)
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i]))
    end
    std_print(table.unpack(tbl))
end

local function assert(ok, msg)
    if ok then
        return
    end
    std_error(uni.u2a(msg), 2)
end

local function error(msg)
    std_error(uni.u2a(msg), 2)
end

local function load_config(path)
    local buf = io.load(path / '.config')
    if not buf then
        return
    end
    local type, id = buf:match '(%C+)%c*(%C+)'
    return type, id
end

local function add_loader(w2l)
    local mpq_path = fs.current_path():parent_path() / 'data' / 'mpq'
    local prebuilt_path = fs.current_path():parent_path() / 'data' / 'prebuilt'

    function w2l:mpq_load(filename)
        return w2l.mpq_path:each_path(function(path)
            return io.load(mpq_path / path / filename)
        end)
    end
    
    function w2l:prebuilt_load(filename)
        return w2l.mpq_path:each_path(function(path)
            return io.load(prebuilt_path / path / filename)
        end)
    end
end

local function load_obj(type, id, path)
    local w2l = core()

    add_loader(w2l)

    local target_name = w2l.info.obj[type]
    function w2l:map_load(filename)
        if filename == target_name then
            return io.load(path / filename)
        end
    end

    w2l:frontend()
    return w2l.slk[type][id]
end

local function load_lni(type, id, path)
    local w2l = core()

    add_loader(w2l)

    local target_name = w2l.info.lni[type]
    function w2l:map_load(filename)
        if filename == target_name then
            print(path / (type .. '.ini'))
            return io.load(path / (type .. '.ini'))
        end
    end

    w2l:frontend()
    return w2l.slk[type][id]
end

local function load_slk(type, id, path)
    local w2l = core()

    add_loader(w2l)

    w2l:set_config {
        read_slk = true,
    }

    local target_names = {}
    for _, name in ipairs(w2l.info.txt) do
        target_names[name] = name:sub(7)
    end
    for _, name in ipairs(w2l.info.slk[type]) do
        target_names[name] = name:sub(7)
    end
    
    function w2l:map_load(filename)
        if target_names[filename] then
            return io.load(path / target_names[filename])
        end
    end

    w2l:frontend()
    return w2l.slk[type][id]
end

local function eq(v1, v2)
    for k in pairs(v1) do
        if k:sub(1, 1) == '_' then
            goto CONTINUE
        end
        if type(v1[k]) ~= type(v2[k]) then
            return false, ('[%s] - [%s](%s):[%s](%s)'):format(k, v1[k], type(v1[k]), v2[k], type(v2[k]))
        end
        if type(v1[k]) == 'table' then
            if #v1[k] ~= #v2[k] then
                return false, ('[%s] - #%s:#%s'):format(k, #v1[k], #v2[k])
            end
            for i = 1, #v1[k] do
                if v1[k][i] ~= v2[k][i] then
                    return false, ('[%s][%s] - [%s](%s):[%s](%s)'):format(k, #v1[k], v1[k][i], type(v1[k][i]), v2[k][i], type(v2[k][i]))
                end
            end
        else
            if v1[k] ~= v2[k] then
                return false, ('[%s] - [%s](%s):[%s](%s)'):format(k, v1[k], type(v1[k]), v2[k], type(v2[k]))
            end
        end
        ::CONTINUE::
    end
    return true
end

local function eq_test(v1, v2, callback)
    local ok, msg = eq(v1, v2)
    if ok then
        return
    end
    callback(msg)
end

local function do_test(path)
    local name = path:filename():string()
    local type, id = load_config(path)
    
    local dump_obj = load_obj(type, id, path)
    local dump_lni = load_lni(type, id, path)
    local dump_slk = load_slk(type, id, path)

    assert(dump_obj, ('\n<%s> 没有读取到%s - [%s][%s]'):format(name, 'obj', type, id))
    assert(dump_lni, ('\n<%s> 没有读取到%s - [%s][%s]'):format(name, 'lni', type, id))
    assert(dump_slk, ('\n<%s> 没有读取到%s - [%s][%s]'):format(name, 'slk', type, id))
    eq_test(dump_obj, dump_lni, function (msg)
        error(('\n<%s> %s 与 %s 不等 - [%s][%s]\n%s'):format(name, 'obj', 'lni', type, id, msg))
    end)
    eq_test(dump_obj, dump_slk, function (msg)
        error(('\n<%s> %s 与 %s 不等 - [%s][%s]\n%s'):format(name, 'obj', 'slk', type, id, msg))
    end)
end

local test_dir = fs.current_path() / 'test' / 'unit_test'
for path in test_dir:list_directory() do
    do_test(path)
end

print('单元测试完成')
