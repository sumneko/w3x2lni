init('misc', 'HERO')
local obj = load('all', { read_slk = true })
compare_string(obj.obj.name, '一个英雄')
