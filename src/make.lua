local function main()
	
	--添加require搜寻路径
	package.path = package.path .. ';' .. arg[2] .. '\\src\\?.lua'
	package.cpath = package.cpath .. ';' .. arg[2] .. '\\build\\?.dll'
	require 'luabind'
	require 'filesystem'
	require 'utility'
	require 'w3x2txt'

	--保存路径
	root_dir	= fs.path(arg[2])
	input_dir	= root_dir / 'input'
	output_dir	= root_dir / 'output'
	meta_path	= root_dir / 'meta'
	txt_dir		= root_dir / 'txt'

	fs.create_directories(txt_dir)
	fs.create_directories(output_dir)

	--读取meta表
	w3x2txt.readMeta(meta_path / 'abilitybuffmetadata.slk')
	w3x2txt.readMeta(meta_path / 'abilitymetadata.slk')
	w3x2txt.readMeta(meta_path / 'destructablemetadata.slk')
	w3x2txt.readMeta(meta_path / 'doodadmetadata.slk')
	w3x2txt.readMeta(meta_path / 'miscmetadata.slk')
	w3x2txt.readMeta(meta_path / 'unitmetadata.slk')
	w3x2txt.readMeta(meta_path / 'upgradeeffectmetadata.slk')
	w3x2txt.readMeta(meta_path / 'upgrademetadata.slk')

	--读取函数
	w3x2txt.readTriggerData(meta_path / 'TriggerData.txt')

	--转换二进制文件到txt
	w3x2txt.obj2txt(input_dir / 'war3map.w3u', txt_dir / 'war3map.w3u.txt', false)
	w3x2txt.obj2txt(input_dir / 'war3map.w3t', txt_dir / 'war3map.w3t.txt', false)
	w3x2txt.obj2txt(input_dir / 'war3map.w3b', txt_dir / 'war3map.w3b.txt', false)
	w3x2txt.obj2txt(input_dir / 'war3map.w3d', txt_dir / 'war3map.w3d.txt', true)
	w3x2txt.obj2txt(input_dir / 'war3map.w3a', txt_dir / 'war3map.w3a.txt', true)
	w3x2txt.obj2txt(input_dir / 'war3map.w3h', txt_dir / 'war3map.w3h.txt', false)
	w3x2txt.obj2txt(input_dir / 'war3map.w3q', txt_dir / 'war3map.w3q.txt', true)

	w3x2txt.w3i2txt(input_dir / 'war3map.w3i', txt_dir / 'war3map.w3i.txt')
	w3x2txt.wtg2txt(input_dir / 'war3map.wtg', txt_dir / 'war3map.wtg.txt')
	w3x2txt.wct2txt(input_dir / 'war3map.wct', txt_dir / 'war3map.wct.txt')

	--转换txt到二进制文件
	w3x2txt.txt2obj(txt_dir / 'war3map.w3u.txt', output_dir / 'war3map.w3u', false)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3t.txt', output_dir / 'war3map.w3t', false)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3b.txt', output_dir / 'war3map.w3b', false)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3d.txt', output_dir / 'war3map.w3d', true)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3a.txt', output_dir / 'war3map.w3a', true)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3h.txt', output_dir / 'war3map.w3h', false)
	w3x2txt.txt2obj(txt_dir / 'war3map.w3q.txt', output_dir / 'war3map.w3q', true)

	w3x2txt.txt2w3i(txt_dir / 'war3map.w3i.txt', output_dir / 'war3map.w3i')
	w3x2txt.txt2wtg(txt_dir / 'war3map.wtg.txt', output_dir / 'war3map.wtg')
	w3x2txt.txt2wct(txt_dir / 'war3map.wct.txt', output_dir / 'war3map.wct')
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 

end

print(arg[2])
main()