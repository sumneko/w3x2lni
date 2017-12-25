local types = {'action', 'call', 'condition', 'event'}

local function copy(a, b)
    if a and b then
        for k, v in pairs(b) do
            a[k] = v
        end
    end
end

local function insert(a, b)
    if a and b then
        for _, v in ipairs(b) do
            table.insert(a, v)
        end
    end
end

local function merge_categories(a, b)
    if a and b then
        for _, v in ipairs(b) do
            table.insert(a, v)
            if not a[v] then
                a[v] = {}
            end
            insert(a[v], b[v])
        end
    end
end

local function merge_fix(state, fix)
    for _, type in ipairs(types) do
        copy(state.ui[type], fix.ui[type])
    end
    insert(state.ui.define.TriggerCategories, fix.ui.define.TriggerCategories)
    insert(state.ui.define.TriggerTypes, fix.ui.define.TriggerTypes)

    for _, type in ipairs(types) do
        merge_categories(state.categories[type], fix.categories[type])
    end
end

return function (w2l, wtg, state)
    local wtg_data, fix = w2l:wtg_reader(wtg, state)
    merge_fix(state, fix)
    return wtg_data
end
