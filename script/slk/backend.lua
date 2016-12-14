local progress = require 'progress'

local function to_lni(w2l, archive, slk, on_lni)
    --转换物编
    local count = 0
    for ttype, meta in pairs(w2l.info['metadata']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = slk[ttype]
        if on_lni then
            data = on_lni(w2l, ttype, data)
        end
        
        local content = w2l:backend_lni(ttype, data)
        if content then
            archive:set(ttype .. '.ini', content)
        end
        progress(1)
    end
end

local function to_obj(w2l, archive, slk, on_lni)
    --转换物编
    local count = 0
    for type, meta in pairs(w2l.info['metadata']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = slk[type]
        if on_lni then
            data = on_lni(w2l, type, data)
        end
        
        local content = w2l:backend_obj(type, data)
        if content then
            archive:set(w2l.info['template']['obj'][type], content)
        end
        progress(1)
    end
end

return function (w2l, archive, slk, on_lni)
    if w2l.config.target_format == 'lni' then
        to_lni(w2l, archive, slk, on_lni)
    elseif w2l.config.target_format == 'obj' then
        to_obj(w2l, archive, slk, on_lni)
    end

    --转换其他文件
    if archive:get 'war3map.w3i' then
        local w3i = w2l:read_w3i(archive:get 'war3map.w3i')
        local lni = w2l:w3i2lni(w3i)
        archive:set('mapinfo.ini', lni)
        archive:set('war3map.w3i', false)
    end

	--刷新字符串
	if w2l.wts then
		local content = w2l.wts:refresh()
		archive:set('war3map.wts', content)
	end
end
