local uni = require 'unicode'
local sleep = require 'sleep'

local table_unpack = table.unpack
local table_insert = table.insert
local table_sort   = table.sort
local pairs = pairs
local setmetatable = setmetatable

local real_io_open = io.open

function io.open(path, ...)
	return real_io_open(uni.u2a(path:string()), ...)
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
	return real_io_lines(uni.u2a(path))
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

local stdio_print = print

function print(...)
	local tbl = {...}
	local count = select('#', ...)
	for i = 1, count do
		tbl[i] = uni.u2a(tostring(tbl[i]))
	end
	stdio_print(table_unpack(tbl))
end

function task(f, ...)
	for i = 1, 100 do
		if i == 100 then
			f(...)
			return
		end
		if pcall(f, ...) then
			return
		end
		sleep(10)
	end
end

local function remove_then_create_dir(dir)
	if fs.exists(dir) then
		task(fs.remove_all, dir)
	end
	task(fs.create_directories, dir)
end
