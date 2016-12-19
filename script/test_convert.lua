(function()
	local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
	package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
w2l:initialize()

local function fixstring(str)
    local r = {}
	str:gsub('[^,]*', function (w)
		if tonumber(w) then
			r[#r+1] = tostring(tonumber(w))
		else
			if w:sub(-1) == '"' then w = w:sub(1,-2) end
			r[#r+1] = w
		end
	end)
	return table.concat(r, ',')
end

local function sortpairs(t)
	local sort = {}
	for k, v in pairs(t) do
		sort[#sort+1] = {k, v}
	end
	table.sort(sort, function (a, b)
		return a[1]:lower() < b[1]:lower()
	end)
	local n = 1
	return function()
		local v = sort[n]
		if not v then
			return
		end
		n = n + 1
		return v[1], v[2]
	end
end

local function convert_txt(inf, outf)
	local t = w2l:parse_ini(assert(io.load(inf)))
	local str = {}
	for id, o in sortpairs(t) do
		str[#str+1] = ('[%s]'):format(id)
		for k, v in sortpairs(o) do
			if k ~= 'EditorSuffix' and k ~= 'EditorName' then
				if k == 'Buttonpos' or k == 'Researchbuttonpos' then
					if v:sub(-1) == ',' then
						v = v:sub(1, -2)
					end
				end
				str[#str+1] = ('%s=%s'):format(k, fixstring(v))
			end
		end
		str[#str+1] = ''
	end
	io.save(outf, table.concat(str, '\r\n'))
end

local txtmap = {
	['units\\campaignunitstrings.txt'] = 'units\\humanunitfunc.txt',
	['units\\campaignabilitystrings.txt'] = 'units\\humanabilityfunc.txt',
	['units\\campaignupgradestrings.txt'] = 'units\\humanupgradefunc.txt',
	['units\\itemstrings.txt'] = 'units\\itemfunc.txt',
	['units\\commonabilitystrings.txt'] = 'units\\neutralabilityfunc.txt',
}

local input = fs.path(uni.a2u(arg[1]))

--fs.remove_all(input / 'units2')
fs.create_directories(input / 'units2')
w2l.info.template.txt.buff = nil
for type, filelist in pairs(w2l.info.template.txt) do
	for _, filename in ipairs(filelist) do
		if txtmap[filename] then
			convert_txt(input / txtmap[filename], input / 'units2' / fs.path(filename):filename())
		else
			io.save(input / 'units2' / fs.path(filename):filename(), '')
		end
	end
end

local function merge(o, name)
	name = name:lower()
	if not o.levels then
		o[name] = {}
		return
	end
	for i = 1, o.levels do
		if o[name..i] then
			if not o[name] then
				o[name] = {}
			end
			o[name][i] = o[name..i]
			o[name..i] = nil
		end
	end
end

w2l.info.template.slk.doodad = nil
for type, filelist in pairs(w2l.info.template.slk) do
	for _, filename in ipairs(filelist) do
		local inf = input / filename
		local outf = input / 'units2' / fs.path(filename):filename()
		local t = w2l:parse_slk(assert(io.load(inf)))
		if type == 'buff' then
			if t.XEsn then
				t.Xesn = t.XEsn
				t.XEsn = nil
			end
		end
    	local keydata = w2l:keyconvert(type)
		for id, o in pairs(t) do
			o._id = id
			o._lower_para = id:lower()
			if type == 'ability' then
				if not keydata[o._lower_para] then
					o._lower_para = o._code:lower()
				end
				merge(o, 'Area')
				merge(o, 'BuffID')
				merge(o, 'Cast')
				merge(o, 'Cool')
				merge(o, 'Cost')
				merge(o, 'DataA')
				merge(o, 'DataB')
				merge(o, 'DataC')
				merge(o, 'DataD')
				merge(o, 'DataE')
				merge(o, 'DataF')
				merge(o, 'DataG')
				merge(o, 'DataH')
				merge(o, 'DataI')
				merge(o, 'Dur')
				merge(o, 'EfctID')
				merge(o, 'HeroDur')
				merge(o, 'Rng')
				merge(o, 'UnitID')
				merge(o, 'targs')
			elseif type == 'unit' then
				o._name = o.name
			end
		end
		io.save(outf, w2l:backend_slk(type, filename, t))
	end
end
