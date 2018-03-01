local wtg

local pack_eca

local function pack(fmt, ...)
    hex[#hex+1] = fmt:pack(...)
end

local function pack_head()
    pack('c4l', 'WTG!', 7)
end

local function pack_category()
    pack('l', #wtg.categories)
    for _, cate in ipairs(wtg.categories) do
        pack('lzl', cate.id, cate.name, cate.comment)
    end
end

local function pack_var()
    pack('ll', 2, #wtg.vars)
    for _, var in ipairs(wtg.vars) do
        pack('zzllllz',
            var.name,
            var.type,
            1,
            var.array,
            var.size,
            var.default,
            var.value
        )
    end
end

local function pack_arg(arg)
    pack('lz', arg.type, arg.value)
    if arg.eca then
        pack('l', 1)
        pack_eca(arg.eca)
    else
        pack('l', 0)
    end
    if arg.index then
        pack('l', 1)
        pack_arg(arg.index)
    else
        pack('l', 0)
    end
end

function pack_eca(eca)
    pack('l', eca.type)
    if eca.child_id then
        pack('l', eca.child_id)
    end
    pack('zl', eca.name, eca.enable)

    if eca.args then
        for _, arg in ipairs(eca.args) do
            pack_arg(arg)
        end
    end

    if eca.child then
        pack('l', #eca.child)
        for _, child in ipairs(eca.child) do
            pack_eca(child)
        end
    else
        pack('l', 0)
    end
end

local function pack_trigger()
    pack('l', #wtg.triggers)
    for _, trg in ipairs(wtg.triggers) do
        pack('zzlllllll',
            trg.name,
            trg.des,
            trg.type,
            trg.enable,
            trg.wct,
            trg.open,
            trg.run,
            trg.category,
            #trg.ecas
        )
        for _, eca in ipairs(trg.ecas) do
            pack_eca(eca)
        end
    end
end

return function (w2l_, wtg_)
    wtg = wtg_
    hex = {}

    pack_head()
    pack_category()
    pack_var()
    pack_trigger()

    return table.concat(hex)
end
