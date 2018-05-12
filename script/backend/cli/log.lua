require 'filesystem'
require 'utility'
local messager = require 'share.messager'

return function ()
    local root = fs.current_path()
    local s = {}
    for l in io.lines((root:parent_path() / 'log' / 'report.log'):string()) do
        s[#s+1] = l
        if #s > 50 then
            messager.raw(table.concat(s, '\r\n') .. '\r\n')
            messager.wait()
            s = {}
        end
    end
    messager.raw(table.concat(s, '\r\n') .. '\r\n')
end
