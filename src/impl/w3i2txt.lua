local function w3i2txt(self, file_name_in, file_name_out)
	local content	= io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end

	local chunk	= {}
	local index	= 1

	--文件头
	chunk.file_ver,		--文件版本
	chunk.map_ver,		--地图版本(保存次数)
	chunk.editor_ver,	--编辑器版本
	chunk.map_name,		--地图名称
	chunk.author,		--作者名字
	chunk.des,			--地图描述
	chunk.player_rec,	--推荐玩家
	--镜头范围
	chunk.camera_bound_1,
	chunk.camera_bound_2,
	chunk.camera_bound_3,
	chunk.camera_bound_4,
	chunk.camera_bound_5,
	chunk.camera_bound_6,
	chunk.camera_bound_7,
	chunk.camera_bound_8,
	--镜头范围扩充
	chunk.camera_complement_1,
	chunk.camera_complement_2,
	chunk.camera_complement_3,
	chunk.camera_complement_4,

	chunk.map_width,	--地图宽度
	chunk.map_height,	--地图长度
	
	chunk.map_flag,		--地图标记,后面解读

	chunk.map_main_ground_type,	--地形类型

	chunk.loading_screen_id,	--载入图ID(-1表示导入载入图)
	chunk.loading_screen_path,	--载入图路径
	chunk.loading_screen_text,	--载入界面文本
	chunk.loading_screen_title,	--载入界面标题
	chunk.loading_screen_subtitle,	--载入图子标题

	chunk.game_data_set,	--使用游戏数据设置

	chunk.prologue_screen_path,		--序幕路径
	chunk.prologue_screen_text,		--序幕文本
	chunk.prologue_screen_title,	--序幕标题
	chunk.prologue_screen_subtitle,	--序幕子标题

	chunk.terrain_fog,	--地形迷雾
	chunk.fog_start_z,	--迷雾开始z轴
	chunk.fog_end_z,	--迷雾结束z轴
	chunk.fog_density,	--迷雾密度
	chunk.fog_red,		--迷雾红色
	chunk.fog_green,	--迷雾绿色
	chunk.fog_blue,		--迷雾蓝色
	chunk.fog_alpha,	--迷雾透明
	
	chunk.weather_id,	--全局天气

	chunk.sound_environment,	--环境音效
	chunk.light_environment,	--环境光照

	chunk.water_red,	--水红色
	chunk.water_green,	--水绿色
	chunk.water_blue,	--水蓝色
	chunk.water_alpha,	--水透明

	index	= ('lllzzzzfffffffflllllllc1lzzzzlzzzzlfffBBBBc4zc1BBBB'):unpack(content, index)

	--玩家数据
	chunk.player_count, index	= ('l'):unpack(content, index)
	chunk.players	= {}
	for i = 1, chunk.player_count do
		local player	= {}
		table.insert(chunk.players, player)

		player.id,
		player.type,			--玩家类型(1玩家,2电脑,3野怪,4可营救)
		player.race,			--玩家种族
		player.start_position,	--修正出生点
		player.name,
		player.start_x,
		player.start_y,
		player.ally_low_flag,	--低结盟优先权标记
		player.ally_high_flag,	--高结盟优先权标记
		index	= ('llllzffll'):unpack(content, index)
	end

	--队伍数据
	chunk.force_count, index	= ('l'):unpack(content, index)
	chunk.forces	= {}
	for i = 1, chunk.force_count do
		local force	= {}
		table.insert(chunk.forces, force)

		force.force_flag,	--队伍标记
		force.player_flag,	--包含玩家
		force.name,
		index	= ('llz'):unpack(content, index)
	end

	--可用升级数据
	chunk.upgrade_count, index	= ('l'):unpack(content, index)
	chunk.upgrades	= {}
	for i = 1, chunk.upgrade_count do
		local upgrade	= {}
		table.insert(chunk.upgrades, upgrade)

		upgrade.player_flag,	--包含玩家
		upgrade.id,				--4位ID
		upgrade.level,			--等级
		upgrade.available,		--可用性
		index	= ('lc4ll'):unpack(content, index)
	end

	--可用科技数据
	chunk.tech_count, index	= ('l'):unpack(content, index)
	chunk.techs	= {}
	for i = 1, chunk.tech_count do
		local tech	= {}
		table.insert(chunk.techs, tech)

		tech.player_flag,	--包含玩家
		tech.id,			--4位ID
		index	= ('lc4'):unpack(content, index)
	end

	--随机组
	chunk.group_count, index	= ('l'):unpack(content, index)
	chunk.groups	= {}
	for i = 1, chunk.group_count do
		local group	= {}
		table.insert(chunk.groups, group)

		group.id,
		group.name,
		index	= ('lz'):unpack(content, index)

		--位置
		group.position_count,
		index	= ('l'):unpack(content, index)

		group.positions	= {}
		for i = 1, group.position_count do
			group.positions[i], index	= ('l'):unpack(content, index)
		end

		--设置
		group.line_count,
		index	= ('l'):unpack(content, index)
		
		group.lines	= {}
		for i = 1, group.line_count do
			local line	= {}
			table.insert(group.lines, line)

			line.chance,
			index	= ('l'):unpack(content, index)

			--id列举
			line.ids	= {}
			for i = 1, group.position_count do
				line.ids[i], index	= ('c4'):unpack(content, index)
			end
		end
		
	end

	--物品列表
	chunk.random_item_count, index	= ('l'):unpack(content, index)
	chunk.random_items	= {}

	for i = 1, chunk.random_item_count do
		local random_item	= {}
		table.insert(chunk.random_items, random_item)

		random_item.id,
		random_item.name,
		index	= ('lz'):unpack(content, index)

		--设置
		random_item.set_count, index	= ('l'):unpack(content, index)
		random_item.sets	= {}
		for i = 1, random_item.set_count do
			local set	= {}
			table.insert(random_item.sets, set)

			--物品
			set.item_count, index	= ('l'):unpack(content, index)
			set.items	= {}

			for i = 1, set.item_count do
				local item	= {}
				table.insert(set.items, item)

				item.chance,
				item.id,
				index	= ('lc4'):unpack(content, index)
			end
		end
	end

	--转换txt文件
	local function child_table(chunk, format, ver_name, count, tab)
		local lines = string.create_lines(tab or 2)
		if type(count) == 'table' then
			for i, v in ipairs(count) do
				lines ('[%d]=' .. format) (i, chunk[ver_name .. v])
			end
		else
			for i = 1, count do
				lines ('[%d]=' .. format) (i, chunk[ver_name .. i])
			end
		end

		return table.concat(lines, ',\r\n')
	end
	
	local lines = string.create_lines(1)

	--文件头
	lines '{\'VERSION\',%s}'	(chunk.file_ver)
	lines '{\'地图版本\',%d}'	(chunk.map_ver)
	lines '{\'编辑器版本\',%d}'	(chunk.editor_ver)
	lines '{\'地图名称\',%q}'	(chunk.map_name)
	lines '{\'作者名字\',%q}'	(chunk.author)
	lines '{\'地图描述\',%q}'	(chunk.des)
	lines '{\'推荐玩家\',%q}'	(chunk.player_rec)

	--镜头范围
	lines '{\'镜头范围\',{\r\n%s' (child_table(chunk, '%.4f', 'camera_bound_', 8))
	lines '}}'

	--镜头范围扩充
	lines '{\'镜头范围扩充\',{\r\n%s' (child_table(chunk, '%d', 'camera_complement_', 4))
	lines '}}'

	lines '{\'地图宽度\',%d}'	(chunk.map_width)
	lines '{\'地图长度\',%d}'	(chunk.map_height)
	
	lines '{\'关闭预览图\',%d}'		(chunk.map_flag >> 0 & 1)
	lines '{\'自定义结盟优先权\',%d}'	(chunk.map_flag >> 1 & 1)
	lines '{\'对战地图\',%d}'		(chunk.map_flag >> 2 & 1)
	lines '{\'大型地图\',%d}'		(chunk.map_flag >> 3 & 1)
	lines '{\'迷雾区域显示地形\',%d}'	(chunk.map_flag >> 4 & 1)
	lines '{\'自定义玩家分组\',%d}'	(chunk.map_flag >> 5 & 1)
	lines '{\'自定义队伍\',%d}'		(chunk.map_flag >> 6 & 1)
	lines '{\'自定义科技树\',%d}'	(chunk.map_flag >> 7 & 1)
	lines '{\'自定义技能\',%d}'		(chunk.map_flag >> 8 & 1)
	lines '{\'自定义升级\',%d}'		(chunk.map_flag >> 9 & 1)
	lines '{\'地图菜单标记\',%d}'	(chunk.map_flag >> 10 & 1)
	lines '{\'地形悬崖显示水波\',%d}'	(chunk.map_flag >> 11 & 1)
	lines '{\'地形起伏显示水波\',%d}'	(chunk.map_flag >> 12 & 1)
	lines '{\'未知1\',%d}'			(chunk.map_flag >> 13 & 1)
	lines '{\'未知2\',%d}'			(chunk.map_flag >> 14 & 1)
	lines '{\'未知3\',%d}'			(chunk.map_flag >> 15 & 1)
	lines '{\'未知4\',%d}'			(chunk.map_flag >> 16 & 1)
	lines '{\'未知5\',%d}'			(chunk.map_flag >> 17 & 1)
	lines '{\'未知6\',%d}'			(chunk.map_flag >> 18 & 1)
	lines '{\'未知7\',%d}'			(chunk.map_flag >> 19 & 1)
	lines '{\'未知8\',%d}'			(chunk.map_flag >> 20 & 1)
	lines '{\'未知9\',%d}'			(chunk.map_flag >> 21 & 1)

	lines '{\'地形类型\',%q}'		(chunk.map_main_ground_type)
	
	lines '{\'载入图序号\',%d}'		(chunk.loading_screen_id)
	lines '{\'自定义载入图\',%q}'	(chunk.loading_screen_path)
	lines '{\'载入界面文本\',%q}'	(chunk.loading_screen_text)
	lines '{\'载入界面标题\',%q}'	(chunk.loading_screen_title)
	lines '{\'载入界面子标题\',%q}'	(chunk.loading_screen_subtitle)

	lines '{\'使用游戏数据设置\',%d}'	(chunk.game_data_set)

	lines '{\'自定义序幕图\',%q}'	(chunk.prologue_screen_path)
	lines '{\'序幕界面文本\',%q}'	(chunk.prologue_screen_text)
	lines '{\'序幕界面标题\',%q}'	(chunk.prologue_screen_title)
	lines '{\'序幕界面子标题\',%q}'	(chunk.prologue_screen_subtitle)

	lines '{\'地形迷雾\',%d}'		(chunk.terrain_fog)
	lines '{\'迷雾z轴起点\',%.4f}'	(chunk.fog_start_z)
	lines '{\'迷雾z轴终点\',%.4f}'	(chunk.fog_end_z)
	lines '{\'迷雾密度\',%.4f}'		(chunk.fog_density)

	--迷雾颜色
	lines '{\'迷雾颜色\',{\r\n%s' (child_table(chunk, '%d', 'fog_', {'red', 'green', 'blue', 'alpha'}))
	lines '}}'

	lines '{\'全局天气\',%q}'	(chunk.weather_id)
	lines '{\'环境音效\',%q}'	(chunk.sound_environment)
	lines '{\'环境光照\',%q}'	(chunk.light_environment)

	--水面颜色
	lines '{\'水面颜色\',{\r\n%s' (child_table(chunk, '%d', 'water_', {'red', 'green', 'blue', 'alpha'}))
	lines '}}'

	--玩家
	lines '{\'玩家数量\',%d}'	(chunk.player_count)
	for _, player in ipairs(chunk.players) do
		local function f()
			local lines = string.create_lines(2)
			
			lines '{\'玩家\',%d}'			(player.id)
			lines '{\'类型\',%d}'			(player.type)
			lines '{\'种族\',%d}'			(player.race)
			lines '{\'修正出生点\',%d}'		(player.start_position)
			lines '{\'名字\',%q}'			(player.name)
			--出生点
			lines '{\'出生点\',{\r\n%s' (child_table(player, '%.4f', 'start_', {'x', 'y'}, 3))
			lines '}}'
			lines '{\'低结盟优先权标记\',%d}'	(player.ally_low_flag)
			lines '{\'高结盟优先权标记\',%d}'	(player.ally_high_flag)

			return table.concat(lines, ',\r\n')
		end

		lines '{\'玩家%d\',{\r\n%s' (player.id, f())
		lines '}}'
	end

	--队伍
	lines '{\'队伍数量\',%d}'	(chunk.force_count)
	for _, force in ipairs(chunk.forces) do
		lines '{\'结盟\',%d}'			(force.force_flag >> 0 & 1)
		lines '{\'结盟胜利\',%d}'		(force.force_flag >> 1 & 1)
		lines '{\'共享视野\',%d}'		(force.force_flag >> 2 & 1)
		lines '{\'共享单位控制\',%d}'	(force.force_flag >> 3 & 1)
		lines '{\'共享高级单位设置\',%d}'	(force.force_flag >> 4 & 1)

		lines '{\'玩家列表\',%d}'		(force.player_flag)
		lines '{\'队伍名称\',%q}'		(force.name)
	end

	--升级
	lines '{\'升级数量\',%d}'	(chunk.upgrade_count)
	for _, upgrades in ipairs(chunk.upgrades) do
		lines '{\'玩家列表\',%d}'	(upgrade.player_flag)
		lines '{\'ID\',%s}'		(upgrade.id)
		lines '{\'等级\',%d}'		(upgrade.level)
		lines '{\'可用性\',%d}'		(upgrade.available)
	end

	--科技
	lines '{\'科技数量\',%d}'	(chunk.tech_count)
	for _, tech in ipairs(chunk.techs) do
		lines '{\'玩家列表\',%d}'	(tech.player_flag)
		lines '{\'ID\',%s}'		(tech.id)
	end

	--随机组
	lines '{\'随机组数量\',%d}'	(chunk.group_count)
	for _, group in ipairs(chunk.groups) do
		lines '{\'随机组\',%d}'		(group.id)
		lines '{\'随机组名称\',%s}'	(group.name)

		lines '{\'位置数量\',%d}'	(group.position_count)
		for _, type in ipairs(group.positions) do
			lines '{\'位置类型\',%d}'	(type)
		end

		lines '{\'设置数\',%d}'		(group.line_count)
		for _, line in ipairs(group.lines) do
			lines '{\'几率\',%d}'	(line.chance)
			for _, id in ipairs(line.ids) do
				lines '{\'ID\',%s}'	(id)
			end
		end
	end

	--物品列表
	lines '{\'物品列表数量\',%d}'	(chunk.random_item_count)
	for _, random_item in ipairs(chunk.random_items) do
		lines '{\'物品列表\',%d}'		(random_item.id)
		lines '{\'物品列表名称\',%s}'	(random_item.name)

		lines '{\'物品设置数量\',%d}'	(random_item.set_count)
		for _, set in ipairs(random_item.sets) do

			lines '{\'物品数量\',%d}'	(set.item_count)
			for _, item in ipairs(set.items) do
				lines '{\'几率\',%d}'	(item.chance)
				lines '{\'ID\',%s}'	(item.id)
			end
		end
	end

	local out_put = [[
return
{
%s
}
]]

	io.save(file_name_out, out_put:format(table.concat(lines, ',\r\n'):convert_wts()))

end

return w3i2txt
