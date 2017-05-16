local ipairs = ipairs
local pairs = pairs

local jass
local current_function, current_line
local executes, executed_any
local mark_exp, mark_lines, mark_function

local function mark_var(name)
    if current_function then
        local locals = current_function.locals
        if locals then
            for i = #locals, 1, -1 do
                local loc = locals[i]
                if loc.name == name and loc.line < current_line then
                    loc.used = true
                    return
                end
            end
        end
        local args = current_function.args
        if args and args[name] then
            return
        end
    end
    jass.globals[name].used = true
end

function mark_exp(exp)
    if not exp then
        return
    end
    if exp.type == 'null' or exp.type == 'integer' or exp.type == 'real' or exp.type == 'string' or exp.type == 'boolean' then
    elseif exp.type == 'var' or exp.type == 'vari' then
        mark_var(exp.name)
    elseif exp.type == 'call' or exp.type == 'code' then
        mark_function(exp.name)
    end
    for i = 1, #exp do
        mark_exp(exp[i])
    end
end

local function mark_locals(locals)
    for _, loc in ipairs(locals) do
        if loc[1] then
            current_line = loc.line
            loc.used = true
            mark_exp(loc[1])
        end
    end
end

local function mark_execute(line)
    if not executes then
        executes = {}
    end
    local exp = line[1]
    if exp.type == 'string' then
        mark_function(exp.value)
        return
    end
    if exp.type == '+' then
        if exp[1].type == 'string' then
            executes[exp[1].value] = true
            return
        end
    end
    executed_any = true
end

local function mark_call(line)
    mark_function(line.name)
    for _, exp in ipairs(line) do
        mark_exp(exp)
    end
    if line.name == 'ExecuteFunc' then
        mark_execute(line)
    end
end

local function mark_set(line)
    mark_var(line.name)
    mark_exp(line[1])
end

local function mark_seti(line)
    mark_var(line.name)
    mark_exp(line[1])
    mark_exp(line[2])
end

local function mark_return(line)
    if line[1] then
        mark_exp(line[1])
    end
end

local function mark_exit(line)
    mark_exp(line[1])
end

local function mark_if(data)
    mark_exp(data.condition)
    mark_lines(data)
end

local function mark_elseif(data)
    mark_exp(data.condition)
    mark_lines(data)
end

local function mark_else(data)
    mark_lines(data)
end

local function mark_ifs(chunk)
    for _, data in ipairs(chunk) do
        if data.type == 'if' then
            mark_if(data)
        elseif data.type == 'elseif' then
            mark_elseif(data)
        else
            mark_else(data)
        end
    end
end

local function mark_loop(chunk)
    mark_lines(chunk)
end

function mark_lines(lines)
    for _, line in ipairs(lines) do
        current_line = line.line
        if line.type == 'call' then
            mark_call(line)
        elseif line.type == 'set' then
            mark_set(line)
        elseif line.type == 'seti' then
            mark_seti(line)
        elseif line.type == 'return' then
            mark_return(line)
        elseif line.type == 'exit' then
            mark_exit(line)
        elseif line.type == 'if' then
            mark_ifs(line)
        elseif line.type == 'loop' then
            mark_loop(line)
        end
    end
end

function mark_function(name)
    local func = jass.functions[name]
    if func.used or func.file ~= 'war3map.j' then
        return
    end
    func.used = true
    if func.native then
        return
    end
    local _current_function = current_function
    local _current_line     = current_line
    current_function = func
    mark_locals(func.locals)
    mark_lines(func)
    current_function = _current_function
    current_line     = _current_line
end

local function mark_globals()
    for _, global in ipairs(jass.globals) do
        if global[1] then
            current_line = global.line
            global.used = true
            mark_exp(global[1])
        end
    end
end

local function mark_executed()
    if not executes then
        return
    end
    for _, func in ipairs(jass.functions) do
        if not func.used then
            local name = func.name
            if executed_any then
                mark_function(name)
            else
                for head in pairs(executes) do
                    if name:sub(1, #head) == head then
                        mark_function(name)
                        break
                    end
                end
            end
        end
    end
end

return function (ast)
    jass = ast
    mark_globals()
    mark_function('config')
    mark_function('main')
    mark_executed()
end
