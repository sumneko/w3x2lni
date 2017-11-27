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

local function make_preload(list)
    if not list then
        return {}
    end
    local res = {}
    for _, name in ipairs(list) do
        local r = require(name)
        res[name] = function() return r end
    end
    return res
end

local function sandbox_env(dir, prelist)
    local _E = standard()
    local _ROOT = ''
    local _PRELOAD = make_preload(prelist)
    local _LOADED = {}
    if dir then
        local pos = dir:find [[[/\][^\/]*$]]
        if pos then
            _ROOT = dir:sub(1, pos)
        end
    end

    _package_load = package.load
    if not _package_load then
        function _package_load(path)
            local f, e = io.open(path)
            if not f then
                return nil, e
            end
            local buf = f:read 'a'
            f:close()
            return buf
        end
    end

    local function package_load(path)
        return _package_load(_ROOT .. path)
    end

    local function searchpath(name, path)
        local err = ''
    	name = string.gsub(name, '%.', '/')
    	for c in string.gmatch(path, '[^;]+') do
    		local filename = string.gsub(c, '%?', name)
    		local buf = package_load(filename)
    		if buf then
    			return filename, buf
    		end
            err = err .. ("\n\tno file '%s'"):format(filename)
        end
        return nil, err
    end

    local function searcher_preload(name)
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
    	local f, err = load(err, '@' .. filename)
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
        loaded = _LOADED,
        path = '?.lua',
        preload = _PRELOAD,
        searchers = { searcher_preload, searcher_lua },
        searchpath = function(name, path)
            local r, e = searchpath(name, path)
            if r then return r end
            return nil, e
        end
    ,
        load = package_load,
    }
    _E.io = {
        open = function(path)
            return io.open(_ROOT .. path)
        end,
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
return function(name, prelist)
    assert(type(name) == "string", ("bad argument #1 to 'sandbox' (string expected, got %s)"):format(type(name)))
	local p = _SANDBOX[name]
	if p ~= nil then
		return p
	end
	local init, extra = sandbox_load(name, package.searchers)
    debug.setupvalue(init, 1, sandbox_env(extra, prelist))
	local res = init(name, extra)
	if res ~= nil then
		_SANDBOX[name] = res
	end
	if _SANDBOX[name] == nil then
		_SANDBOX[name] = true
	end
	return _SANDBOX[name]
end
