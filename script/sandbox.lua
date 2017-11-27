local function standard()
    local r = {}
    for _, s in ipairs {
        --'package',
        'coroutine',
        'table',
        --'io',
        'os',
        'string',
        'math',
        'utf8',
        'debug',
        'assert',
        'collectgarbage',
        --'dofile',
        'error',
        'getmetatable',
        'ipairs',
        --'loadfile',
        'load',
        'next',
        'pairs',
        'pcall',
        'print',
        'rawequal',
        'rawlen',
        'rawget',
        'rawset',
        'select',
        'setmetatable',
        'tonumber',
        'tostring',
        'type',
        'xpcall',
        '_VERSION',
        --'require',
    } do
        r[s] = _G[s]
    end
    return r
end

local function sandbox_env(dir)
    local _E = standard()
    local _ROOT = ''
    if dir then
        local pos = dir:find [[[/\][^\/]*$]]
        if pos then
            _ROOT = dir:sub(1, pos)
        end
    end

    local function io_open(path, ...)
        --TODO
        return io.open(_ROOT .. path, ...)
    end

    local function loadfile(name, ...)
        local f, err = io_open(name)
        if not f then
            return nil, err
        end
        local buf = f:read 'a'
        f:close()
        return load(buf, '@' .. name, ...)
    end

    local function searchpath(name, path)
        local err = ''
    	name = string.gsub(name, '%.', '/')
    	for c in string.gmatch(path, '[^;]+') do
    		local filename = string.gsub(c, '%?', name)
    		local f = io_open(filename)
    		if f then
    			f:close()
    			return filename
    		end
            err = err .. ("\n\tno file '%s'"):format(_ROOT .. filename)
        end
        return nil, err
    end

    local function searcher_preload(name)
        local _PRELOAD = _E.package.preload
        assert(type(_PRELOAD) == "table", "'package.preload' must be a table")
        if _PRELOAD[name] == nil then
            return ("\n\tno field package.preload['%s']"):format(name)
        end
        return _PRELOAD[name]
    end
    
    local function searcher_lua(name)
        assert(type(_E.package.path) == "string", "'package.path' must be a string")
    	local filename, err = searchpath(name, _E.package.path)
    	if not filename then
    		return err
    	end
    	local f, err = loadfile(filename)
    	if not f then
    		error(("error loading module '%s' from file '%s':\n\t%s"):format(name, filename, err))
    	end
    	return f, filename
    end

    local function searcher_c(name)
        local symbolname = string.gsub(name, "%.", "_")
        local pos = symbolname:find '-'
        if pos then
            symbolname = symbolname:sub(1, pos-1)
        end
    	local filename, err = package.searchpath(name, package.cpath)
    	if not filename then
    		return err
    	end
        local f, err = package.loadlib(filename, "luaopen_"..symbolname)
        if not f then
            error(("error loading module '%s' from file '%s':\n\t%s"):format(name, filename, err))
        end
    	return f, filename
    end

    local function require_load(name)
        local msg = ''
        local _SEARCHERS = _E.package.searchers
        assert(type(_SEARCHERS) == "table", "'package.searchers' must be a table")
    	for _, searcher in ipairs(_SEARCHERS) do
            local f, extra = searcher(name)
            if type(f) == 'function' then
                return f, extra
            elseif type(f) == 'string' then
                msg = msg .. f
            end
        end
        error(("module '%s' not found:%s"):format(name, msg))
    end

    _E.require = function(name)
        assert(type(name) == "string", ("bad argument #1 to 'require' (string expected, got %s)"):format(type(name)))
        local _LOADED = _E.package.loaded
    	local p = _LOADED[name]
    	if p ~= nil then
    		return p
    	end
    	local init, extra = require_load(name)
        debug.setupvalue(init, 1, _E)
    	local res = init(name, extra)
    	if res ~= nil then
    		_LOADED[name] = res
    	end
    	if _LOADED[name] == nil then
    		_LOADED[name] = true
    	end
    	return _LOADED[name]
    end
    _E.package = {
        config = [[
            \
            ;
            ?
            !
            -
        ]],
        loaded = {},
        path = '?.lua',
        preload = {},
        searchers = { searcher_preload, searcher_c, searcher_lua },
        searchpath = searchpath,
    }
    _E.io = {
        open = io_open,
    }
    return _E
end

local function sandbox_load(name, searchers)
    assert(type(searchers) == "table", "'package.searchers' must be a table")
    local msg = ''
    for _, searcher in ipairs(searchers) do
        local f, extra = searcher(name)
        if type(f) == 'function' then
            return f, extra
        elseif type(f) == 'string' then
            msg = msg .. f
        end
    end
    error(("module '%s' not found:%s"):format(name, msg))
end

local _SANDBOX = {}
return function(name)
    assert(type(name) == "string", ("bad argument #1 to 'sandbox' (string expected, got %s)"):format(type(name)))
	local p = _SANDBOX[name]
	if p ~= nil then
		return p
	end
	local init, extra = sandbox_load(name, package.searchers)
    debug.setupvalue(init, 1, sandbox_env(extra))
	local res = init(name, extra)
	if res ~= nil then
		_SANDBOX[name] = res
	end
	if _SANDBOX[name] == nil then
		_SANDBOX[name] = true
	end
	return _SANDBOX[name]
end
