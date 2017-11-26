local function standard()
    local r = {}
    for _, s in ipairs {
        'package',
        'coroutine',
        'table',
        'io',
        'os',
        'string',
        'math',
        'utf8',
        'debug',
        'assert',
        'collectgarbage',
        'dofile',
        'error',
        'getmetatable',
        'ipairs',
        'loadfile',
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
    } do
        r[s] = _G[s]
    end
    return r
end

local function searcher_lua(name, _PATH)
	local filename, err = package.searchpath(name, _PATH)
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

local function require_load(name, _PATH)
    local msg = ''
	for _, searcher in ipairs { searcher_c, searcher_lua } do
        local f, extra = searcher(name, _PATH)
        if type(f) == 'function' then
            return f, extra
        elseif type(f) == 'string' then
            msg = msg .. f
        end
    end
    error(("module '%s' not found:%s"):format(name, f))
end

local function require(name, _LOADED, _PATH, _ENV)
    assert(type(name) == "string", ("bad argument #1 to 'require' (string expected, got %s)"):format(type(name)))
	local p = _LOADED[name]
	if p ~= nil then
		return p
	end
	local init, extra = require_load(name, _PATH)
    debug.setupvalue(init, 1, _ENV)
	local res = init(name, extra)
	if res ~= nil then
		_LOADED[name] = res
	end
	if _LOADED[name] == nil then
		_LOADED[name] = true
	end
	return _LOADED[name]
end

local function sandbox(dir)
    local _ENV = standard()
    local _PATH = ''
    local _IO_PATH = ''
    local _LOADED = {}
    if dir then
        local pos = dir:find [[[/\][^\/]*$]]
        if pos then
            _PATH = dir:sub(1, pos) .. '?.lua'
            _IO_PATH = dir:sub(1, pos)
        end
    end
    _ENV.require = function (name)
        return require(name, _LOADED, _PATH, _ENV)
    end
    _ENV.package = {
        loaded = _LOADED,
        path = _PATH,
        searchpath = package.searchpath,
    }
    local io_open = io.open
    _ENV.io = {
        open = function (path, mode)
            return io_open(_IO_PATH .. path, mode)
        end,
    }
    return _ENV
end

local function load(name, searchers)
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
    assert(type(name) == "string", ("bad argument #1 to 'import' (string expected, got %s)"):format(type(name)))
	local p = _SANDBOX[name]
	if p ~= nil then
		return p
	end
	local init, extra = load(name, package.searchers)
    debug.setupvalue(init, 1, sandbox(extra))
	local res = init(name, extra)
	if res ~= nil then
		_SANDBOX[name] = res
	end
	if _SANDBOX[name] == nil then
		_SANDBOX[name] = true
	end
	return _SANDBOX[name]
end
