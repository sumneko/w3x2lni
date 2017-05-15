local lines
local jass

local current_function
local get_exp
local add_lines

local function insert_line(str)
    lines[#lines+1] = str
end

local function int32(int)
    int = int & 0xFFFFFFFF
    if int & 0x80000000 == 0 then
        return int
    else
        return - (((~ int) & 0xFFFFFFFF) + 1)
    end
end

local function get_integer(exp)
    return int32(exp.value)
end

local function get_real(exp)
    local int, float = math.modf(exp.value)
    return int32(int) + float
end

local function get_available_name(name)
    return name
end

local function get_string(exp)
    local str = exp.value
    local lines = {}
    local start = 1
    while start <= #str do
        local pos = str:find('[\r\n]', start) or #str+1
        local line = str:sub(start, pos-1)
        if str:sub(pos, pos+1) == '\r\n' then
            start = pos+2
        else
            start = pos+1
        end
        lines[#lines+1] = line
    end
    return ('"%s"'):format(table.concat(lines, '\\\r\n'))
end

local function get_boolean(exp)
    if exp.value == true then
        return 'true'
    elseif exp.value == false then
        return 'false'
    end
end

local function is_arg(name)
    if not current_function or not current_function.args then
        return false
    end
    return current_function.args[name]
end

local function get_var_name(name)
    return get_available_name(name)
end

local function get_var(exp)
    return get_var_name(exp.name)
end

local function get_vari(exp)
    return ('%s[%s]'):format(get_var_name(exp.name), get_exp(exp[1]))
end

local function get_function_name(name)
    return get_available_name(name)
end

local function get_call(exp)
    local args = {}
    for i, sub_exp in ipairs(exp) do
        args[i] = get_exp(sub_exp)
    end
    return ('%s(%s)'):format(get_function_name(exp.name), table.concat(args, ', '))
end

local function get_type_in_paren(exp)
    while exp.type == 'paren' do
        exp = exp[1]
    end
    return exp.type
end

local function must_string(exp)
    local type = get_type_in_paren(exp)
    if type == 'string' or type == '+' then
        return get_exp(exp)
    end
    return ('(%s or "")'):format(get_exp(exp))
end

local function get_add(exp)
    if exp.vtype == 'integer' or exp.vtype == 'real' then
        return ('%s + %s'):format(get_exp(exp[1]), get_exp(exp[2]))
    elseif exp.vtype == 'string' then
        return ('%s .. %s'):format(must_string(exp[1]), must_string(exp[2]))
    end
    error(('表达式类型错误:%s %s'):format(exp.type, exp.vtype))
end

local function get_sub(exp)
    return ('%s - %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_mul(exp)
    return ('%s * %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_div(exp)
    if exp.vtype == 'integer' then
        return ('%s // %s'):format(get_exp(exp[1]), get_exp(exp[2]))
    elseif exp.vtype == 'real' then
        return ('%s / %s'):format(get_exp(exp[1]), get_exp(exp[2]))
    end
    error(('表达式类型错误:%s %s'):format(exp.type, exp.vtype))
end

local function get_neg(exp)
    return (' - %s'):format(get_exp(exp[1]))
end

local function get_paren(exp)
    return ('(%s)'):format(get_exp(exp[1]))
end

local function get_equal(exp)
    return ('%s == %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_unequal(exp)
    return ('%s ~= %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_gt(exp)
    return ('%s > %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_ge(exp)
    return ('%s >= %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_lt(exp)
    return ('%s < %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_le(exp)
    return ('%s <= %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_and(exp)
    return ('%s and %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_or(exp)
    return ('%s or %s'):format(get_exp(exp[1]), get_exp(exp[2]))
end

local function get_not(exp)
    return ('not %s'):format(get_exp(exp[1]))
end

local function get_code(exp)
    return get_function_name(exp.name)
end

function get_exp(exp)
    if not exp then
        return nil
    end
    if exp.type == 'null' then
        return 'null'
    elseif exp.type == 'integer' then
        return get_integer(exp)
    elseif exp.type == 'real' then
        return get_real(exp)
    elseif exp.type == 'string' then
        return get_string(exp)
    elseif exp.type == 'boolean' then
        return get_boolean(exp)
    elseif exp.type == 'var' then
        return get_var(exp)
    elseif exp.type == 'vari' then
        return get_vari(exp)
    elseif exp.type == 'call' then
        return get_call(exp)
    elseif exp.type == '+' then
        return get_add(exp)
    elseif exp.type == '-' then
        return get_sub(exp)
    elseif exp.type == '*' then
        return get_mul(exp)
    elseif exp.type == '/' then
        return get_div(exp)
    elseif exp.type == 'neg' then
        return get_neg(exp)
    elseif exp.type == 'paren' then
        return get_paren(exp)
    elseif exp.type == '==' then
        return get_equal(exp)
    elseif exp.type == '!=' then
        return get_unequal(exp)
    elseif exp.type == '>' then
        return get_gt(exp)
    elseif exp.type == '<' then
        return get_lt(exp)
    elseif exp.type == '>=' then
        return get_ge(exp)
    elseif exp.type == '<=' then
        return get_le(exp)
    elseif exp.type == 'and' then
        return get_and(exp)
    elseif exp.type == 'or' then
        return get_or(exp)
    elseif exp.type == 'not' then
        return get_not(exp)
    elseif exp.type == 'code' then
        return get_code(exp)
    end
    print('未知的表达式类型', exp.type)
    return nil
end

local function base_type(type)
    while jass.types[type].extends do
        type = jass.types[type].extends
    end
    return type
end

local function new_array(type)
    local default
    local type = base_type(type)
    if type == 'boolean' then
        default = 'false'
    elseif type == 'integer' then
        default = '0'
    elseif type == 'real' then
        default = '0.0'
    else
        default = ''
    end
    return ([[_array_(%s)]]):format(default)
end

local function add_global(global)
    if global.array then
        insert_line(([[%s array %s]]):format(global.type, get_available_name(global.name)))
    else
        local value = get_exp(global[1])
        if value then
            insert_line(([[%s %s=%s]]):format(global.type, get_available_name(global.name), value))
        else
            insert_line(([[%s %s]]):format(global.type, get_available_name(global.name)))
        end
    end
end

local function add_globals()
    insert_line('globals')
    for _, global in ipairs(jass.globals) do
        add_global(global)
    end
    insert_line('endglobals')
end

local function add_local(loc)
    local value = get_exp(loc[1])
    if loc.array then
        value = new_array(loc.type)
    end
    if value then
        insert_line(('local %s = %s'):format(get_var_name(loc.name), value))
    else
        insert_line(('local %s'):format(get_var_name(loc.name)))
    end
end

local function add_locals(locals)
    if #locals == 0 then
        return
    end
    for _, loc in ipairs(locals) do
        add_local(loc)
    end
end

local function get_args(line)
    local args = {}
    for i, exp in ipairs(line) do
        args[i] = get_exp(exp)
    end
    return table.concat(args, ', ')
end

local function add_call(line)
    insert_line(('%s(%s)'):format(get_function_name(line.name), get_args(line)))
end

local function add_set(line)
    insert_line(('%s = %s'):format(get_var_name(line.name), get_exp(line[1])))
end

local function add_seti(line)
    insert_line(('%s[%s] = %s'):format(get_var_name(line.name), get_exp(line[1]), get_exp(line[2])))
end

local function add_return(line, last)
    if last then
        if line[1] then
            insert_line(('return %s'):format(get_exp(line[1])))
        else
            insert_line('return')
        end
    else
        if line[1] then
            insert_line(('do return %s end'):format(get_exp(line[1])))
        else
            insert_line('do return end')
        end
    end
end

local function add_exit(line)
    insert_line(('if %s then break end'):format(get_exp(line[1])))
end

local function add_if(data)
    insert_line(('if %s then'):format(get_exp(data.condition)))
    add_lines(data)
end

local function add_elseif(data)
    insert_line(('elseif %s then'):format(get_exp(data.condition)))
    add_lines(data)
end

local function add_else(data)
    insert_line('else')
    add_lines(data)
end

local function add_ifs(chunk)
    for _, data in ipairs(chunk) do
        if data.type == 'if' then
            add_if(data)
        elseif data.type == 'elseif' then
            add_elseif(data)
        elseif data.type == 'else' then
            add_else(data)
        else
            print('未知的判断类型', line.type)
        end
    end
    insert_line('end')
end

local function add_loop(chunk)
    insert_line('for _ in _loop_() do')
    add_lines(chunk)
    insert_line('end')
end

function add_lines(chunk)
    for i, line in ipairs(chunk) do
        if line.type == 'call' then
            add_call(line)
        elseif line.type == 'set' then
            add_set(line)
        elseif line.type == 'seti' then
            add_seti(line)
        elseif line.type == 'return' then
            add_return(line, #chunk == i)
        elseif line.type == 'exit' then
            add_exit(line)
        elseif line.type == 'if' then
            add_ifs(line)
        elseif line.type == 'loop' then
            add_loop(line)
        else
            print('未知的代码行类型', line.type)
        end
    end
end

local function get_takes(func)
    if not func.args then
        return 'nothing'
    end
    local takes = {}
    for i, arg in ipairs(func.args) do
        takes[i] = ('%s %s'):format(arg.type, get_available_name(arg.name))
    end
    return table.concat(takes, ',')
end

local function get_returns(func)
    if func.returns then
        return func.returns
    else
        return 'nothing'
    end
end

local function add_native(func)
    current_function = func
    insert_line(([[native function %s takes %s returns %s]]):format(get_function_name(func.name), get_takes(func), get_returns(func)))
end

local function add_function(func)
    current_function = func
    insert_line(([[function %s takes %s returns %s]]):format(get_function_name(func.name), get_takes(func), get_returns(func)))
    add_locals(func.locals)
    add_lines(func)
    insert_line('endfunction')
end

local function add_functions()
    for _, func in ipairs(jass.functions) do
        if func.native then
            add_native(func)
        else
            add_function(func)
        end
    end
end

return function (ast)
    lines = {}
    jass = ast

    add_globals()
    add_functions()

    lines[#lines+1] = ''

    return table.concat(lines, '\r\n')
end
