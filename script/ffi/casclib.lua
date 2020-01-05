local ffi = require 'ffi'
local loaddll = require 'ffi.loaddll'

ffi.cdef[[
    bool CascOpenStorage(const wchar_t* szParams, unsigned long dwLocaleMask, uint32_t* phStorage);
    bool CascCloseStorage(uint32_t* hStorage);
    bool CascOpenFile(uint32_t hStorage, const char* szFileName, unsigned long dwLocaleFlags, unsigned long dwOpenFlags, uint32_t* PtrFileHandle);
    long CascGetFileSize(uint32_t hFile, long* pdwFileSizeHigh);
    bool CascReadFile(uint32_t hFile, void* lpBuffer, unsigned long dwToRead, unsigned long* pdwRead);
    bool CascCloseFile(uint32_t hFile);
]]

loaddll 'casclib'
local fs = require 'bee.filesystem'
local uni = require 'ffi.unicode'
local casclib = ffi.load('casclib')

local rfile = {}
rfile.__index = rfile

function rfile:size()
    if self.handle == 0 then
        return 0
    end
    local size_hi = ffi.new('long[1]', 0)
    local size_lo = casclib.CascGetFileSize(self.handle, size_hi)
    return size_lo | (size_hi[0] << 32)
end

function rfile:read(n)
    if self.handle == 0 then
        return
    end
    if not n then
        n = self:size()
    end
    if n < 0 then
        return nil
    end
    local buf = ffi.new('char[?]', n)
    local pread = ffi.new('unsigned long[1]', 0)
    if not casclib.CascReadFile(self.handle, buf, n, pread) then
        return nil
    end
    return ffi.string(buf, pread[0])
end

function rfile:close()
    if self.handle == 0 then
        return
    end
    casclib.CascCloseFile(self.handle)
    self.handle = 0
end

rfile.__close = rfile.close

local archive = {}
archive.__index = archive

function archive:close()
    if self.handle == 0 then
        return
    end
    casclib.CascCloseFile(self.handle)
    self.handle = 0
end

function archive:extract(name, path)
    if self.handle == 0 then
        return false
    end
    local file <close> = self:open_file(name)
    if not file then
        return false
    end
    local dir = path:parent_path()
    if not fs.exists(dir) then
        fs.create_directories(dir)
    end
    local content = file:read()
    if not content then
        return false
    end
    local f <close> = io.open(path:string(), 'wb')
    if not f then
        return false
    end
    f:write(content)
    return true
end

function archive:open_file(name)
    if self.handle == 0 then
        return nil
    end
    local phandle = ffi.new('uint32_t[1]', 0)
    if not casclib.CascOpenFile(self.handle, name, 0, 0, phandle) then
        return nil
    end
    return setmetatable({ handle = phandle[0] }, rfile)
end

function archive:has_file(name)
    local file <close> = self:open_file(name)
    return file ~= nil and file:size() >= 0
end

function archive:load_file(name)
    if self.handle == 0 then
        return nil
    end
    local file = self:open_file(name)
    if not file then
        return nil
    end
    local content = file:read()
    file:close()
    return content
end

archive.__close = archive.close

local m = {}
function m.open(path)
    local wpath = uni.u2w(path)
    local phStorage = ffi.new('uint32_t[1]', 0)
    if not casclib.CascOpenStorage(wpath, 0, phStorage) then
        return nil
    end
    return setmetatable({ handle = phStorage[0] }, archive)
end

return m
