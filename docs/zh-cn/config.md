# 配置文件

> global.mpq_path

数据文件的目录。默认是`data/mpq`。

> global.mpq

使用哪个数据文件。默认是`zhCN-1.24.4`。

> global.prebuilt_path

缓存文件的目录，默认是`data/prebuilt`。为了加快运行速度，我们会在第一次使用数据文件时，缓存一些结果。

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

> slk.confusion

输出目标是Slk时，混淆jass文件。

> slk.find_id_times

输出目标是Slk时，限制搜索最优模板的次数，0表示无限。
