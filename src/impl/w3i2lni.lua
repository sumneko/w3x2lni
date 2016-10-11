local table_concat = table.concat

local mt = {}
mt.__index = mt

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
end

function mt:add_head(chunk)
    self:add('["地图"]')
    self:add('\'文件版本\' = %s', chunk.file_ver)
	self:add('\'地图版本\' = %d', chunk.map_ver)
	self:add('\'编辑器版本\' = %d', chunk.editor_ver)
	self:add('\'地图名称\' = %q', chunk.map_name)
	self:add('\'作者名字\' = %q', chunk.author)
	self:add('\'地图描述\' = %q', chunk.des)
	self:add('\'推荐玩家\' = %q', chunk.player_rec)

    self:add ''
    self:add('["镜头"]')
	self:add('\'镜头范围\' = {')
    for i = 1, 8 do
        self:add('[%d] = %.4f', i, chunk['camera_bound_' .. i])
    end
	self:add '}'
	self:add('\'镜头范围扩充\' = {%d, %d, %d, %d}', chunk.camera_complement_1, chunk.camera_complement_2, chunk.camera_complement_3, chunk.camera_complement_4)

    self:add ''
    self:add('["地形"]')
	self:add('\'地图宽度\' = %d', chunk.map_width)
	self:add('\'地图长度\' = %d', chunk.map_height)
    self:add('\'地形类型\' = %q', chunk.map_main_ground_type)
	
    self:add ''
    self:add('["选项"]')
    self:add('\'使用的游戏数据设置\' = %d', chunk.game_data_set)
	self:add('\'关闭预览图\' = %d', chunk.map_flag >> 0 & 1)
	self:add('\'自定义结盟优先权\' = %d', chunk.map_flag >> 1 & 1)
	self:add('\'对战地图\' = %d', chunk.map_flag >> 2 & 1)
	self:add('\'大型地图\' = %d', chunk.map_flag >> 3 & 1)
	self:add('\'迷雾区域显示地形\' = %d', chunk.map_flag >> 4 & 1)
	self:add('\'自定义玩家分组\' = %d', chunk.map_flag >> 5 & 1)
	self:add('\'自定义队伍\' = %d', chunk.map_flag >> 6 & 1)
	self:add('\'自定义科技树\' = %d', chunk.map_flag >> 7 & 1)
	self:add('\'自定义技能\' = %d', chunk.map_flag >> 8 & 1)
	self:add('\'自定义升级\' = %d', chunk.map_flag >> 9 & 1)
	self:add('\'地图菜单标记\' = %d', chunk.map_flag >> 10 & 1)
	self:add('\'地形悬崖显示水波\' = %d', chunk.map_flag >> 11 & 1)
	self:add('\'地形起伏显示水波\' = %d', chunk.map_flag >> 12 & 1)
	self:add('\'未知1\' = %d', chunk.map_flag >> 13 & 1)
	self:add('\'未知2\' = %d', chunk.map_flag >> 14 & 1)
	self:add('\'未知3\' = %d', chunk.map_flag >> 15 & 1)
	self:add('\'未知4\' = %d', chunk.map_flag >> 16 & 1)
	self:add('\'未知5\' = %d', chunk.map_flag >> 17 & 1)
	self:add('\'未知6\' = %d', chunk.map_flag >> 18 & 1)
	self:add('\'未知7\' = %d', chunk.map_flag >> 19 & 1)
	self:add('\'未知8\' = %d', chunk.map_flag >> 20 & 1)
	self:add('\'未知9\' = %d', chunk.map_flag >> 21 & 1)
	
	self:add ''
    self:add('["载入图"]')
	self:add('\'序号\' = %d', chunk.loading_screen_id)
	self:add('\'路径\' = %q', chunk.loading_screen_path)
	self:add('\'文本\' = %q', chunk.loading_screen_text)
	self:add('\'标题\' = %q', chunk.loading_screen_title)
	self:add('\'子标题\' = %q', chunk.loading_screen_subtitle)

	self:add ''
    self:add('["战役"]')
	self:add('\'路径\' = %q', chunk.prologue_screen_path)
	self:add('\'文本\' = %q', chunk.prologue_screen_text)
	self:add('\'标题\' = %q', chunk.prologue_screen_title)
	self:add('\'子标题\' = %q', chunk.prologue_screen_subtitle)

    self:add ''
    self:add('["迷雾"]')
	self:add('\'类型\' = %d', chunk.terrain_fog)
	self:add('\'z轴起点\' = %.4f', chunk.fog_start_z)
	self:add('\'z轴终点\' = %.4f', chunk.fog_end_z)
	self:add('\'密度\' = %.4f', chunk.fog_density)
	self:add('\'颜色\' = {%d, %d, %d, %d}', chunk.fog_red, chunk.fog_green, chunk.fog_blue, chunk.fog_alpha)

    self:add ''
    self:add('["环境"]')
	self:add('\'天气\' = %q', chunk.weather_id)
	self:add('\'音效\' = %q', chunk.sound_environment)
	self:add('\'光照\' = %q', chunk.light_environment)

	--水面颜色
	self:add('\'水面颜色\' = {%d, %d, %d, %d}', chunk.water_red, chunk.water_green, chunk.water_blue, chunk.water_alpha)

    return chunk
end

return function (self, data)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self

    tbl:add_head(data)

	return table_concat(tbl.lines, '\n')
end
