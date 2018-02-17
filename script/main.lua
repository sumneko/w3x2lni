local function run_from_bat()
    local nk = require 'nuklear'
    nk:console()
    local std_print = print
    local cmd = table.remove(arg, 1)
    local suc, msg = xpcall(function()
        if cmd == '-prebuilt' then
            require 'prebuilt.init'
        elseif cmd == '-slk_test' then
            require 'slk_test'
        elseif cmd == '-mpq' then
            require 'custom_mpq'
        elseif cmd == '-fix_wtg' then
            require 'fix_wtg'
        end
    end, debug.traceback)
    if not suc then
        std_print(msg)
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
