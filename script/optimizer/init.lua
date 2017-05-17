local simplify = require 'optimizer.simplify'
local converter = require 'optimizer.converter'

return function (ast)
    simplify(ast)
    return converter(ast)
end
