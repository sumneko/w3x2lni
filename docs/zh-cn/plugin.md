# 插件

w3x2lni支持自定义插件，你可以用插件来修改转换文件的行为。

!> w3x2lni不会对插件行为做安全检查，进行一些错误的操作可能导致转换出错。

### 快速开始
在w3x2lni根目录新建`plugin`文件夹，在里面放一个`.config`文件，写上想要加载的插件名，w3x2lni便会去加载`plugin\插件名.lua`。

> plugin\\.config

```
修改单位名
```

> plugin\\修改单位名.lua

```lua
local mt = {}

mt.info = {
    name = '修改单位名',
    version = 1.0,
    author = '最萌小汐',
    description = '将所有单位的名字加上前缀"被插件修改过的"。',
}

function mt:on_full(w2l)
    for id, obj in pairs(w2l.slk.unit) do
        obj.name = '被插件修改过的' .. obj.name
    end
end

return mt
```

### 配置
配置文件为`plugin\.config`，在该文件中写上想要加载的插件名，w3x2lni便会去加载相应的插件。如果要加载多个插件，可以每行写一个插件名，w3x2lni会按照顺序去加载这些插件。

```
插件1
插件2
插件3
```

### 插件
插件为`plugin\插件名.lua`，需要在`plugin\.config`中定义后才会加载。插件应该是一个lua脚本，它需要返回一张表，在表中应有以下属性：

#### info
插件的基本信息，是一张拥有下列属性的表：

+ `name` 插件的名字，字符串。
+ `version` 插件的版本号，数字。
+ `author` 插件的作者，字符串。
+ `description` 插件的描述，字符串。

```lua
mt.info = {
    name = '插件名',
    version = 1.0,
    author = '插件作者',
    description = '插件描述',
}
```

#### on_full
完整数据（Full）事件，关于完整数据的定义见[这里][完整数据]。在该事件中可以简单方便的修改物编数据从而修改转换后的结果。

> 完整数据内的数据格式可以参考`data\zhCN-1.24.4\prebuilt\Custom`

```lua
-- 让所有技能无冷却无消耗
function mt:on_full(w2l)
    for id, skill in pairs(w2l.slk.ability) do
        for i = 1, skill._max_level do
            skill.cost[i] = 0
            skill.cool[i] = 0
        end
    end
end
```

#### on_mark
引用标记事件，在该事件中可以对对象的引用进行标记，以免转换Slk时对象被当做未使用对象而删除。这个事件期待返回一张表，这张表的所有`key`对应的对象都会被标记为引用。

```lua
-- 引用L000 - L009的对象，这些对象只在Lua脚本中使用，无法被自动引用
function mt:on_mark()
    local list = {}

    for i = 0, 9 do
        list['L00'..i] = true
    end

    return list
end
```

[完整数据]: /zh-cn/insider
