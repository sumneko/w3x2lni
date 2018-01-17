local sandbox = require 'sandbox'

local function getparent(path)
    if path then
        local pos = path:find [[[/\][^\/]*$]]
        if pos then
            return path:sub(1, pos)
        end
    end
end

local function search_init(name)
    local searchers = package.searchers
    assert(type(searchers) == "table", "'package.searchers' must be a table")
    local msg = ''
    for _, searcher in ipairs(searchers) do
        local f, extra = searcher(name)
        if type(f) == 'function' then
            local root = getparent(extra)
            if not root then
                return error(("module '%s' not found"):format(name))
            end
            return root
        elseif type(f) == 'string' then
            msg = msg .. f
        end
    end
    error(("module '%s' not found:%s"):format(name, msg))
end

local function loadlua(name, read)
    local f = io._open(name, 'r')
    if not read then
        local ok = not not f
        f:close()
        return ok
    end
    if f then
        local str = f:read 'a'
        f:close()
        return load(str, '@' .. name)
    end
end

local root = search_init('core')

return sandbox(root, loadlua, { 
    ['w3xparser'] = require 'w3xparser',
    ['lni-c']     = require 'lni-c',
    ['lpeg']      = require 'lpeg',
    ['io']        = { open = io._open }
})()
