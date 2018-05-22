local root = fs.current_path():parent_path()

local function loaddata(filepath)
    local f, e = io.open((root / filepath):string(), 'rb')
    if f then
        if f:read(3) ~= '\xEF\xBB\xBF' then
            f:seek('set')
        end
        local content = f:read 'a'
        f:close()
        return content
    else
        return false, e
    end
end

return (require 'backend.sandbox')('.\\core\\', io.open, { 
    ['w3xparser'] = require 'w3xparser',
    ['lni']       = require 'lni',
    ['lpeg']      = require 'lpeg',
    ['lml']       = require 'lml',
    ['lang']      = require 'share.lang',
    ['filesystem'] = fs,
    ['loaddata']   = loaddata
})
