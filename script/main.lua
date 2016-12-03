if arg[1] == '-backend' then
	table.remove(arg, 1)
	require 'make'
elseif arg[1] == '-prebuilt' then
	table.remove(arg, 1)
	require 'prebuilt'
else
	require 'gui.main'
end
