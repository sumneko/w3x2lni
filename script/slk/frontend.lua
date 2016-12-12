local progress = require 'progress'

local function load_obj(w2l, files, ttype, file_name, target_progress)
    local metadata = w2l:read_metadata(ttype)
    local key_data = w2l:parse_lni(io.load(w2l.key / (ttype .. '.ini')), ttype)

    local obj, data
    local force_slk

    progress:target(target_progress-1)
    if files[file_name] then
        message('正在转换', file_name)
        obj, force_slk = w2l:frontend_obj(ttype, file_name, self.files[file_name](file_name))
    end

    progress:target(target_progress)
    if force_slk or w2l.config['unpack']['read_slk'] then
        data = w2l:frontend_slk(ttype, function(name)
            message('正在转换', name)
            if files[name] then
                return files[name](name)
            end
            return io.load(w2l.mpq / name)
        end)
    else
        data = w2l:parse_lni(io.load(w2l.default / (ttype .. '.ini')))
    end

    add_table(data, obj or {})

    return data
end

local function load_data(w2l, files)
    local objs = {}

	--读取字符串
	if files['war3map.wts'] then
		w2l:frontend_wts(files['war3map.wts']('war3map.wts'))
	end
    
    local count = 0
    for ttype, name in pairs(w2l.info.template.obj) do
        count = count + 1
        local target_progress = 3 + count * 2
        objs[ttype] = load_obj(w2l, files, ttype, name, target_progress)
    end

    -- 删掉输入的二进制物编和slk,因为他们已经转化成lua数据了
    for _, name in pairs(w2l.info.template.obj) do
        files[name] = nil
    end
    if w2l.config['unpack']['read_slk'] then
        for _, names in pairs(w2l.info.template.slk) do
            for _, name in ipairs(names) do
                files[name] = nil
            end
        end
        for _, names in pairs(w2l.info.template.txt) do
            for _, name in ipairs(names) do
                files[name] = nil
            end
        end
    end

    return objs
end

return load_data
