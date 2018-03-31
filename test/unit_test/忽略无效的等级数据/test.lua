init('ability', 'AOr3')
local obj = load 'obj'
local slk = save('slk', obj, { remove_unuse_object = false })
compare_string(slk.txt, read 'target.txt')
