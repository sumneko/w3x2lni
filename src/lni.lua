local mt = {}
local marco = {}
local function split(str, p) local rt = {} str:gsub('[^'..p..']+', function (w) table.insert(rt, w) end) return rt end
local function trim(str) return str:gsub('^%s*(.-)%s*$', '%1') end
local function dostring(file, ln, str, env) return assert(load(str, '=['..file..':'.. ln..']', 't', env))() end
local function table_copy(tbl) local res = {} if tbl then for k, v in pairs(tbl) do res[k] = v end end return res end
local function complie_computed(line, env)
	local f, l = line:find('=', 1, true)
	if not f then
		return
	end
	local k, v = line:sub(1, f-1), line:sub(l+1)
	v = v:gsub([[%'.-%']], function (s)
		return [[_u:get ]] .. s
	end):gsub('%[(.-)%]', function (s)
		local x, y
		local r = split(s, ',')
		if #r == 0 then
			return '[' .. s .. ']'
		elseif #r == 1 then
			x, y = s, s
		elseif #r < env.max_level or #r == 2 then
			x, y = r[1], r[#r]
		else
			return '({'..s..'})[_l*(max_level-1)+1]'
		end
		return '(('..x..') + (('..y..') - ('..x..')) * _l)'
	end)
	if env.max_level <= 1 then
		return trim(k), 'local _l,_u=...;_l=0;return('..v..')'
	end
	return trim(k), 'local _l,_u=...;_l=(_l-1)/(max_level-1);return('..v..')'
end
local function format(n, formater)
	if formater then
		return ('%' .. formater):format(n)
	elseif type(n) == 'number' then
		return math.tointeger(n) or ('%.1f'):format(n)
	end
	return n
end
local fmter = {}
function fmter:__tostring()
	if not self.hero then
		if self.fmt then
			return self(('{:%s}[+{:%s}]'):format(self.fmt, self.fmt))
		else
			return self '{}[+{}]'
		end
	end
	return format(self.func(self.level, self.hero), self.fmt)
end
function fmter:__call(formater)
	local count = 0
	local dummy = {}
	local key
	if not self.hero then
		self.hero = {}
		function self.hero:get(str)
			key = str
			return 0
		end
	end
	local value_total = self.func(self.level, self.hero)
	function dummy:get() return 0 end
	local value_base = self.func(self.level, dummy)
	function dummy:get() return 1 end
	local value_factor = self.func(self.level, dummy) - value_base
	return formater:gsub('%{(.-)%}', function(str)
		count = count + 1
		local fmt
		local pos = str:find ':'
		if pos then
			fmt = str:sub(pos+1)
			str = str:sub(1,pos-1)
		end
		local order = tonumber(str) or count
		if order == 1 then
			return format(value_base, fmt)
		elseif order == 2 then
			if key then
				return ('%s*%s'):format(key, format(value_factor, fmt))
			end
			return format(value_total - value_base, fmt)
		elseif order == 3 then
			return format(value_factor, fmt)
		else
			return ''
		end
	end)
end
local function format_computed(str, hero, level, env, fmt)
	local func = assert(load(str, '=(load)', 't', env))
	return setmetatable({
		func = func,
		level = level,
		hero = hero,
		fmt = fmt,
	}, fmter)
end
function mt:loader(code, file, ac, default, enum)
	if code:sub(1, 3) == '\xEF\xBB\xBF' then code = code:sub(4) end
	local env = nil
	local multi_table = nil
	local multi_string = nil
	file = file or '...'
	ac = ac or {}
	default = table_copy(default)
	enum = table_copy(enum)
	for ln, line in ipairs(split(code, '\n')) do
		line = trim(line)
		if multi_string then
			multi_string = multi_string .. '\n' .. line
			if line:sub(-2) == ']]' then
				dostring(file, ln, multi_string, env)
				multi_string = nil
			end
		elseif multi_table then
			multi_table = multi_table .. '\n' .. line
			if line:sub(-1) == '}' then
				dostring(file, ln, multi_table, env)
				multi_table = nil
			end
		else
			if line:sub(1,1) == '[' then
				local name = line:sub(3,-3)
				if name == 'default' then
					env = default
				elseif name == 'enum' then
					env = enum
				else
					local computed = {}
					local mt = {}
					function mt:__index(k)
						if k == 'computed' then
							return computed
						end
						return enum[k]
					end
					function mt:__newindex(k, v)
						if k == 'computed' then
							for _, l in ipairs(split(v, '\n')) do
								local k, v = complie_computed(trim(l), self)
								if k then
									computed[k] = v
								end
							end
							return
						end
						rawset(self, k, v)
					end
					env = setmetatable(table_copy(default), mt)
					ac[name] = env
				end
			elseif line:sub(1,2) == '--' then
			elseif line:sub(-2) == '[[' then
				multi_string = line
			elseif line:sub(-1) == '{' then
				multi_table = line
			elseif line:sub(1,1) == [[']] then
				dostring(file, ln, line:gsub([[^('.-')]], '_ENV[%1]'), env)
			elseif line:sub(1, 1) == [["]] then
				dostring(file, ln, line:gsub([[^(".-")]], '_ENV[%1]'), env)
			elseif line:find([[^%d]]) ~= nil then
				dostring(file, ln, line:gsub([[^(%d+)]], '_ENV[%1]'), env)
			else
				dostring(file, ln, line, env)
			end
		end
	end
	return ac, default, enum
end
function mt:normalize_then_unpack(abil)
	local spell = {}
	spell.computed = table_copy(abil.computed)
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
function mt:normalize(abil)
	-- todo
end
function mt:dostring(str, keyval, sep, hero, computed, level)
	if not hero or type(hero) ~= 'table' then
		hero = nil
	else
		function hero:get(name)
			return self[name]
		end
	end
	local fmt
	local env = setmetatable({}, {__index = function(_, key)
		if computed and computed[key] then
			return format_computed(computed[key], hero, level, keyval, fmt)
		end
		if keyval[key] then
			local value = keyval[key]
			if type(value) == 'string' then
				value = self:dostring(value, keyval, sep, hero, computed, level)
			end
			return value
		end
		return _G[key]
	end})
	return str:gsub('%' .. sep .. '(.-)%' .. sep, function(str)
		local pos = str:find ':[%.%d]*%a$'
		if pos then
			fmt = str:sub(pos+1)
			str = str:sub(1, pos-1)
		else
			fmt = nil
		end
		local value = assert(load('return (' .. str .. ')', '=(load)', 't', env))()
		if type(value) == 'table' then
			return tostring(value)
		else
			return format(value, fmt)
		end
	end)
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
		return load(string.dump(f), '=(load)', nil, env)
	end
	local function dostring(str, env)
		return str
	end
	local function format(n, env)
		if type(n) == 'number' then
			return math.tointeger(n) or ('%.1f'):format(n)
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
	local ok = {}
	local function package(path, default, enum)
		ok[path] = true
		local content = loadfile(path.. name .. '.ini')
		if content then
			result, default, enum = self:loader(content, path .. name .. '.ini', result, default, enum)
		end
		local config = loadfile(path .. '.iniconfig')
		if config then
			for _, dir in ipairs(split(config, '\n')) do
				local name = dir:gsub('^%s', ''):gsub('%s$', '')
				if name ~= '' then
					local name = path .. name .. '\\'
					if not ok[name] then
						package(name, default, enum)
					end
				end
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