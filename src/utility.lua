require 'ar_stormlib'
require 'sys'
require 'i18n'

local stormlib = ar.stormlib
local mpq_meta =  { __index = {} }

function mpq_meta.__index:import(path_in_archive, import_file_path)
	return stormlib.add_file_ex(
			self.handle,
			import_file_path,
			path_in_archive,
			stormlib.MPQ_FILE_COMPRESS | stormlib.MPQ_FILE_REPLACEEXISTING,
			stormlib.MPQ_COMPRESSION_ZLIB,
			stormlib.MPQ_COMPRESSION_ZLIB)
end

function mpq_meta.__index:extract(path_in_archive, extract_file_path)
	return stormlib.extract_file(self.handle, extract_file_path, path_in_archive)
end

function mpq_meta.__index:close()
	stormlib.close_archive(self.handle)
end

function mpq_meta.__index:remove(path_in_archive)
	return stormlib.remove_file(self.handle, path_in_archive, 0)
end

function mpq_meta.__index:rename(path_in_archive, new_name)
	return stormlib.rename_file(self.handle, path_in_archive, new_name)
end

function mpq_meta.__index:has(path_in_archive)
	return stormlib.has_file(self.handle, path_in_archive)
end

function mpq_open(path)
	local h = stormlib.open_archive(path, 0, 0)
	if not h then
		return nil
	end
	return setmetatable({handle = h}, mpq_meta)
end

function mpq_create(path, max_file_count)
	local h = stormlib.create_archive(path, 0, max_file_count or 1)
	if not h then
		return nil
	end
	return setmetatable({handle = h}, mpq_meta)
end

function io.load(file_path)
	local f, e = io.open(file_path, "rb")

	if f then
		local content	= f:read 'a'
		f:close()
		return content
	else
		return false, e
	end
end

function io.save(file_path, content)
	local f, e = io.open(file_path, "wb")

	if f then
		f:write(content)
		f:close()
		return true
	else
		return false, e
	end
end

local real_io_lines = io.lines

function io.lines(path)
	return real_io_lines(path:utf8_to_ansi())
end

function io.lines2(path)
    local f, e = io.open(path, "rb")
    if not f then
        return nil, e
    end
    local CHUNK_SIZE = 1024
    local buffer = ""
    local pos_beg = 1
    if f:read(3) ~= '\xEF\xBB\xBF' then
        f:seek('set')
    end
    return function()
        local pos, chars
        while 1 do
            pos, chars = buffer:match('()([\r\n].)', pos_beg)
            if pos or not f then
                break
            elseif f then
                local chunk = f:read(CHUNK_SIZE)
                if chunk then
                    buffer = buffer:sub(pos_beg) .. chunk
                    pos_beg = 1
                else
                    f:close()
                    f = nil
                end
            end
        end
        if not pos then
            pos = #buffer
        elseif chars == '\r\n' then
            pos = pos + 1
        end
        local line = buffer:sub(pos_beg, pos)
        pos_beg = pos + 1
        if #line > 0 then
            return line
        end
    end
end

function sys.spawn(command_line, current_dir, wait)
	local p = sys.process()
	if not p:create(nil, command_line, current_dir) then
		return false
	end

	if wait then
		local exit_code = p:wait()
		p:close()
		p = nil
		return exit_code == 0
	end
	
	p:close()
	p = nil	
	return false
end

local stdio_print = print

function print(...)
	local tbl = {}
	for _, v in ipairs(table.pack(...)) do
		table.insert(tbl, utf8_to_ansi(tostring(v)))
	end
	stdio_print(table.unpack(tbl))
end

function string.create_lines(tab)
	local lines = {}
	local tabs = ('\t'):rep(tab or 0)
	lines.tab = tab or 0
	
	local function push(self, mo)
		local line = tabs .. mo
		table.insert(self, line)
		return function(...)
			self[#self] = line:format(...)
		end
	end

	return setmetatable(lines, {__call = push})
end

function table.hash_to_array(t)
	--将key保存在数组中
	local nt = {}
	for key in pairs(t) do
		table.insert(nt, key)
	end

	for i = 1, #nt do
		t[i] = nt[i]
	end

	table.sort(t)

	--添加遍历的元方法
	local mt = getmetatable(t)
	if not mt then
		mt = {}
		setmetatable(t, mt)
	end

	local function __pairs(t, key)
		key = (key or 0) + 1
		if t[key] then
			return key, t[key], t[t[key]]
		end
	end

	function mt.__pairs(t)
		return __pairs, t, nil
	end

	return #t
end

function string.set_len(s, len)
	if #s > len then
		return s:sub(1, len)
	else
		return s .. ('\0'):rep(len - #s)
	end
end