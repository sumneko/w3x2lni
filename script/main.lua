
require 'filesystem'
local nk = require 'nuklear'
nk:console()

local NK_WIDGET_STATE_MODIFIED = 1 << 1
local NK_WIDGET_STATE_INACTIVE = 1 << 2
local NK_WIDGET_STATE_ENTERED = 1 << 3
local NK_WIDGET_STATE_HOVER = 1 << 4
local NK_WIDGET_STATE_ACTIVED = 1 << 5
local NK_WIDGET_STATE_LEFT = 1 << 6

local NK_TEXT_ALIGN_LEFT     = 0x01
local NK_TEXT_ALIGN_CENTERED = 0x02
local NK_TEXT_ALIGN_RIGHT    = 0x04
local NK_TEXT_ALIGN_TOP      = 0x08
local NK_TEXT_ALIGN_MIDDLE   = 0x10
local NK_TEXT_ALIGN_BOTTOM   = 0x20
local NK_TEXT_LEFT           = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_LEFT
local NK_TEXT_CENTERED       = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_CENTERED
local NK_TEXT_RIGHT          = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_RIGHT
    
local window = nk.window('W3x2Lni', 400, 600)

local filetype = 'none'
local showmappath = false
local showcount = 0
local mapname = ''
local mappath = fs.path()

function window:dropfile(file)
	mappath = fs.path(file)
	mapname = mappath:filename():string()
	if fs.is_directory(mappath) then
		filetype = 'dir'
	else
		filetype = 'mpq'
	end
end

local function button_mapname(canvas)
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(40, 1)
	local ok, state = canvas:button(mapname)
	if ok then 
		showmappath = not showmappath
	end
	if state & NK_WIDGET_STATE_LEFT ~= 0 then
		count = count + 1
	else
		count = 0
	end
	if showmappath or count > 20 then
		canvas:edit(mappath:string(), 200, function ()
			return false
		end)
		return 44
	end
	return 0
end

local function window_none(canvas)
	canvas:layout_row_dynamic(200, 1)
	canvas:button('把地图拖进来')
	canvas:layout_row_dynamic(280, 1)
	canvas:layout_row_dynamic(20, 2)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('版本: 1.0.0', NK_TEXT_LEFT)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('前端: actboy168', NK_TEXT_LEFT)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('后端: 最萌小汐', NK_TEXT_LEFT)
end

local config = {
	unpack = {
		-- 解包地图时是否分析slk文件
		read_slk = false,
		-- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
		find_id_times = 0,
		-- 解包时移除与模板完全相同的数据
		remove_same = true,
		-- 解包时移除超出等级的数据
		remove_over_level = true,
	}
}

local function window_mpq(canvas, height)
	height = 200 - height
	local unpack = config.unpack
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(30, 1)
	if canvas:checkbox('分析slk文件', unpack.read_slk) then
		unpack.read_slk = not unpack.read_slk
	end
	if canvas:checkbox('删除和模板一致的数据', unpack.remove_same) then
		unpack.remove_same = not unpack.remove_same
	end
	if canvas:checkbox('删除超过最大等级的数据', unpack.remove_over_level) then
		unpack.remove_over_level = not unpack.remove_over_level
	end
	canvas:layout_row_dynamic(10, 1)
	canvas:tree('高级', 1, function()
		canvas:layout_row_dynamic(30, 1)
		if canvas:checkbox('限制搜索最优模板的次数', unpack.find_id_times ~= 0) then
			if unpack.find_id_times == 0 then
				unpack.find_id_times = 1
			else
				unpack.find_id_times = 0
			end
		end
		if unpack.find_id_times == 0 then
			canvas:edit('', 0, function ()
				return false
			end)
		else
			local r = canvas:edit(tostring(unpack.find_id_times), 10, function (c)
				return 48 <= c and c <= 57
			end)
			unpack.find_id_times = tonumber(r)
		end
		height = height - 68
	end)
	canvas:layout_row_dynamic(height, 1)
	canvas:layout_row_dynamic(30, 1)
	canvas:label('正在读取文件...', NK_TEXT_LEFT)
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(30, 1)
	canvas:progress(0, 100)
	canvas:layout_row_dynamic(10, 1)
end

local function window_dir(canvas)
end

function window:draw(canvas)
	if filetype == 'none' then
		window_none(canvas)
		return
	end
	local height = button_mapname(canvas)
	if filetype == 'mpq' then
		window_mpq(canvas, height)
	else
		window_dir(canvas)
	end
	canvas:layout_row_dynamic(50, 1)
	if canvas:button('开始') then
	end
end

window:run()
