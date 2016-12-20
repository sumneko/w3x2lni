local mpq = require 'archive_mpq'

return function (pathorhandle, tp)
    if type(pathorhandle) == 'number' or not fs.is_directory(pathorhandle) then
        return mpq(pathorhandle, tp)
    else
        -- TODO:
    end
end
