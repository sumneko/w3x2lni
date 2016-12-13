require 'utility'
local uni = require 'ffi.unicode'
local w3xparser = require 'w3xparser'
local lni = require 'lni-c'
local slk = w3xparser.slk
local txt = w3xparser.txt
local ini = w3xparser.ini
local pairs = pairs

local mt = {}

local metadatas = {}
local id_type
local usable_code
local editstring

function mt:parse_lni(...)
	return lni(...)
end

function mt:parse_slk(buf)
	return slk(buf)
end

function mt:parse_txt(buf)
	return txt(buf)
end

function mt:parse_ini(buf)
	return ini(buf)
end

function mt:read_metadata(type)
	local filepath = self.mpq / self.info['metadata'][type]
	if metadatas[filepath:string()] then
		return metadatas[filepath:string()]
	end
	local tbl = slk(io.load(filepath))
	metadatas[filepath:string()] = tbl

	local has_index = {}
	for k, v in pairs(tbl) do
		-- 进行部分预处理
		local name  = v['field']
		local index = v['index']
		if index and index >= 1 then
			has_index[name] = true
		end
	end
	for k, v in pairs(tbl) do
		local name = v['field']
		if has_index[name] then
			v._has_index = true
		end
	end
	return tbl
end

function mt:get_id_type(id, meta)
    local type = meta[id]['type']
	if not id_type then
		id_type = lni(io.load(self.prebuilt / 'id_type.ini'))
	end
    local format = id_type[type] or 3
    return format
end

function mt:is_usable_code(code)
	if not usable_code then
		usable_code = lni(io.load(self.prebuilt / 'usable_code.ini'))
	end
	return usable_code[code]
end

function mt:editstring(str)
	-- TODO: WESTRING不区分大小写，不过我们把WorldEditStrings.txt改了，暂时不会出现问题
	if not editstring then
		editstring = ini(io.load(self.mpq / 'ui' / 'WorldEditStrings.txt'))['WorldEditStrings']
	end
	if not editstring[str] then
		return str
	end
	repeat
		str = editstring[str]
	until not editstring[str]
	return str:gsub('%c+', '')
end

function mt:initialize(root)
	if self.initialized then
		return
	end
	self.initialized = true
	self.root = root or fs.path(uni.a2u(arg[0])):remove_filename()
	self.template = self.root / 'template'
	self.mpq = self.root / 'script' / 'mpq'
	self.prebuilt = self.root / 'script' / 'prebuilt'
	self.key = self.prebuilt / 'key'
	self.default = self.prebuilt / 'default'
	self.config = lni(io.load(self.root / 'config.ini'), 'config')
    self.info   = lni(io.load(self.root / 'script' / 'info.ini'), 'info')
end

-- 加载脚本
local convertors = {
	'frontend', 'backend',
	'frontend_wts',
	'frontend_slk', 
	'frontend_obj',
	'frontend_misc',
	'backend_processing',
	'backend_lni', 
	'backend_obj',
}

for _, name in ipairs(convertors) do
	mt[name] = require('slk.' .. name)
end

local convertors = {
	'lni2w3i', 'read_w3i', 'w3i2lni',
	'create_unitsdoo',
}

for _, name in ipairs(convertors) do
	mt[name] = require('other.' .. name)
end

return mt
