local lines
local jass

local current_function
local get_exp
local add_lines

local function insert_line(str)
    lines[#lines+1] = str
end

local function get_integer(exp)
    local int = exp.value
    if int >= 1000000 then
        int = ('$%X'):format(int)
    else
        int = ('%d'):format(int)
    end
    return int
end

local function get_real(exp)
    local str = ('%.3f'):format(exp.value)
    for i = 1, 3 do
        if str:sub(-1) == '0' then
            str = str:sub(1, -2)
        end
    end
    if #str > 2 and str:sub(1, 2) == '0.' then
        str = str:sub(2)
    end
    return str
end

local function get_available_name(name)
    return name
end

local function get_string(exp)
    return ('"%s"'):format(exp.value:gsub('\r\n', '\\n'):gsub('[\r\n]', '\\n'))
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
    return ('%s(%s)'):format(get_function_name(exp.name), table.concat(args, ','))
end

local function get_add(exp)
    return ('%s+%s'):format(get_exp(exp[1], '+'), get_exp(exp[2], '+'))
end

local function get_sub(exp)
    return ('%s-%s'):format(get_exp(exp[1], '-'), get_exp(exp[2], '-'))
end

local function get_mul(exp)
    return ('%s*%s'):format(get_exp(exp[1], '*'), get_exp(exp[2], '*'))
end

local function get_div(exp)
    return ('%s/%s'):format(get_exp(exp[1], '/'), get_exp(exp[2], '/'))
end

local function get_neg(exp)
    return ('-%s'):format(get_exp(exp[1], 'neg'))
end

local level = {}
level['or']    = 1
level['and']   = 2
level['>']     = 3
level['>=']    = 3
level['<']     = 3
level['<=']    = 3
level['==']    = 3
level['!=']    = 3
level['+']     = 4
level['-']     = 4
level['*']     = 5
level['/']     = 5
level['not']   = 6
level['neg']   = 6
level['paren'] = 6
local function get_equal(exp)
    return ('%s==%s'):format(get_exp(exp[1], '=='), get_exp(exp[2], '=='))
end

local function get_unequal(exp)
    return ('%s!=%s'):format(get_exp(exp[1], '!='), get_exp(exp[2], '!='))
end

local function get_gt(exp)
    return ('%s>%s'):format(get_exp(exp[1], '>'), get_exp(exp[2], '>'))
end

local function get_ge(exp)
    return ('%s>=%s'):format(get_exp(exp[1], '>='), get_exp(exp[2], '>='))
end

local function get_lt(exp)
    return ('%s<%s'):format(get_exp(exp[1], '<'), get_exp(exp[2], '<'))
end

local function get_le(exp)
    return ('%s<=%s'):format(get_exp(exp[1], '<='), get_exp(exp[2], '<='))
end

local function get_and(exp)
    return ('%s and %s'):format(get_exp(exp[1], 'and'), get_exp(exp[2], 'and'))
end

local function get_or(exp)
    return ('%s or %s'):format(get_exp(exp[1], 'or'), get_exp(exp[2], 'or'))
end

local function get_not(exp)
    return ('not %s'):format(get_exp(exp[1], 'not'))
end

local function get_code(exp)
    return ('function %s'):format(get_function_name(exp.name))
end

local priority = {
{'and'},
{'or'},
{'<', '>', '==', '!=', '<=', '>='},
{'not'},
{'+', '-'},
{'*', '/'},
{'neg'},
}

local op_level
local function get_op_level(op)
    if not op_level then
        op_level = {}
        for lv, ops in ipairs(priority) do
            for _, op in ipairs(ops) do
                op_level[op] = lv
            end
        end
    end
    return op_level[op]
end

local function need_paren(op1, op2)
    if not op2 then
        return false
    end
    local lv1, lv2 = get_op_level(op1), get_op_level(op2)
    if not lv1 then
        return false
    end
    return lv1 < lv2
end

function get_exp(exp, op)
    if not exp then
        return nil
    end
    local value
    if exp.type == 'null' then
        value = 'null'
    elseif exp.type == 'integer' then
        value = get_integer(exp)
    elseif exp.type == 'real' then
        value = get_real(exp)
    elseif exp.type == 'string' then
        value = get_string(exp)
    elseif exp.type == 'boolean' then
        value = get_boolean(exp)
    elseif exp.type == 'var' then
        value = get_var(exp)
    elseif exp.type == 'vari' then
        value = get_vari(exp)
    elseif exp.type == 'call' then
        value = get_call(exp)
    elseif exp.type == '+' then
        value = get_add(exp)
    elseif exp.type == '-' then
        value = get_sub(exp)
    elseif exp.type == '*' then
        value = get_mul(exp)
    elseif exp.type == '/' then
        value = get_div(exp)
    elseif exp.type == 'neg' then
        value = get_neg(exp)
    elseif exp.type == '==' then
        value = get_equal(exp)
    elseif exp.type == '!=' then
        value = get_unequal(exp)
    elseif exp.type == '>' then
        value = get_gt(exp)
    elseif exp.type == '<' then
        value = get_lt(exp)
    elseif exp.type == '>=' then
        value = get_ge(exp)
    elseif exp.type == '<=' then
        value = get_le(exp)
    elseif exp.type == 'and' then
        value = get_and(exp)
    elseif exp.type == 'or' then
        value = get_or(exp)
    elseif exp.type == 'not' then
        value = get_not(exp)
    elseif exp.type == 'code' then
        value = get_code(exp)
    end
    if value then
        if need_paren(exp.type, op) then
            value = ('(%s)'):format(value)
        end
        return value
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

local function add_global(global)
    if not global.used then
        return
    end
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
    if not loc.used then
        return
    end
    if loc.array then
        insert_line(('local %s array %s'):format(loc.type, get_var_name(loc.name)))
    else
        local value = get_exp(loc[1])
        if value then
            insert_line(('local %s %s=%s'):format(loc.type, get_var_name(loc.name), value))
        else
            insert_line(('local %s %s'):format(loc.type, get_var_name(loc.name)))
        end
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
    return table.concat(args, ',')
end

local function add_call(line)
    insert_line(('call %s(%s)'):format(get_function_name(line.name), get_args(line)))
end

local function add_set(line)
    insert_line(('set %s=%s'):format(get_var_name(line.name), get_exp(line[1])))
end

local function add_seti(line)
    insert_line(('set %s[%s]=%s'):format(get_var_name(line.name), get_exp(line[1]), get_exp(line[2])))
end

local function add_return(line)
    if line[1] then
        insert_line(('return %s'):format(get_exp(line[1])))
    else
        insert_line('return')
    end
end

local function add_exit(line)
    insert_line(('exitwhen %s'):format(get_exp(line[1])))
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
    insert_line('endif')
end

local function add_loop(chunk)
    insert_line('loop')
    add_lines(chunk)
    insert_line('endloop')
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
            add_return(line)
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
    if not func.used then
        return
    end
    current_function = func
    insert_line(([[native %s takes %s returns %s]]):format(get_function_name(func.name), get_takes(func), get_returns(func)))
end

local function add_function(func)
    if not func.used then
        return
    end
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
