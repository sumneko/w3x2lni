local ffi = require 'ffi'
ffi.cdef[[
	struct SFILE_CREATE_MPQ {
    	unsigned long cbSize;         // Size of this structure, in bytes
    	unsigned long dwMpqVersion;   // Version of the MPQ to be created
    	void*         pvUserData;     // Reserved, must be NULL
    	unsigned long cbUserData;     // Reserved, must be 0
    	unsigned long dwStreamFlags;  // Stream flags for creating the MPQ
    	unsigned long dwFileFlags1;   // File flags for (listfile). 0 = default
    	unsigned long dwFileFlags2;   // File flags for (attributes). 0 = default
    	unsigned long dwFileFlags3;   // File flags for (signature). 0 = default
    	unsigned long dwAttrFlags;    // Flags for the (attributes) file. If 0, no attributes will be created
    	unsigned long dwSectorSize;   // Sector size for compressed files
    	unsigned long dwRawChunkSize; // Size of raw data chunk
    	unsigned long dwMaxFileCount; // File limit for the MPQ
	};
	struct SFILE_FIND_DATA {
		char          cFileName[1024]; // Full name of the found file
		char*         szPlainName;     // Plain name of the found file
		unsigned long dwHashIndex;     // Hash table index for the file (HAH_ENTRY_FREE if no hash table)
		unsigned long dwBlockIndex;    // Block table index for the file
		unsigned long dwFileSize;      // File size in bytes
		unsigned long dwFileFlags;     // MPQ file flags
		unsigned long dwCompSize;      // Compressed file size
		unsigned long dwFileTimeLo;    // Low 32-bits of the file time (0 if not present)
		unsigned long dwFileTimeHi;    // High 32-bits of the file time (0 if not present)
		unsigned int  lcLocale;        // Locale version
	};

	bool SFileCreateArchive2(const wchar_t* szMpqName, struct SFILE_CREATE_MPQ* pCreateInfo, uint32_t* phMpq);
	bool SFileOpenArchive(const wchar_t* szMpqName, unsigned long dwPriority, unsigned long dwFlags, uint32_t* phMpq);
	bool SFileCloseArchive(uint32_t hMpq);
	bool SFileAddFileEx(uint32_t hMpq, const wchar_t* szFileName, const char* szArchivedName, unsigned long dwFlags, unsigned long dwCompression, unsigned long dwCompressionNext);
	bool SFileExtractFile(uint32_t hMpq, const char* szToExtract, const wchar_t* szExtracted, unsigned long dwSearchScope);
	bool SFileHasFile(uint32_t hMpq, const char* szFileName);

	uint32_t SListFileFindFirstFile(uint32_t hMpq, const char* szListFile, const char* szMask, struct SFILE_FIND_DATA* lpFindFileData);
	bool SListFileFindNextFile(uint32_t hFind, struct SFILE_FIND_DATA* lpFindFileData);
	bool SListFileFindClose(uint32_t hFind);
	
	unsigned long GetLastError();
	int MessageBoxA(void* hWnd, const char* lpText, const char* lpCaption, unsigned int uType);
]]

local uni = require 'unicode'
local stormlib = ffi.load('stormlib')

local mt = {}
mt.__index = mt

function mt:close()
	if self.handle == 0 then
		return
	end
	stormlib.SFileCloseArchive(self.handle)
	self.handle = 0
end

function mt:add_file(name, path)
	if self.handle == 0 then
		return false
	end
	local wpath = uni.u2w(path:string())
	return stormlib.SFileAddFileEx(self.handle, wpath, name,
			0x00000200 | 0x80000000, -- MPQ_FILE_COMPRESS | MPQ_FILE_REPLACEEXISTING,
			0x02, -- MPQ_COMPRESSION_ZLIB,
			0x02 --MPQ_COMPRESSION_ZLIB
			)
end

function mt:extract(name, path)
	if self.handle == 0 then
		return false
	end
	local wpath = uni.u2w(path:string())
	return stormlib.SFileExtractFile(self.handle, name, wpath,
			0 --SFILE_OPEN_FROM_MPQ
			)
end

function mt:has_file(name)
	if self.handle == 0 then
		return false
	end
	return stormlib.SFileHasFile(self.handle, name)
end

function mt:__pairs()
	local temp_path = fs.path('temp' .. os.time())
	if not self:extract('(listfile)', temp_path) then
		print('(listfile)导出失败', temp_path:string())
		return
	end
	local content = io.load(temp_path)
	fs.remove(temp_path)
	if content:sub(1, 3) == '\xEF\xBB\xBF' then
		content = content:sub(4)
	end
	return content:gmatch '[^\n\r]+'
end

local m = {}
function m.open(path)
	local wpath = uni.u2w(path:string())
	local phandle = ffi.new('uint32_t[1]', 0)
	if not stormlib.SFileOpenArchive(wpath, 0, 0, phandle) then
		return nil
	end
	return setmetatable({ handle = phandle[0] }, mt)
end
function m.create(path, filecount)
	local wpath = uni.u2w(path:string())
	local phandle = ffi.new('uint32_t[1]', 0)
	local info = ffi.new('struct SFILE_CREATE_MPQ')
	info.cbSize = ffi.sizeof('struct SFILE_CREATE_MPQ')
	info.dwMpqVersion   = 0 --MPQ_FORMAT_VERSION_1
	info.pvUserData     = nil
    info.cbUserData     = 0
	info.dwStreamFlags  = 0 --STREAM_PROVIDER_FLAT | BASE_PROVIDER_FILE
	info.dwFileFlags1   = 0x80000000 --MPQ_FILE_EXISTS
	info.dwFileFlags2   = 0x80000000 --MPQ_FILE_EXISTS
	info.dwFileFlags3   = 0x80000000 --MPQ_FILE_EXISTS
	info.dwAttrFlags    = 7 --MPQ_ATTRIBUTE_CRC32 | MPQ_ATTRIBUTE_FILETIME | MPQ_ATTRIBUTE_MD5
	info.dwSectorSize   = 0x10000
	info.dwRawChunkSize = 0
	info.dwMaxFileCount = filecount
	if not stormlib.SFileCreateArchive2(wpath, info, phandle) then
		return nil
	end
	return setmetatable({ handle = phandle[0] }, mt)
end
function m.messagebox(text, caption)
	ffi.C.MessageBoxA(nil, text, caption, 0)
end
return m
