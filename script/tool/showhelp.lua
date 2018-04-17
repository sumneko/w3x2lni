local messager = require 'tool.messager'

if arg[2] == 'mpq' then
messager.raw [[
用法: w2l mpq <War3路径>

例如：
   w2l mpq "C:\Warcraft III"
]]
    return
end

if arg[2] == 'lni' then
messager.raw [[
用法: w2l lni <地图路径> [-config=<配置文件路径>]

    地图可以是一个w3x文件也可以是一个文件夹。

例如：
    w2l lni "E:\Warcraft III\Maps\Test.w3x"
    w2l lni Test.w3x
]]
    return
end

messager.raw [[
用法: w2l <命令> <路径>

可用命令：
    help   获取帮助信息
    mpq    提取《魔兽争霸III》的数据文件
    lni    将地图转换为`Lni`格式
    obj    将地图转换为`Obj`格式
    slk    将地图转换为`Slk`格式

使用`w2l help <命令>`，获取具体命令的帮助信息。
]]
