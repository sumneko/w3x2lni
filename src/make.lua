package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
require 'localization'

local w3x2txt  = require 'w3x2txt'
local stormlib = require 'stormlib'
local lni      = require 'lni'

local root_dir = fs.path(arg[1])
local lni_dir  = root_dir / 'lni'
local w3x_dir  = root_dir / 'w3x'
local meta_dir = root_dir / 'meta'

local function read_config()
	lni:set_marco('TableSearcher', root_dir:string() .. '/')
	local config = lni:packager('config', function(filename)
		return io.load(fs.path(filename))
	end)

	for file_name, meta_name in pairs(config['metadata']) do
		w3x2txt:set_metadata(file_name, meta_name)
	end
end

local function main()
	local mode = arg[2]
	
	read_config()
	
	-- 创建目录
	fs.create_directory(lni_dir)
	fs.create_directory(w3x_dir)

	w3x2txt:set_dir('w3x', w3x_dir)
	w3x2txt:set_dir('lni', lni_dir)
	w3x2txt:set_dir('meta', meta_dir)

	if mode == "w3x2lni" then
		--读取字符串
		w3x2txt:read_wts('war3map.wts')

		--读取编辑器文本
		w3x2txt:read_editstring('WorldEditStrings.txt')
		
		--转换二进制文件到lni
		w3x2txt:obj2lni 'war3map.w3u'
		w3x2txt:obj2lni 'war3map.w3t'
		w3x2txt:obj2lni 'war3map.w3b'
		w3x2txt:obj2lni 'war3map.w3d'
		w3x2txt:obj2lni 'war3map.w3a'
		w3x2txt:obj2lni 'war3map.w3h'
		w3x2txt:obj2lni 'war3map.w3q'

		--刷新字符串
		w3x2txt:fresh_wts('war3map.wts')
	end

	if mode == "lni2w3x" then
		-- 初始化lni解析器
		lni:set_marco('TableSearcher', lni_dir:string() .. '/')

		--转换lni到二进制文件
		w3x2txt:lni2obj 'war3map.w3u'
		w3x2txt:lni2obj 'war3map.w3t'
		w3x2txt:lni2obj 'war3map.w3b'
		w3x2txt:lni2obj 'war3map.w3d'
		w3x2txt:lni2obj 'war3map.w3a'
		w3x2txt:lni2obj 'war3map.w3h'
		w3x2txt:lni2obj 'war3map.w3q'
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
