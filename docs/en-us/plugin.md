# Plugin

w3x2lni supports custom plugins, you can use plugins to change file conversion behaviours.

> w3x2lni does not perform security check on plugins. Possible failures of conversion occur if you are doing it wrong.

### Quick Start

Create a `plugin` directory under w3x2lni root, and then create a `.config` file inside. Enter the plugin name you would like to load, w3x2lni will automatically load `plugin\<plugin_name>.lua`.

> plugin/.config

```
ModUnitName
```

> plugin/ModUnitName.lua

```lua
local mt = {}

mt.info = {
    name = 'ModUnitName',
    version = 1.0,
    author = 'sumneko',
    description = 'Prepend "plugin modified" to all units names.',
}

function mt:on_full(w2l)
    for id, obj in pairs(w2l.slk.unit) do
        obj.name = 'plugin modified' .. obj.name
    end
end

return mt
```

### Config

The config file is `plugin/.config`, put plugin names inside and w3x2lni will load the plugins by name. If you would like to load multiple plugins, separate them with line breakers. w3x2lni will load them by order.

```
Plugin_1
Plugin_2
Plugin_3
```

### Plugin

A plugin is a `plugin/<plugin_name>.lua` file. It will only be loaded if it's defined in `plugin/.config`. A plugin is a lua script. It returns a table which may contain the following properties and methods:

#### info

The meta data (info) of a plugin is a table contains these properties:

+ `name` string
+ `version` number
+ `author` string
+ `description` string

```lua
mt.info = {
    name = 'Plugin Name',
    version = 1.0,
    author = 'Plugin Author',
    description = 'Plugin description',
}
```

#### on_full

Full event, check [here][DataFull] for the defination of Full. In this event you can change object data in an easy way to manipulate the final results.

> Data format of Full data refers to `data/enUS-1.27.1/prebuilt/Custom`

```lua
-- Let all abilities cost no mana and have no cooldown
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

Mark event, you an mark the references of objects in this event to prevent to be deleted during SLK conversion. This event returns a table, all objects corresponding to the `key`s will be marked as referenced.

```lua
-- Reference L000 - L009 objects, this objects will only be used in Lua scripts and can't be referenced automatically
function mt:on_mark()
    local list = {}

    for i = 0, 9 do
        list['L00'..i] = true
    end

    return list
end
```

### Interface

There's no dedicated interfaces for plugins, instead that the plugins act as part of the code base. The context data will be passed into the event callbacks in plugins. In other words, plugins can use any w3x2lni internal functions at your will. But you need to be 100 percent sure what you are doing. Here are some common internal functions usages (assume the context is saved in w2l):

#### slk

Object editor data table, refers to `data/enUS-1.27.1/prebuilt/Custom`

```lua
for type, list in pairs(w2l.slk) do
    for id, obj in pairs(list) do
        for key, value in pairs(obj) do
        end
    end
end
```

#### setting

Configuration table, besides of the properties in `config.ini`, here are some more:

+ input (filesystem) - input path
+ output (filesystem) - output path
+ target_storage (string) - output format, `mpq` for the playable map, `dir` for directory
+ mode (string) - output mode, `slk`, `obj` or `lni`
+ version (string) - map version, `Custom` for custom maps, `Melee` for melee maps

```lua
if w2l.setting.mode == 'slk' then
end
```

#### file_save

Save files

+ type (string) - file type, check the Lni format directory hierarchy
+ path (string) - file name
+ buf (string) - file data

```lua
w2l:file_save('scripts', 'blizzard.j', '')
```

#### file_load

Load files

+ type (string) - file type
+ path (string) - file name

```lua
local buf = w2l:file_load('script', 'blizzard.j')
```

#### file_remove

Remove files

+ type (string) - file type
+ path (string) - file name

```lua
w2l:file_remove('script', 'blizzard.j')
```

#### input_mode

Input file mode, `lni` for that the input map is Lni

### In-map plugins

Place the `plugin` directory under `w3x2lni` directory of a map. The map here can be `Lni` format or `Obj` format. W3x2lni will invoke these plugins when processing the map. The in-map plugins will stay where they are, except for that the conversion mode is `Slk` and `Removed WE-only files` is enabled.

[DataFull]: /en-us/insider
