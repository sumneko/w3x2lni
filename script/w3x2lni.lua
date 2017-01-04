require 'utility'
local uni = require 'ffi.unicode'
local w3xparser = require 'w3xparser'
local lni = require 'lni-c'
local slk = w3xparser.slk
local txt = w3xparser.txt
local ini = w3xparser.ini
local pairs = pairs
local string_lower = string.lower

local mt = {}

local metadatas = {}
local id_type
local usable_para
local editstring
local keyconvert = {}
local default

function mt:parse_lni(...)
	return lni(...)
end

function mt:parse_slk(buf)
	return slk(buf)
end

function mt:parse_txt(...)
	return txt(...)
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

function mt:read_metadata2(type)
	if not metadatas[type] then
		metadatas[type] = lni(io.load(self.meta / (type .. '.ini')), type)
	end
	return metadatas[type]
end

function mt:get_id_type(type)
	if not id_type then
		id_type = lni(io.load(self.prebuilt / 'id_type.ini'))
	end
    return id_type[string_lower(type)] or 3
end

function mt:is_usable_para(parent)
	if not usable_para then
		usable_para = lni(io.load(self.prebuilt / 'usable_para.ini'))
	end
	return usable_para[parent]
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

function mt:keyconvert(type)
	if not keyconvert[type] then
		keyconvert[type] = lni(io.load(self.key / (type .. '.ini')), type)
	end
	return keyconvert[type]
end

local function create_default(w2l)
	return {
		ability      = lni(io.load(w2l.default / 'ability.ini')),
		buff         = lni(io.load(w2l.default / 'buff.ini')),
		unit         = lni(io.load(w2l.default / 'unit.ini')),
		item         = lni(io.load(w2l.default / 'item.ini')),
		upgrade      = lni(io.load(w2l.default / 'upgrade.ini')),
		doodad       = lni(io.load(w2l.default / 'doodad.ini')),
		destructable = lni(io.load(w2l.default / 'destructable.ini')),
		txt          = lni(io.load(w2l.default / 'txt.ini')),
		misc         = lni(io.load(w2l.default / 'misc.ini')),
	}
end

function mt:get_default(create)
	if create then
		return create_default(self)
	end
	if not default then
		default = create_default(self)
	end
	return default
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
	self.meta = self.prebuilt / 'meta'
	self.info   = lni(assert(io.load(self.root / 'script' / 'info.ini')), 'info')
	self.config = lni(assert(io.load(self.root / 'config.ini')), 'config')
	local fmt = self.config.target_format
	self.config = self.config[fmt]
	self.config.target_format = fmt
end

-- 加载脚本
local convertors = {
	'frontend', 
	'frontend_wts',
	'frontend_slk', 
	'frontend_lni', 
	'frontend_obj',
	'frontend_misc',
	'frontend_updatelni',
	'frontend_processing',
	'backend',
	'backend_processing',
	'backend_mark',
	'backend_lni',
	'backend_slk',
	'backend_txt',
	'backend_obj',
	'backend_searchjass',
	'backend_convertjass',
	'backend_searchdoo',
	'backend_computed',
	'backend_extra_txt',
	'backend_misc',
	'backend_skin',
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
