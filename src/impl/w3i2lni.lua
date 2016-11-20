local table_concat = table.concat
local table_insert = table.insert

local function unpack_flag(flag)
    local tbl = {}
    for i = 0, 64 do
        local n = 1 << i
        if n > flag then
            break
        end
        if flag & n ~= 0 then
            table_insert(tbl, i+1)
        end
    end
    return tbl
end

local mt = {}
mt.__index = mt

function mt:add(format, ...)
    self.lines[#self.lines+1] = format:format(...)
end

function mt:format_string(value)
    if value:match '[\n\r]' then
        return ('[=[\r\n%s]=]'):format(value)
    else
        return ('%q'):format(value)
    end
end

function mt:add_head(data)
    self:add('[地图]')
    self:add('文件版本 = %s', data.file_ver)
    self:add('地图版本 = %d', data.map_ver)
    self:add('编辑器版本 = %d', data.editor_ver)
    self:add('地图名称 = %s', self:format_string(data.map_name))
    self:add('作者名字 = %s', self:format_string(data.author))
    self:add('地图描述 = %s', self:format_string(data.des))
    self:add('推荐玩家 = %s', self:format_string(data.player_rec))

    self:add ''
    self:add('[镜头]')
    self:add('镜头范围 = {')
    for i = 1, 8 do
        self:add('%d = %.4f,', i, data['camera_bound_' .. i])
    end
    self:add '}'
    self:add('镜头范围扩充 = {%d, %d, %d, %d}', data.camera_complement_1, data.camera_complement_2, data.camera_complement_3, data.camera_complement_4)

    self:add ''
    self:add('[地形]')
    self:add('地图宽度 = %d', data.map_width)
    self:add('地图长度 = %d', data.map_height)
    self:add('地形类型 = %q', data.map_main_ground_type)
    
    self:add ''
    self:add('[选项]')
    self:add('使用的游戏数据设置 = %d', data.game_data_set)
    self:add('关闭预览图 = %d', data.map_flag >> 0 & 1)
    self:add('自定义结盟优先权 = %d', data.map_flag >> 1 & 1)
    self:add('对战地图 = %d', data.map_flag >> 2 & 1)
    self:add('大型地图 = %d', data.map_flag >> 3 & 1)
    self:add('迷雾区域显示地形 = %d', data.map_flag >> 4 & 1)
    self:add('自定义玩家分组 = %d', data.map_flag >> 5 & 1)
    self:add('自定义队伍 = %d', data.map_flag >> 6 & 1)
    self:add('自定义科技树 = %d', data.map_flag >> 7 & 1)
    self:add('自定义技能 = %d', data.map_flag >> 8 & 1)
    self:add('自定义升级 = %d', data.map_flag >> 9 & 1)
    self:add('地图菜单标记 = %d', data.map_flag >> 10 & 1)
    self:add('地形悬崖显示水波 = %d', data.map_flag >> 11 & 1)
    self:add('地形起伏显示水波 = %d', data.map_flag >> 12 & 1)
    self:add('未知1 = %d', data.map_flag >> 13 & 1)
    self:add('未知2 = %d', data.map_flag >> 14 & 1)
    self:add('未知3 = %d', data.map_flag >> 15 & 1)
    self:add('未知4 = %d', data.map_flag >> 16 & 1)
    self:add('未知5 = %d', data.map_flag >> 17 & 1)
    self:add('未知6 = %d', data.map_flag >> 18 & 1)
    self:add('未知7 = %d', data.map_flag >> 19 & 1)
    self:add('未知8 = %d', data.map_flag >> 20 & 1)
    self:add('未知9 = %d', data.map_flag >> 21 & 1)
    
    self:add ''
    self:add('[载入图]')
    self:add('序号 = %d', data.loading_screen_id)
    self:add('路径 = %s', self:format_string(data.loading_screen_path))
    self:add('文本 = %s', self:format_string(data.loading_screen_text))
    self:add('标题 = %s', self:format_string(data.loading_screen_title))
    self:add('子标题 = %s', self:format_string(data.loading_screen_subtitle))

    self:add ''
    self:add('[战役]')
    self:add('路径 = %s', self:format_string(data.prologue_screen_path))
    self:add('文本 = %s', self:format_string(data.prologue_screen_text))
    self:add('标题 = %s', self:format_string(data.prologue_screen_title))
    self:add('子标题 = %s', self:format_string(data.prologue_screen_subtitle))

    self:add ''
    self:add('[迷雾]')
    self:add('类型 = %d', data.terrain_fog)
    self:add('z轴起点 = %.4f', data.fog_start_z)
    self:add('z轴终点 = %.4f', data.fog_end_z)
    self:add('密度 = %.4f', data.fog_density)
    self:add('颜色 = {%d, %d, %d, %d}', data.fog_red, data.fog_green, data.fog_blue, data.fog_alpha)

    self:add ''
    self:add('[环境]')
    self:add('天气 = %s', self:format_string(data.weather_id))
    self:add('音效 = %s', self:format_string(data.sound_environment))
    self:add('光照 = %s', self:format_string(data.light_environment))

    --水面颜色
    self:add('水面颜色 = {%d, %d, %d, %d}', data.water_red, data.water_green, data.water_blue, data.water_alpha)

    return data
end

function mt:add_player(data)
    self:add ''
    self:add('[玩家]')
    self:add('玩家数量 = %d', data.player_count)

    for i, player in ipairs(data.players) do
        self:add ''
        self:add('[玩家%d]', i)
        self:add('玩家 = %d', player.id)
        self:add('类型 = %d', player.type)
        self:add('种族 = %d', player.race)
        self:add('修正出生点 = %d', player.start_position)
        self:add('名字 = %s', self:format_string(player.name))
        --出生点
        self:add('出生点 = {%.4f, %.4f}', player.start_x, player.start_y)
        self:add('低结盟优先权标记 = {%s}', table_concat(unpack_flag(player.ally_low_flag), ', '))
        self:add('高结盟优先权标记 = {%s}', table_concat(unpack_flag(player.ally_high_flag), ', '))
    end
end

function mt:add_force(data)
    self:add ''
    self:add('[队伍]')
    self:add('队伍数量 = %d', data.force_count)

    for i, force in ipairs(data.forces) do
        self:add ''
        self:add('[队伍%d]', i)
		self:add('结盟 = %d', force.force_flag >> 0 & 1)
		self:add('结盟胜利 = %d', force.force_flag >> 1 & 1)
		self:add('共享视野 = %d', force.force_flag >> 2 & 1)
		self:add('共享单位控制 = %d', force.force_flag >> 3 & 1)
		self:add('共享高级单位设置 = %d', force.force_flag >> 4 & 1)

		self:add('玩家列表 = {%s}', table_concat(unpack_flag(force.player_flag), ', '))
		self:add('队伍名称 = %s', self:format_string(force.name))
	end
end

function mt:add_upgrade(data)
    if not data.upgrades then
        return
    end
    for i, upgrade in ipairs(data.upgrades) do
        self:add ''
        self:add('[升级%d]', i)
        self:add('玩家列表 = {%s}', table_concat(unpack_flag(upgrade.player_flag), ', '))
		self:add('ID = %q', upgrade.id)
		self:add('等级 = %d', upgrade.level)
		self:add('可用性 = %d', upgrade.available)
    end
end

function mt:add_tech(data)
    if not data.techs then
        return
    end
    for i, tech in ipairs(data.techs) do
        self:add ''
        self:add('[科技%d]', i)
		self:add('玩家列表 = {%s}', table_concat(unpack_flag(tech.player_flag), ', '))
		self:add('ID = %q', tech.id)
	end
end

function mt:add_randomgroup(data)
    if not data.groups then
        return
    end
    for i, group in ipairs(data.groups) do
        self:add ''
        self:add('[随机组%d]', i)
		self:add('随机组名称 = %s', self:format_string(group.name))
        self:add('位置类型 = {%s}', table_concat(group.positions, ', '))
        
        self:add('设置 = {')
		for i, line in ipairs(group.lines) do
		    self:add('%d = {', i)
			self:add('几率 = %d,', line.chance)
            local ids = {}
            for i = 1, #line.ids do
                ids[i] = ('%q'):format(line.ids[i])
            end
            self:add('ID = {%s},', table_concat(ids, ', '))
            self:add('},')
		end
        self:add('}')
	end
end

function mt:add_randomitem(data)
    if not data.random_items then
        return
    end
    for i, random_item in ipairs(data.random_items) do
        self:add ''
        self:add('[物品列表%d]', i)
		self:add('物品列表名称 = %s', self:format_string(random_item.name))

        self:add('设置 = {')
		for i, set in ipairs(random_item.sets) do
            self:add('%d = {', i)
			for _, item in ipairs(set.items) do
				self:add('{几率 = %d, ID = %q},', item.chance, item.id)
			end
            self:add('},')
		end
        self:add('}')
	end
end

return function (self, data)
    local tbl = setmetatable({}, mt)
    tbl.lines = {}
    tbl.self = self

    tbl:add_head(data)
    tbl:add_player(data)
    tbl:add_force(data)
    tbl:add_upgrade(data)
    tbl:add_tech(data)
    tbl:add_randomgroup(data)
    tbl:add_randomitem(data)

    return table_concat(tbl.lines, '\r\n')
end
