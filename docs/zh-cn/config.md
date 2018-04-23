# 配置文件

> global.lang

使用的语言，默认是`*auto`，表示会根据你的操作系统语言自动选择。目前支持简体中文`zh-CN`与美式英语`en-US`。此外所有以`zh-`开头的语言会使用`zh-CN`，所有以`en-`开头的语言会使用`en-US`。如果无法匹配，则使用`en-US`。

> global.war3

使用魔兽数据文件的目录。在中文版中默认是`zhCN-1.24.4`，在英文版中默认是`enUS-1.27.1`。

> global.ui

使用触发器数据的目录，在中文版中默认是`*YDWE`，表示会搜索你本地YDWE使用的触发器数据文件，你需要设置YDWE关联地图才能保证搜索成功。在英文版中默认是`enUS-1.27.1`。

> global.plugin_path

插件的目录。默认是`plugin`。


> lni.read_slk

输出目标是Lni时，转换地图内的slk文件。

> lni.find_id_times

输出目标是Lni时，限制搜索最优模板的次数，0表示无限。

> lni.export_lua

输出目标是Lni时，导出地图内的lua文件。

> obj.read_slk

输出目标是Obj时，转换地图内的slk文件。

> obj.find_id_times

输出目标是Obj时，限制搜索最优模板的次数，0表示无限。

> slk.remove_unuse_object

输出目标是Slk时，移除没有引用的物体对象。

> slk.mdx_squf

输出目标是Slk时，压缩mdx文件（有损压缩）。

> slk.remove_we_only

输出目标是Slk时，删除只在WE中使用的文件。

> slk.slk_doodad

输出目标是Slk时，对装饰物进行Slk优化。

> slk.optimize_jass

输出目标是Slk时，优化jass文件。

> slk.confused

输出目标是Slk时，混淆jass文件

> slk.confusion

输出目标是Slk时，混淆jass文件使用的字符集。

> slk.find_id_times

输出目标是Slk时，限制搜索最优模板的次数，0表示无限。
