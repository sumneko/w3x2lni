local ffi = require 'ffi'
ffi.cdef[[
	uint32_t LoadLibraryA(const char* lpFileName);
    typedef void (*ffi_anyfunc)();
	ffi_anyfunc GetProcAddress(uint32_t hModule, uint32_t ord);
    typedef bool (*__stdcall SBigNew)(uint32_t* phandle);
    typedef bool (*__stdcall SBigDel)(uint32_t handle);
    typedef bool (*__stdcall SBigFromBinary)(uint32_t handle, const char* buf, size_t len);
    typedef bool (*__stdcall SBigToBinary)(uint32_t handle, void* buf, size_t len, size_t* wlen);
    typedef bool (*__stdcall SBigPowMod)(uint32_t handle, uint32_t src, uint32_t pow, uint32_t mod);
]]

local storm = ffi.C.LoadLibraryA('storm.dll')
local SBigNew = ffi.cast('SBigNew', ffi.C.GetProcAddress(storm, 624))
local SBigDel = ffi.cast('SBigDel', ffi.C.GetProcAddress(storm, 606))
local SBigFromBinary = ffi.cast('SBigFromBinary', ffi.C.GetProcAddress(storm, 609))
local SBigToBinary = ffi.cast('SBigToBinary', ffi.C.GetProcAddress(storm, 638))
local SBigPowMod = ffi.cast('SBigPowMod', ffi.C.GetProcAddress(storm, 628))
	
local mt = {}
mt.__index = mt

function mt:__gc()
	SBigDel(self.handle)
end

function mt:__tostring()
	local len = 0x100
    while true do
	    local buf = ffi.new('char[?]', len+1)
	    local wlen = ffi.new('size_t[1]', 0)
	    SBigToBinary(self.handle, buf, len+11, wlen)
        if wlen[0] < len + 1 then
            return ffi.string(buf, wlen[0])
        end
        len = len * 2
    end
end

function mt:powmod(pow, mod)
    local phandle = ffi.new('uint32_t[1]', 0)
	SBigNew(phandle)
    local handle = phandle[0]
    local new = setmetatable({ handle = handle }, mt)
    SBigPowMod(new.handle, self.handle, pow.handle, mod.handle)
    return new
end

return function (bin)
	local phandle = ffi.new('uint32_t[1]', 0)
	SBigNew(phandle)
	local handle = phandle[0]
	SBigFromBinary(handle, bin, #bin)
	return setmetatable({ handle = handle }, mt)
end
