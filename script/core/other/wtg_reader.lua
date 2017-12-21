local function wtg2txt(w2l, content, state)
    local index    = 1
    local len    = #content

    local chunk    = {}
    local funcs    = {}
    local categories, category, vars, var, triggers, trigger, ecas, eca, args, arg

    --文件头
    function funcs.readHead()
        chunk.file_id,            --文件ID
        chunk.file_ver,            --文件版本
        index    = ('c4l'):unpack(content, index)
    end

    --触发器类别(文件夹)
    function funcs.readCategories()
        --触发器类别数量
        chunk.category_count, index    = ('l'):unpack(content, index)

        --初始化
        categories    = {}
        chunk.categories    = categories

        for i = 1, chunk.category_count do
            funcs.readCategory()
        end
    end

    function funcs.readCategory()
        category    = {}
        category.id, category.name, category.comment, index    = ('lzl'):unpack(content, index)

        table.insert(categories, category)
    end

    --全局变量
    function funcs.readVars()
        --全局变量数量
        chunk.int_unknow_1, chunk.var_count, index    = ('ll'):unpack(content, index)
        
        --初始化
        vars    = {}
        chunk.vars    = vars

        for i = 1, chunk.var_count do
            funcs.readVar()
        end
    end

    function funcs.readVar()
        var    = {}
        var.name,        --变量名
        var.type,        --变量类型
        var.int_unknow_1,    --(永远是1,忽略)
        var.is_array,    --是否是数组(0不是, 1是)
        var.array_size,    --数组大小(非数组是1)
        var.is_default,    --是否是默认值(0是, 1不是)
        var.value,        --初始数值
        index = ('zzllllz'):unpack(content, index)

        table.insert(vars, var)
        vars[var.name]    = var
    end

    --触发器
    function funcs.readTriggers()
        --触发器数量
        chunk.trigger_count, index    = ('l'):unpack(content, index)

        --初始化
        triggers    = {}
        chunk.triggers    = triggers

        for i = 1, chunk.trigger_count do
            funcs.readTrigger()
        end
    end

    function funcs.readTrigger()
        trigger    = {}
        trigger.name,        --触发器名字
        trigger.des,        --触发器描述
        trigger.type,        --类型(0普通, 1注释)
        trigger.enable,        --是否允许(0禁用, 1允许)
        trigger.wct,        --是否是自定义代码(0不是, 1是)
        trigger.init,        --是否初始化(0是, 1不是)
        trigger.run_init,    --地图初始化时运行
        trigger.category,    --在哪个文件夹下
        index    = ('zzllllll'):unpack(content, index)

        table.insert(triggers, trigger)
        --print('trigger:' .. trigger.name)
        --读取子结构
        funcs.readEcas()

    end

    --子结构
    function funcs.readEcas()
        --子结构数量
        trigger.eca_count, index    = ('l'):unpack(content, index)

        --初始化
        ecas    = {}
        trigger.ecas    = ecas

        for i = 1, trigger.eca_count do
            funcs.readEca()
        end
    end

    function funcs.readEca(is_child, is_arg)
        eca    = {}
        local eca    = eca
        
        eca.type,    --类型(0事件, 1条件, 2动作, 3函数调用)
        index    = ('l'):unpack(content, index)

        --是否是复合结构
        if is_child then
            eca.child_id, index    = ('l'):unpack(content, index)
        end

        --是否是参数中的子函数
        if is_arg then
            is_arg.eca    = eca
        else
            table.insert(ecas, eca)
        end
        
        eca.name,    --名字
        eca.enable,    --是否允许(0不允许, 1允许)
        index    = ('zl'):unpack(content, index)

        --print('eca:' .. eca.name)
        --读取参数
        funcs.readArgs(eca)

        --if,loop等复合结构
        eca.child_eca_count, index    = ('l'):unpack(content, index)
        for i = 1, eca.child_eca_count do
            funcs.readEca(true)
        end
    end

    --参数
    function funcs.readArgs(eca)
        --初始化
        args    = {}
        local args    = args
        eca.args    = args

        --print(eca.type, eca.name)
        local function_data = state[eca.type][eca.name]
        if not function_data then
            error(('触发器UI[%s]不存在'):format(eca.name))
        end
        local state_args    = function_data.args
        local arg_count    = #state_args

        --print('args:' .. arg_count)

        for i = 1, arg_count do
            funcs.readArg(args)
        end

    end

    function funcs.readArg(args)
        arg    = {}

        arg.type,             --类型(0预设, 1变量, 2函数, 3代码)
        arg.value,            --值
        arg.insert_call,    --是否需要插入调用
        index    = ('lzl'):unpack(content, index)
        --print('var:' .. arg.value)

        --是否是索引
        table.insert(args, arg)

        --插入调用
        if arg.insert_call == 1 then
            funcs.readEca(false, arg)
            arg.int_unknow_1, index    = ('l'):unpack(content, index) --永远是0
            --print(arg.int_unknow_1)
            return
        end

        arg.insert_index,    --是否需要插入数组索引
        index    = ('l'):unpack(content, index)

        --插入数组索引
        if arg.insert_index == 1 then
            funcs.readArg(args)
        end
    end

    --开始解析
    do
        funcs.readHead()
        funcs.readCategories()
        funcs.readVars()
        funcs.readTriggers()
    end

    return chunk
end

return wtg2txt
