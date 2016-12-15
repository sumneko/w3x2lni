require 'filesystem'
require 'sys'
require 'utility'
require 'gui.backend'
local lni = require 'lni-c'
local nk = require 'nuklear'
nk:console()

NK_WIDGET_STATE_MODIFIED = 1 << 1
NK_WIDGET_STATE_INACTIVE = 1 << 2
NK_WIDGET_STATE_ENTERED  = 1 << 3
NK_WIDGET_STATE_HOVER    = 1 << 4
NK_WIDGET_STATE_ACTIVED  = 1 << 5
NK_WIDGET_STATE_LEFT     = 1 << 6

NK_TEXT_ALIGN_LEFT     = 0x01
NK_TEXT_ALIGN_CENTERED = 0x02
NK_TEXT_ALIGN_RIGHT    = 0x04
NK_TEXT_ALIGN_TOP      = 0x08
NK_TEXT_ALIGN_MIDDLE   = 0x10
NK_TEXT_ALIGN_BOTTOM   = 0x20
NK_TEXT_LEFT           = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_LEFT
NK_TEXT_CENTERED       = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_CENTERED
NK_TEXT_RIGHT          = NK_TEXT_ALIGN_MIDDLE | NK_TEXT_ALIGN_RIGHT

local root = fs.get(fs.DIR_EXE):remove_filename()
local config = lni(io.load(root / 'config.ini'))

local config_content = [[
[root]
-- 是否分析slk文件
read_slk = $read_slk$
-- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
find_id_times = $find_id_times$
-- 移除与模板完全相同的数据
remove_same = $remove_same$
-- 补全空缺的数据
add_void = $add_void$
-- 移除超出等级的数据
remove_over_level = $remove_over_level$
-- 转换后的目标格式('lni', 'obj', 'slk')
target_format = $target_format$
-- 转换为地图还是目录('map', 'dir')
target_storage = $target_storage$
]]

local function save_config()
	local content = config_content:gsub('%$(.-)%$', function(str)
		local value = config
		for key in str:gmatch '[^%.]*' do
			value = value[key]
		end
		if type(value) == 'string' then
			return ('%q'):format(value)
		else
			return tostring(value)
		end
	end)
	io.save(root / 'config.ini', content)
end

local window = nk.window('W3x2Lni', 400, 600)
window:set_style(0, 173, 217)

local uitype = 'none'
local showmappath = false
local showcount = 0
local mapname = ''
local mappath = fs.path()

function window:dropfile(file)
	mappath = fs.path(file)
	mapname = mappath:filename():string()
	uitype = 'select'
	window:set_title('W3x2Lni')
end

local function button_mapname(canvas, height)
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(40, 1)
	local ok, state = canvas:button(mapname)
	if ok then 
		showmappath = not showmappath
	end
	if state & NK_WIDGET_STATE_LEFT ~= 0 then
		showcount = showcount + 1
	else
		showcount = 0
	end
	if showmappath or showcount > 20 then
		canvas:edit(mappath:string(), 200, function ()
			return false
		end)
		height = height - 44
	end
	return height
end

local function window_none(canvas)
	canvas:layout_row_dynamic(2, 1)
	canvas:layout_row_dynamic(200, 1)
	canvas:button('把地图拖进来')
	canvas:layout_row_dynamic(280, 1)
	canvas:layout_row_dynamic(20, 2)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('版本: 1.0.0', NK_TEXT_LEFT)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('前端: actboy168', NK_TEXT_LEFT)
	canvas:label('', NK_TEXT_RIGHT) canvas:label('后端: 最萌小汐', NK_TEXT_LEFT)
end

local function window_select(canvas)
	canvas:layout_row_dynamic(2, 1)
	canvas:layout_row_dynamic(100, 1)
	if canvas:button('转为Lni') then
		uitype = 'convert'
		window:set_title('W3x2Lni')
		config.target_format = 'lni'
		save_config()
		return
	end
	window:set_style(0, 173, 60)
	if canvas:button('转为Slk') then
		uitype = 'convert'
		window:set_title('W3x2Slk')
		config.target_format = 'slk'
		config.remove_same = false
		config.remove_over_level = true
		config.add_void = true
		save_config()
		return
	end
	window:set_style(217, 163, 60)
	if canvas:button('转为Obj') then
		uitype = 'convert'
		window:set_title('W3x2Obj')
		config.target_format = 'obj'
		config.remove_same = true
		config.add_void = false
		save_config()
		return
	end
	window:set_style(0, 173, 217)
