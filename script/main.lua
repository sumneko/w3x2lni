if arg[1] == '-backend' then
    table.remove(arg, 1)
    require 'map'
elseif arg[1] == '-prebuilt' then
    local nk = require 'nuklear'
    nk:console()
    table.remove(arg, 1)
    local prebuilt = require 'prebuilt.init'
    os.execute('pause')
elseif arg[1] == '-slk' then
    local nk = require 'nuklear'
    nk:console()
    table.remove(arg, 1)
    require 'slk'
    os.execute('pause')
elseif arg[1] == '-mpq' then
    local nk = require 'nuklear'
    nk:console()
    table.remove(arg, 1)
    require 'custom_mpq'
    os.execute('pause')
else
    require 'gui.main'
end
