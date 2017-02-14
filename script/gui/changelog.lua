local window
local canvas

local color  = {
    NEW = {0, 173, 60},
    CHG = {217, 163, 60},
    FIX = {200, 30, 30},
    UI = {111, 77, 150},
}

local current
local index

local function version_begin()
    canvas:layout_row_dynamic(2, 1)
    canvas:layout_space(25, 10)
    index = 0
end

local function version(ver, text)
    if not current then
        current = text
    end
    if current == text then
        window:set_style('button.color', 131, 135, 147)
        canvas:layout_space_push(index, 0, 80, 25)
        index = index + 80
    else
        window:set_style('button.color', 81, 85, 97)
        canvas:layout_space_push(index, 0, 40, 25)
        index = index + 40
    end
    if canvas:button(ver) then
        current = text
    end
end

local function version_end()
    canvas:layout_row_dynamic(342, 1)
    canvas:group('说明', function()
        if current then
            current()
        end
    end)
end

local function log(type, msg, tip)
    window:set_style('button.color', table.unpack(color[type]))
    canvas:layout_space(25, 2)
    canvas:layout_space_push( 0, 0,  40, 25) canvas:button(type)
    canvas:layout_space_push(50, 0, 320, 25) canvas:text(msg, NK_TEXT_LEFT, tip)
end

return function(window_, canvas_)
    window = window_
    canvas = canvas_
    version_begin()
    version('1.5.1', function()
        log('CHG', '简化显示更多的详情')
        log('FIX', '修正一个简化错误')
    end)
    version('1.5', function()
        log('NEW', '没有修改过的自定义技能会被移除', '和魔兽的行为保持一致')
        log('CHG', '转换为lni时不生成imp文件')
        log('CHG', '简化时科技需求不搜索它的引用')
        log('FIX', '修正随机物品会被简化掉的问题')
        log('FIX', '修正弹道速率为0优化后错误的问题', '弹道速度默认为1500(编辑器中错误的显示为0)')
        log('FIX', '修正imp中的文件分析不全的问题')
        log('FIX', '修正部分图标填空slk后崩溃的问题', '如影遁等技能')
        log('FIX', '修正触发器文本丢失的问题')
        log('FIX', '修正没有忽略无效对象的问题')
        log('FIX', '修正游戏界面文本可能丢失的问题', '换行后的文本会丢失')
        log('FIX', '修正部分报告后面多一个数字的问题')
    end)
    version('1.4', function()
        log('FIX', '修正创建地图失败的问题')
        log('FIX', '修正读取lni对象等级错误的问题')
        log('FIX', '修正w3i字符串可能留在wts里的问题')
        log('FIX', '修正地图创建界面玩家数错误的问题')
        log('FIX', '修正地图信息中队伍玩家错误的问题')
        log('FIX', '修正可能丢失自定义对象的问题', '仅仅从默认对象上复制出来，没有修改任何属性的自定义对象会在转换成obj/lni后丢失')
        log('FIX', '修正转换obj后部分数据不可见的问题', '在编辑器中技能的DataA等数据显示为默认值')
    end)
    version('1.3', function()
        log('NEW', '保留无法转换为obj/lni的slk数据', '有些slk数据无法转换成obj格式，会在转回slk时重新生成出来')
        log('NEW', 'slk后的文本不会出现DefaultString')
        log('NEW', '从wts读取的文本不会因"}"截断', '不要在长文本中使用"}"符号，否则魔兽和编辑器会将从该符号开始的字符丢弃')
        log('NEW', '往wts写入的文本会将"}"改为"|"', '不要在长文本中使用"}"符号，否则魔兽和编辑器会将从该符号开始的字符丢弃')
        log('CHG', '简化slk后的txt文件', '去掉重复的文本')
        log('CHG', '简化lni模板', 'template去掉超过等级的数据')
        log('FIX', '修正slk后无法研究科技的问题')
        log('FIX', '修正部分详情显示错误的问题')
        log('FIX', '修正平衡常数可能丢失的问题', '转换到obj或lni时，丢失平衡常数的修改')
        log('FIX', '修正部分空文本在slk后错误的问题')
        log('FIX', '修正无法放在txt的数据丢失的问题')
        log('FIX', '修正部分模型在slk后不显示的问题', '模型路径可以被转换为数字(路径开头是数字/负号/小数点+数字)')
        log('FIX', '修正部分平衡常数简化后失效的问题')
        log('FIX', '修正删除WE文件导致读取不全的问题', '(listfile)中不存在但导入列表中存在的文件没有搜索到')
    end)
    version('1.2', function()
        log('NEW', '对象不再无视大小写', '例如A00A与A00a，会被视为两个对象')
        log('NEW', '现在会搜索导入表里的文件')
        log('NEW', '优化详情的显示')
        log('CHG', '只有slk的数据会移除超过等级的部分')
        log('CHG', '变身技能的buff引用改为搜索', 'Amil、AHav')
        log('CHG', '必须保留列表移除一些对象', 'Barm')
        log('CHG', '空的slk文件会保留文件头', '包含标题等信息,而再是个空文件')
        log('CHG', '生成lni时会使用正确的数据类型')
        log('FIX', '修正部分技能的引用分析错误的问题', 'Acoi、Acoh')
        log('FIX', '修正lpeg模块加载失败的问题')
        log('FIX', '修正市场没有被搜索到的问题')
        log('FIX', '修正没有读取的SLK会被删除的问题')
        log('FIX', '修正转换为SLK时数据可能不对的问题', '例如技能的[100,200,300,400,400]改成[100,200,300,500,400]，上个版本会错误的转换为[100,200,300,500,500]')
        log('FIX', '修正平衡常数分析不正确的问题')
        log('FIX', '修正部分物编文本没有截断的问题', '例如buff的描述应该只显示到逗号前')
        log('FIX', '修正生成lni时有冗余数据的问题', '超过4级的技能应该不显示与底板完全相同的属性')
        log('FIX', '修正w3i和imp文件不正确的问题')
    end)
    version('1.1', function()
        log('NEW', '支持模型压缩', '有损压缩')
        log('NEW', '无法放在txt中的字符串会放在wts里', '尽量不要同时包含逗号和双引号')
        log('NEW', '增加部分选项的提示')
        log('NEW', '转换成OBJ时会补充必要文件', 'war3mapunits.doo')
        log('CHG', '重要的详情现在会更加显眼')
        log('CHG', '必须保留列表移除一些对象', 'Bbar、Bchd、Buad、Biwb')
        log('FIX', '修正某些格式互转地图不可用的问题')
        log('FIX', '修正无法读取南瓜头生成的txt的问题')
        log('FIX', '修正读取0级技能会出错的问题')
        log('FIX', '修正详情里的tip被截断的问题')
    end)
    version_end()
end