end

local backend
local backend_lastmsg = ''
local backend_msgs = {}

local function update_backendmsg(pos)
	local msg = backend.output:sub(1, pos):gsub("^%s*(.-)%s*$", "%1"):gsub('[^\r\n]+[\r\n]*', function(str)
		if str:sub(1, 1) == '-' then
			local key, value = str:match('%-(%S+)%s(.+)')
			if key then
				backend_msgs[key] = value
				return ''
			end
		end
	end)
	if #msg > 0 then
		backend_lastmsg = msg
	end
	backend.output = backend.output:sub(pos+1)
	return true
end

local function update_backend()
	if not backend then
		return
	end
	if not backend.closed then
		backend.closed = backend:update()
	end
	if #backend.output > 0 then
		local pos = backend.output:find('\n')
		if pos then
			update_backendmsg(pos)
		end
	end
	if #backend.error > 0 then
		io.stdout:write(backend.error)
		io.stdout:flush()
		backend.error = ''
	end
	if backend.closed then
		while true do
			local pos = backend.output:find('\n')
			if not pos then
				break
			end
			update_backendmsg(pos)
		end
		update_backendmsg(-1)
		backend = nil
	end
end
	
local function window_mpq(canvas, height)
	height = height - 90
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(30, 1)
	if canvas:checkbox('分析slk文件', config.read_slk) then
		config.read_slk = not config.read_slk
		save_config()
	end
	if config.target_format == 'lni' then
		height = height - 34
		if canvas:checkbox('删除和模板一致的数据', config.remove_same) then
			config.remove_same = not config.remove_same
			save_config()
		end
	end
	if config.target_format == 'lni' or config.target_format == 'obj' then
		height = height - 34
		if canvas:checkbox('删除超过最大等级的数据', config.remove_over_level) then
			config.remove_over_level = not config.remove_over_level
			save_config()
		end
	end
	if config.target_format == 'lni' then
		height = height - 34
		if canvas:checkbox('补全多等级数据中的空位', config.add_void) then
			config.add_void = not config.add_void
			save_config()
		end
	end
	canvas:layout_row_dynamic(10, 1)
	canvas:tree('高级', 1, function()
		canvas:layout_row_dynamic(30, 1)
		if canvas:checkbox('限制搜索最优模板的次数', config.find_id_times ~= 0) then
			if config.find_id_times == 0 then
				config.find_id_times = 10
			else
				config.find_id_times = 0
			end
			save_config()
		end
		if config.find_id_times == 0 then
			canvas:edit('', 0, function ()
				return false
			end)
		else
			local r = canvas:edit(tostring(config.find_id_times), 10, function (c)
				return 48 <= c and c <= 57
			end)
			config.find_id_times = tonumber(r) or 1
			save_config()
		end
		height = height - 68
	end)
	return height
end

local function window_dir(canvas, height)
	return height
end

local dot = 0
function window:draw(canvas)
	update_backend()
	if uitype == 'none' then
		window_none(canvas)
		return
	end
	if uitype == 'select' then
		window_select(canvas)
		return
	end
	local height = button_mapname(canvas, 358)
	height = window_mpq(canvas, height)
	--height = window_dir(canvas, height)
	canvas:layout_row_dynamic(height, 1)
	canvas:layout_row_dynamic(30, 1)
	canvas:label(backend_lastmsg, NK_TEXT_LEFT)
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(30, 1)
	canvas:progress(math.floor(backend_msgs['progress'] or 0), 100)
	canvas:layout_row_dynamic(10, 1)
	canvas:layout_row_dynamic(50, 1)
	if backend then
		canvas:button('正在处理...')
	else
		if canvas:button('开始') then
			backend_msgs['progress'] = nil
			canvas:progress(0, 100)
			backend_lastmsg = '正在初始化...'
			backend = sys.async_popen(('%q -backend %q'):format(arg[0], mappath:string()))
		end
	end
end

window:run()
