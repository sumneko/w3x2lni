if arg[1] == '-nogui' then
	local nk = require 'nuklear'
	--nk:console()
	table.remove(arg, 1)
	require 'make'
	os.execute('pause')
else
	require 'gui.main'
end
