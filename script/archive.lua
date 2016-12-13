local mpq = require 'archive_mpq'

return function (pathorhandle)
    if type(pathorhandle) == 'number' or not fs.is_directory(pathorhandle) then
        return mpq(pathorhandle)
    else
        -- TODO:
    end
end
