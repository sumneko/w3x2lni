require 'ar_stormlib'

local mt =  {}
mt.__index = {}

function mt:__pairs()
	local ff = ar.stormlib.findfile()
	ff:start(self.handle)
	return function ()
		if not ff:next() then
			ff:close()
			return nil
		end
		return ff:current()
	end
end

function mt.__index:import(path_in_archive, import_file_path)
	return ar.stormlib.add_file_ex(
			self.handle,
			import_file_path,
			path_in_archive,
			ar.stormlib.MPQ_FILE_COMPRESS | ar.stormlib.MPQ_FILE_REPLACEEXISTING,
			ar.stormlib.MPQ_COMPRESSION_ZLIB,
			ar.stormlib.MPQ_COMPRESSION_ZLIB)
end

function mt.__index:extract(path_in_archive, extract_file_path)
	local dir = extract_file_path:parent_path()
	if not fs.exists(dir) then
		fs.create_directories(dir)
	end
	return ar.stormlib.extract_file(self.handle, extract_file_path, path_in_archive)
end

function mt.__index:close()
	ar.stormlib.close_archive(self.handle)
end

return function (path)
	local obj = {}
	obj.handle = ar.stormlib.open_archive(path, 0, 0)
	if not obj.handle then
		return nil
	end
	return setmetatable(obj, mt)
end
