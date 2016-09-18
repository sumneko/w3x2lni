local table_insert = table.insert
local math_tointeger = math.tointeger
local string_dump = string.dump
local mt = {}
local marco = {}
local function split(str, p) local rt = {} str:gsub('[^'..p..']+', function (w) table_insert(rt, w) end) return rt end
function mt:loader(code, ac, default)
	if code:sub(1, 3) == '\xEF\xBB\xBF' then code = code:sub(4) end
	local function dostring(ln, str, env) return assert(load(str, '=line<' .. ln .. '>', 't', env))() end
	local function trim(str) return str:gsub('^%s*(.-)%s*$', '%1') end
	local function table_copy(tbl) local res = {} if tbl then for k, v in pairs(tbl) do res[k] = v end end return res end
	local self = nil
	local multi_table = nil
	local multi_string = nil
	ac = ac or {}
	default = table_copy(default)
	for ln, line in ipairs(split(code, '\n')) do
		line = trim(line)
		if multi_string then
			multi_string = multi_string .. '\n' .. line
			if line:sub(-2) == ']]' then
				dostring(ln, multi_string, self)
				multi_string = nil
			end
		elseif multi_table then
			multi_table = multi_table .. '\n' .. line
			if line:sub(-1) == '}' then
				dostring(ln, multi_table, self)
				multi_table = nil
			end
		else
			if line:sub(1,1) == '[' then
				local name = line:sub(3,-3)
				if name == 'default' then
					self = default
				else
					self = setmetatable(table_copy(default), { __index = ac })
					ac[name] = self
				end
			elseif line:sub(1,2) == '--' then
			elseif line:sub(-2) == '[[' then
				multi_string = line
			elseif line:sub(-1) == '{' then
				multi_table = line
			elseif line:sub(1,1) == [[']] then
				dostring(ln, line:gsub([[^('.-')]], '_ENV[%1]'), self)
			elseif line:sub(1, 1) == [["]] then
				dostring(ln, line:gsub([[^(".-")]], '_ENV[%1]'), self)
			elseif line:find([[^%d]]) ~= nil then
				dostring(ln, line:gsub([[^(%d+)]], '_ENV[%1]'), self)
			else
				dostring(ln, line, self)
			end
		end
	end
	return ac, default
end
function mt:unpacker(abil)
	local spell = {}
	local max_level = abil.max_level
	if not max_level then
		max_level = 1
		for key, value in pairs(abil) do
			if type(value) == 'table' and type(value[1]) == 'number' then
				if max_level < #value then max_level = #value end
			end
		end
	end
	for lvl = 1, max_level do
		spell[lvl] = { max_level = max_level }
	end
	for key, value in pairs(abil) do
		if type(value) == 'table' then
			if type(value[1]) ~= 'number' then
				for lvl = 1, max_level do
				 	spell[lvl][key] = value
				end
			elseif #value == 1 then
				for lvl = 1, max_level do
				 	spell[lvl][key] = value[1]
				end
			elseif #value == max_level then
				for lvl = 1, max_level do
					spell[lvl][key] = value[lvl]
				end
			else
				local first = value[1]
				local last = value[#value]
				local dv = (last - first) / (max_level - 1)
				for lvl = 1, max_level do
					spell[lvl][key] = first + dv * (lvl - 1)
				end
			end
		else
			for lvl = 1, max_level do
				spell[lvl][key] = value
			end
		end
	end
	return spell
end
function mt:dostringer(str, keyval, sep, hero)
	if not hero or type(hero) ~= 'table' then
		hero = {}
	end
	function hero:get(name)
		return self[name]
	end
	local env = setmetatable(keyval, {__index = _G})
	local function setfenv(f)
		return load(string_dump(f), '=(load)', nil, env)
	end
	local function dostring(str, env)
		return str
	end
	local function format(n, env)
		if type(n) == 'number' then
			return math_tointeger(n) or ('%.1f'):format(n)
		end
		if type(n) == 'string' then
			return dostring(n, env)
		end
		if type(n) == 'function' then
			local suc, r = pcall(setfenv(n), hero)
			if not suc then return '' end
			return format(r, env)
		end
		return tostring(n)
	end
	dostring = function (str, env)
		return str:gsub('%' .. sep .. '(.-)%' .. sep, function(name)
			return format(assert(load('return (' ..name .. ')', '=(load)', 't', env))(), env)
		end)
	end
	return dostring(str, setmetatable({hero = hero}, {__index = keyval}))
end
function mt:searcher(name, callback)
	local searcher = marco[name .. 'Searcher']
	if searcher == '' then
		callback('')
		return
	end
	for _, path in ipairs(split(searcher, ';')) do
		local fullpath = path: gsub('%$(.-)%$', function(v) return marco[v] or '' end)
		callback(fullpath)
	end
end
function mt:packager(name, loadfile)
	local result = {}
	local function package(path, default)
		local content = loadfile(path.. name .. '.ini')
		if content then
			result, default = self:loader(content, result, default)
		end
		local config = loadfile(path .. '.iniconfig')
		if config then
			for _, dir in ipairs(split(config, '\n')) do
				package(path .. dir:gsub('^%s', ''):gsub('%s$', '') .. '\\', default)
			end
		end
	end
	self:searcher('Table', package)
	return result
end
function mt:set_marco(key, value)
	marco[key] = value
end
function mt:get_searcher(name)
	local result = nil
	self:searcher(name, function(path)
		if result then
			result = result .. ';' .. path
		else
			result = path
		end
	end)
	return result
end
return mt