local parser    = require 'parser'
local optimizer = require 'optimizer'

local function create_report(report, type, max)
    local msgs = report[type]
    if not msgs then
        return
    end
    local fix = 0
    if #msgs > max then
        fix = math.random(0, #msgs - max)
    end
    for i = 1, max do
        local msg = msgs[i+fix]
        if msg then
            message('-report|8脚本优化', msg[1])
            message('-tip', msg[2])
        end
    end
end

return function (w2l, archive)
    local common   = archive:get 'common.j'   or archive:get 'scripts\\common.j'   or io.load(w2l.mpq / 'scripts' / 'common.j')
    local blizzard = archive:get 'blizzard.j' or archive:get 'scripts\\blizzard.j' or io.load(w2l.mpq / 'scripts' / 'blizzard.j')
    local war3map  = archive:get 'war3map.j'  or archive:get 'scripts\\war3map.j'
    local ast
    ast = parser(common,   'common.j',   ast)
    ast = parser(blizzard, 'blizzard.j', ast)
    ast = parser(war3map,  'war3map.j',  ast)
    
    local buf, report = optimizer(ast, w2l.config)

    archive:set('scripts\\war3map.j', false)
    archive:set('war3map.j', buf)

    create_report(report, '脚本混淆失败', 1)
    create_report(report, '没有混淆函数名', 1)
    create_report(report, '强制引用全部函数', 1)
    create_report(report, '引用函数', 5)
    create_report(report, '清除未引用的函数', 10)
    create_report(report, '清除未引用的局部变量', 20)
end
