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

local function main()
	local mode = arg[2]
	
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
		w3x2txt:obj2lni('war3map.w3u', 'war3map.w3u', 'unitmetadata.slk', false)
		w3x2txt:obj2lni('war3map.w3t', 'war3map.w3t', 'unitmetadata.slk', false)
		w3x2txt:obj2lni('war3map.w3b', 'war3map.w3b', 'destructablemetadata.slk', false)
		w3x2txt:obj2lni('war3map.w3d', 'war3map.w3d', 'doodadmetadata.slk', true)
		w3x2txt:obj2lni('war3map.w3a', 'war3map.w3a', 'abilitymetadata.slk', true)
		w3x2txt:obj2lni('war3map.w3h', 'war3map.w3h', 'abilitybuffmetadata.slk', false)
		w3x2txt:obj2lni('war3map.w3q', 'war3map.w3q', 'upgrademetadata.slk', true)

		--刷新字符串
		w3x2txt:fresh_wts('war3map.wts')
	end

	if mode == "lni2w3x" then
		-- 初始化lni解析器
		lni:set_marco('TableSearcher', '')

		--转换lni到二进制文件
		w3x2txt:lni2obj('war3map.w3u', 'war3map2.w3u', 'unitmetadata.slk', false)
		w3x2txt:lni2obj('war3map.w3t', 'war3map2.w3t', 'unitmetadata.slk', false)
		w3x2txt:lni2obj('war3map.w3b', 'war3map2.w3b', 'destructablemetadata.slk', false)
		w3x2txt:lni2obj('war3map.w3d', 'war3map2.w3d', 'doodadmetadata.slk', true)
		w3x2txt:lni2obj('war3map.w3a', 'war3map2.w3a', 'abilitymetadata.slk', true)
		w3x2txt:lni2obj('war3map.w3h', 'war3map2.w3h', 'abilitybuffmetadata.slk', false)
		w3x2txt:lni2obj('war3map.w3q', 'war3map2.w3q', 'upgrademetadata.slk', true)
	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
