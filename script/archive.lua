local mpq = require 'archive_mpq'
local dir = require 'archive_dir'

return function (pathorhandle, tp)
    if type(pathorhandle) == 'number' or not fs.is_directory(pathorhandle) then
        return mpq(pathorhandle, tp)
    else
        return dir(pathorhandle, tp)
    end
end
