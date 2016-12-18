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

w2l.info.template.slk.doodad = nil
for type, filelist in pairs(w2l.info.template.slk) do
	for _, filename in ipairs(filelist) do
		local inf = input / filename
		local outf = input / 'units2' / fs.path(filename):filename()
		local t = w2l:parse_slk(assert(io.load(inf)))
		for id, o in pairs(t) do
			o._id = id
			if o.code then
				o._lower_code = o.code:lower()
				o._code = o.code
			elseif not o._lower_code then
				o._lower_code = id:lower()
				o._code = o._id
			end
		end
		io.save(outf, w2l:backend_slk(type, filename, t))
	end
end
