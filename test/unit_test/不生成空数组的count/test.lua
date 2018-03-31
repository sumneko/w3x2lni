init('upgrade', 'Rhac')
local obj = load 'lni'
local slk = save('slk', obj, { remove_unuse_object = false })
compare_string(slk.txt, read 'target.txt')
