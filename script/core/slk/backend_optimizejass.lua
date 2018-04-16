local parser    = require 'parser.init'
local optimizer = require 'optimizer.init'

local function create_report(w2l, report, title, type, max)
    local msgs = report[type]
    if not msgs then
        return
    end
    local fix = 0
    if #msgs > max then
        fix = math.random(0, #msgs - max)
    end
    if title then
        w2l.messager.report('脚本优化', 8, ('%d.%s    总计：%d'):format(title, type, #msgs))
    end
    for i = 1, max do
        local msg = msgs[i+fix]
        if msg then
            w2l.messager.report('脚本优化', 8, msg[1], msg[2])
        end
    end
end

return function (w2l)
    local common   = w2l:file_load('map', 'common.j')   or w2l:file_load('map', 'scripts\\common.j')   or w2l:mpq_load('scripts\\common.j')
    local blizzard = w2l:file_load('map', 'blizzard.j') or w2l:file_load('map', 'scripts\\blizzard.j') or w2l:mpq_load('scripts\\blizzard.j')
    local war3map  = w2l:file_load('map', 'war3map.j')  or w2l:file_load('map', 'scripts\\war3map.j')
    if not war3map then
        w2l.messager.report('严重错误', 1, '没有找到脚本')
        return
    end
    local function messager(...)
        local t = table.pack(...)
        for i = 1, t.n do
            t[i] = tostring(t[i])
        end
        w2l.messager.report('脚本优化', 8, table.concat(t, '\t'))
    end
    local ast
    ast = parser(common,   'common.j',   ast, messager)
    ast = parser(blizzard, 'blizzard.j', ast, messager)
    ast = parser(war3map,  'war3map.j',  ast, messager)
    
    local buf, report = optimizer(ast, w2l.config, messager)

    if w2l:file_load('map', 'war3map.j') then
        w2l:file_save('map', 'war3map.j', buf)
    else
        w2l:file_save('map', 'scripts\\war3map.j', buf)
    end

    create_report(w2l, report, 1,   '混淆脚本',        10)
    create_report(w2l, report, 2,   '引用函数',        5)
    create_report(w2l, report, 3,   '未引用的全局变量', 20)
    create_report(w2l, report, 4,   '未引用的函数',     20)
    create_report(w2l, report, 5,   '未引用的局部变量', 20)
end
