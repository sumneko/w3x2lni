if _W3X2LNI == 'CLI' then
    if arg[1] then
        require 'map'
        return
    end
elseif _W3X2LNI == 'GUI' then
    if arg[1] then
        require 'gui.mini'
        return
    end
    require 'gui.old.main'
end
