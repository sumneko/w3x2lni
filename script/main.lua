if arg[1] == '-backend' then
	table.remove(arg, 1)
	require 'make'
elseif arg[1] == '-prebuilt' then
	local nk = require 'nuklear'
	nk:console()

	table.remove(arg, 1)
	require 'prebuilt'
	os.execute('pause')
else
	require 'gui.main'
end
