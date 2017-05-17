local simplify = require 'optimizer.simplify'
local converter = require 'optimizer.converter'

return function (ast)
    local report = {}

    local function message(type, msg, tip)
        if not report[type] then
            report[type] = {}
        end
        report[type][#report[type]+1] = {msg, tip}
    end
    
    simplify(ast, message)
    return converter(ast, message), report
end
