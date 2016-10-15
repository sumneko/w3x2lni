local select = select

local mt = {}
mt.__index = mt

function mt:set_index(...)
	self.index = select(-1, ...)
	return ...
end

function mt:unpack(str)
	return self:set_index(str:unpack(self.content, self.index))
end

function mt:is_finish()
	return ('I1'):unpack(self.content, self.index) == 0xFF
end

function mt:add_head(data)
    -- 地图数据
	data.file_ver,		--文件版本
	data.map_ver,		--地图版本(保存次数)
	data.editor_ver,	--编辑器版本
	data.map_name,		--地图名称
	data.author,		--作者名字
	data.des,			--地图描述
	data.player_rec	--推荐玩家
    = self:unpack 'lllzzzz'
    
	-- 镜头范围
	data.camera_bound_1,
	data.camera_bound_2,
	data.camera_bound_3,
	data.camera_bound_4,
	data.camera_bound_5,
	data.camera_bound_6,
	data.camera_bound_7,
	data.camera_bound_8
    = self:unpack 'ffffffff'
    
    -- 镜头范围扩充
	data.camera_complement_1,
	data.camera_complement_2,
	data.camera_complement_3,
	data.camera_complement_4
    = self:unpack 'llll'

    -- 地形属性
	data.map_width,	        --地图宽度
	data.map_height,	        --地图长度
	data.map_flag,		        --地图标记,后面解读
	data.map_main_ground_type	--地形类型
    = self:unpack 'lllc1'

    -- 载入图
	data.loading_screen_id,	    --ID(-1表示导入载入图)
	data.loading_screen_path,	    --路径
	data.loading_screen_text,	    --文本
	data.loading_screen_title,	    --标题
	data.loading_screen_subtitle	--子标题
    = self:unpack 'lzzzz'

    -- 使用的游戏数据设置
	data.game_data_set = self:unpack 'l'

    -- 战役序幕
	data.prologue_screen_path,		--路径
	data.prologue_screen_text,		--文本
	data.prologue_screen_title,	--标题
	data.prologue_screen_subtitle	--子标题
    = self:unpack 'zzzz'

    -- 迷雾
	data.terrain_fog,	--类型
	data.fog_start_z,	--开始z轴
	data.fog_end_z,	--结束z轴
	data.fog_density,	--密度
	data.fog_red,		--红色
	data.fog_green,	--绿色
	data.fog_blue,		--蓝色
	data.fog_alpha	    --透明
    = self:unpack 'lfffBBBB'
	
    -- 环境
	data.weather_id,           --天气
	data.sound_environment,	--音效
	data.light_environment	    --光照
    = self:unpack 'c4zc1'

    -- 水
	data.water_red,	--红色
	data.water_green,	--绿色
	data.water_blue,	--蓝色
	data.water_alpha	--透明
	= self:unpack 'BBBB'
end

function mt:add_player(data)
	data.player_count = self:unpack 'l'
	data.players = {}
	for i = 1, data.player_count do
		local player	= {}
		data.players[i] = player

		player.id,
		player.type,			--玩家类型(1玩家,2电脑,3野怪,4可营救)
		player.race,			--玩家种族
		player.start_position,	--修正出生点
		player.name,
		player.start_x,
		player.start_y,
		player.ally_low_flag,	--低结盟优先权标记
		player.ally_high_flag	--高结盟优先权标记
		= self:unpack 'llllzffLL'

		player.ally_low_flag = player.ally_low_flag & ((1 << data.player_count) - 1)
		player.ally_high_flag = player.ally_high_flag & ((1 << data.player_count) - 1)
	end
end

function mt:add_force(data)
	data.force_count = self:unpack 'l'
	data.forces = {}
	for i = 1, data.force_count do
		local force	= {}
		data.forces[i] = force

		force.force_flag,	--队伍标记
		force.player_flag,	--包含玩家
		force.name
		= self:unpack 'LLz'

		force.player_flag = force.player_flag & ((1 << data.player_count) - 1)
	end
end

function mt:add_upgrade(data)
	if self:is_finish() then
		return
	end
	data.upgrade_count = self:unpack 'l'
	data.upgrades	= {}
	for i = 1, data.upgrade_count do
		local upgrade	= {}
		table.insert(data.upgrades, upgrade)

		upgrade.player_flag,	--包含玩家
		upgrade.id,				--4位ID
		upgrade.level,			--等级
		upgrade.available		--可用性
		= self:unpack 'lc4ll'
	end
end

function mt:add_tech(data)
	if self:is_finish() then
		return
	end
	data.tech_count = self:unpack 'l'
	data.techs	= {}
	for i = 1, data.tech_count do
		local tech	= {}
		table.insert(data.techs, tech)

		tech.player_flag,	--包含玩家
		tech.id			--4位ID
		= self:unpack 'lc4'
	end
end

function mt:add_randomgroup(data)
	if self:is_finish() then
		return
	end
	data.group_count = self:unpack 'l'
	data.groups = {}
	for i = 1, data.group_count do
		local group	= {}
		table.insert(data.groups, group)

		group.id,
		group.name
		= self:unpack 'lz'

		--位置
		group.position_count = self:unpack 'l'

		group.positions	= {}
		for i = 1, group.position_count do
			group.positions[i] = self:unpack 'l'
		end

		--设置
		group.line_count = self:unpack 'l'
		
		group.lines	= {}
		for i = 1, group.line_count do
			local line	= {}
			table.insert(group.lines, line)

			line.chance = self:unpack 'l'

			--id列举
			line.ids	= {}
			for i = 1, group.position_count do
				line.ids[i] = self:unpack 'c4'
			end
		end
	end
end

function mt:add_randomitem(data)
	if self:is_finish() then
		return
	end
	data.random_item_count = self:unpack 'l'
	data.random_items = {}

	for i = 1, data.random_item_count do
		local random_item = {}
		table.insert(data.random_items, random_item)

		random_item.id,
		random_item.name
		= self:unpack 'lz'

		--设置
		random_item.set_count = self:unpack 'l'
		random_item.sets = {}
		for i = 1, random_item.set_count do
			local set = {}
			table.insert(random_item.sets, set)

			--物品
			set.item_count = self:unpack 'l'
			set.items = {}

			for i = 1, set.item_count do
				local item = {}
				table.insert(set.items, item)

				item.chance,
				item.id
				= self:unpack 'lc4'
			end
		end
	end
end

return function (self, content)
    if not content then
        return nil
    end
    local index = 1
    local tbl   = setmetatable({}, mt)
    local data  = {}

    tbl.content = content
    tbl.index   = index

    tbl:add_head(data)
	tbl:add_player(data)
	tbl:add_force(data)
	tbl:add_upgrade(data)
	tbl:add_tech(data)
	tbl:add_randomgroup(data)
	tbl:add_randomitem(data)
    
    return data
end
