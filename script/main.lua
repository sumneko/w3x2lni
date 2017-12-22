local function run_from_bat()
    local nk = require 'nuklear'
    nk:console()
    local cmd = table.remove(arg, 1)
    if cmd == '-prebuilt' then
        require 'prebuilt.init'
    elseif cmd == '-slk' then
        require 'slk'
    elseif cmd == '-mpq' then
        require 'custom_mpq'
    elseif cmd == '-fix_wtg' then
        require 'fix_wtg'
    end
    os.execute('pause')
end

if arg[1] == '-backend' then
    table.remove(arg, 1)
    require 'map'
elseif arg[1] == nil then
    require 'gui.main'
else
    run_from_bat()
end
