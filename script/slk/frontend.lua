local progress = require 'progress'

local function add_table(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if tbl1[k] then
            if type(tbl1[k]) == 'table' and type(v) == 'table' then
                add_table(tbl1[k], v)
            else
                tbl1[k] = v
            end
        else
            tbl1[k] = v
        end
    end
end

local function load_obj(w2l, archive, ttype, filename, target_progress)
    local metadata = w2l:read_metadata(ttype)
    local key_data = w2l:parse_lni(io.load(w2l.key / (ttype .. '.ini')), ttype)

    local obj, data
    local force_slk

    progress:target(target_progress-1)
    local buf = archive:get(filename)
    if buf then
        message('正在转换', file_name)
        obj, force_slk = w2l:frontend_obj(ttype, filename, buf)
    end

    progress:target(target_progress)
    if force_slk or w2l.config['unpack']['read_slk'] then
        data = w2l:frontend_slk(ttype, function(name)
            message('正在转换', name)
            local buf = archive:get(name)
            if buf then
                return buf
            end
            return io.load(w2l.mpq / name)
        end)
    else
        data = w2l:parse_lni(io.load(w2l.default / (ttype .. '.ini')))
    end

    add_table(data, obj or {})

    return data
end

local function load_data(w2l, archive)
    local slk = {}

	--读取字符串
    local wts = archive:get('war3map.wts')
	if wts then
		w2l:frontend_wts(wts)
	end
    
    local count = 0
    for ttype, name in pairs(w2l.info.template.obj) do
        count = count + 1
        local target_progress = 3 + count * 2
        slk[ttype] = load_obj(w2l, archive, ttype, name, target_progress)
    end

    -- TODO: 删掉输入的二进制物编和slk,因为他们已经转化成lua数据了
    -- 
    --for _, name in pairs(w2l.info.template.obj) do
    --    files[name] = nil
    --end
    --if w2l.config['unpack']['read_slk'] then
    --    for _, names in pairs(w2l.info.template.slk) do
    --        for _, name in ipairs(names) do
    --            files[name] = nil
    --        end
    --    end
    --    for _, names in pairs(w2l.info.template.txt) do
    --        for _, name in ipairs(names) do
    --            files[name] = nil
    --        end
    --    end
    --end

    return slk
end

return load_data
