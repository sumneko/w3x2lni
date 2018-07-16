init('ability', 'AOr3')
local obj = load 'obj'
obj.obj.name = 'Name'
obj.obj.researchtip = 'Researchtip'
obj.obj.researchubertip = 'Researchubertip'
obj.obj.tip = {'Tip', 'Tip'}
obj.obj.ubertip = {'Ubertip', 'Ubertip'}
local slk = save('slk', obj, { remove_unuse_object = false })
compare_string(slk.txt, read 'target.txt')
