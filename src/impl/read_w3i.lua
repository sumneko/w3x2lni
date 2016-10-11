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

function mt:add_head(chunk)
    -- 地图数据
	chunk.file_ver,		--文件版本
	chunk.map_ver,		--地图版本(保存次数)
	chunk.editor_ver,	--编辑器版本
	chunk.map_name,		--地图名称
	chunk.author,		--作者名字
	chunk.des,			--地图描述
	chunk.player_rec	--推荐玩家
    = self:unpack 'lllzzzz'
    
	-- 镜头范围
	chunk.camera_bound_1,
	chunk.camera_bound_2,
	chunk.camera_bound_3,
	chunk.camera_bound_4,
	chunk.camera_bound_5,
	chunk.camera_bound_6,
	chunk.camera_bound_7,
	chunk.camera_bound_8
    = self:unpack 'ffffffff'
    
    -- 镜头范围扩充
	chunk.camera_complement_1,
	chunk.camera_complement_2,
	chunk.camera_complement_3,
	chunk.camera_complement_4
    = self:unpack 'llll'

    -- 地形属性
	chunk.map_width,	        --地图宽度
	chunk.map_height,	        --地图长度
	chunk.map_flag,		        --地图标记,后面解读
	chunk.map_main_ground_type	--地形类型
    = self:unpack 'lllc1'

    -- 载入图
	chunk.loading_screen_id,	    --ID(-1表示导入载入图)
	chunk.loading_screen_path,	    --路径
	chunk.loading_screen_text,	    --文本
	chunk.loading_screen_title,	    --标题
	chunk.loading_screen_subtitle	--子标题
    = self:unpack 'lzzzz'

    -- 使用的游戏数据设置
	chunk.game_data_set = self:unpack 'l'

    -- 战役序幕
	chunk.prologue_screen_path,		--路径
	chunk.prologue_screen_text,		--文本
	chunk.prologue_screen_title,	--标题
	chunk.prologue_screen_subtitle	--子标题
    = self:unpack 'zzzz'

    -- 迷雾
	chunk.terrain_fog,	--类型
	chunk.fog_start_z,	--开始z轴
	chunk.fog_end_z,	--结束z轴
	chunk.fog_density,	--密度
	chunk.fog_red,		--红色
	chunk.fog_green,	--绿色
	chunk.fog_blue,		--蓝色
	chunk.fog_alpha	    --透明
    = self:unpack 'lfffBBBB'
	
    -- 环境
	chunk.weather_id,           --天气
	chunk.sound_environment,	--音效
	chunk.light_environment	    --光照
    = self:unpack 'c4zc1'

    -- 水
	chunk.water_red,	--红色
	chunk.water_green,	--绿色
	chunk.water_blue,	--蓝色
	chunk.water_alpha	--透明
	= self:unpack 'BBBB'
end

return function (self, content)
    local index = 1
    local tbl   = setmetatable({}, mt)
    local data  = {}

    tbl.content = content
    tbl.index   = index

    tbl:add_head(data)
    
    return data
end
