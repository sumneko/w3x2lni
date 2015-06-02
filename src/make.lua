local function main()
	
	--添加require搜寻路径
	package.path = package.path .. ';' .. arg[1] .. '\\src\\?.lua'
	package.cpath = package.cpath .. ';' .. arg[1] .. '\\build\\?.dll'
	require 'luabind'
	require 'filesystem'
	require 'utility'
	require 'localization'
	local w3x2txt = require 'w3x2txt'
	local stormlib = require 'stormlib'
	
	--保存路径
	root_dir	= fs.path(ansi_to_utf8(arg[1]))
	input_dir	= root_dir / 'input'
	output_dir	= root_dir / 'output'
	meta_path	= root_dir / 'meta'
	user_meta_path	= meta_path / 'user'

	--读取meta表
	w3x2txt.read_metadata(meta_path / 'abilitybuffmetadata.slk')
	w3x2txt.read_metadata(meta_path / 'abilitymetadata.slk')
	w3x2txt.read_metadata(meta_path / 'destructablemetadata.slk')
	w3x2txt.read_metadata(meta_path / 'doodadmetadata.slk')
	w3x2txt.read_metadata(meta_path / 'miscmetadata.slk')
	w3x2txt.read_metadata(meta_path / 'unitmetadata.slk')
	w3x2txt.read_metadata(meta_path / 'upgradeeffectmetadata.slk')
	w3x2txt.read_metadata(meta_path / 'upgrademetadata.slk')

	--读取函数
	w3x2txt.read_triggerdata(meta_path / 'TriggerData.txt')
	w3x2txt.read_triggerdata(user_meta_path / 'TriggerData.txt')

	if arg[2] then

		--清空输入输出目录
		fs.remove_all(input_dir)
		fs.create_directories(input_dir)

		--拆解地图
		map_path	= fs.path(ansi_to_utf8(arg[2]))
		local map = stormlib(map_path)
		for name in pairs(map) do
			map:extract(name, input_dir / name)
		end
		map:close()

		--读取字符串
		w3x2txt.read_wts(input_dir / 'war3map.wts')
		
		--转换二进制文件到txt
		w3x2txt.obj2txt(input_dir / 'war3map.w3u', input_dir / 'war3map.w3u.txt', false)
		w3x2txt.obj2txt(input_dir / 'war3map.w3t', input_dir / 'war3map.w3t.txt', false)
		w3x2txt.obj2txt(input_dir / 'war3map.w3b', input_dir / 'war3map.w3b.txt', false)
		w3x2txt.obj2txt(input_dir / 'war3map.w3d', input_dir / 'war3map.w3d.txt', true)
		w3x2txt.obj2txt(input_dir / 'war3map.w3a', input_dir / 'war3map.w3a.txt', true)
		w3x2txt.obj2txt(input_dir / 'war3map.w3h', input_dir / 'war3map.w3h.txt', false)
		w3x2txt.obj2txt(input_dir / 'war3map.w3q', input_dir / 'war3map.w3q.txt', true)


		w3x2txt.w3i2txt(input_dir / 'war3map.w3i', input_dir / 'war3map.w3i.txt')
		--w3x2txt.wtg2txt(input_dir / 'war3map.wtg', input_dir / 'war3map.wtg.txt')
		--w3x2txt.wct2txt(input_dir / 'war3map.wct', input_dir / 'war3map.wct.txt')

		--将wts写入脚本
		w3x2txt.convert_j(input_dir / 'war3map.j', input_dir / 'war3map.j')
	else

		--清空输入输出目录
		fs.remove_all(output_dir)
		fs.create_directories(output_dir)
		
		--转换txt到二进制文件
		w3x2txt.txt2obj(input_dir / 'war3map.w3u.txt', output_dir / 'war3map.w3u', false)
		w3x2txt.txt2obj(input_dir / 'war3map.w3t.txt', output_dir / 'war3map.w3t', false)
		w3x2txt.txt2obj(input_dir / 'war3map.w3b.txt', output_dir / 'war3map.w3b', false)
		w3x2txt.txt2obj(input_dir / 'war3map.w3d.txt', output_dir / 'war3map.w3d', true)
		w3x2txt.txt2obj(input_dir / 'war3map.w3a.txt', output_dir / 'war3map.w3a', true)
		w3x2txt.txt2obj(input_dir / 'war3map.w3h.txt', output_dir / 'war3map.w3h', false)
		w3x2txt.txt2obj(input_dir / 'war3map.w3q.txt', output_dir / 'war3map.w3q', true)

		w3x2txt.txt2w3i(input_dir / 'war3map.w3i.txt', output_dir / 'war3map.w3i')
		--w3x2txt.txt2wtg(input_dir / 'war3map.wtg.txt', output_dir / 'war3map.wtg')
		--w3x2txt.txt2wct(input_dir / 'war3map.wct.txt', output_dir / 'war3map.wct')

	end

	--刷新字符串
	w3x2txt.fresh_wts(input_dir / 'war3map.wts')
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
