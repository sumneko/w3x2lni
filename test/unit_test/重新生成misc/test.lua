local config = require 'share.config'

init('misc', 'Misc')
local obj = load('all')
local slk = save('obj', obj)
compare_string(slk.obj, read 'war3mapmisc.txt')
local obj = load('all')
local slk = save('lni', obj)
if config.global.data == 'zhCN-1.24.4' then
    compare_string(slk.lni, read 'zhCN-misc.ini')
else
    compare_string(slk.lni, read 'enUS-misc.ini')
end
local obj = load('all')
local slk = save('slk', obj)
compare_string(slk.obj, read 'war3mapmisc.txt')
