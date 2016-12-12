local progress = require 'progress'

local function to_lni(w2l, files, objs, on_lni)
    --转换物编
    local count = 0
    for ttype, meta in pairs(w2l.info['metadata']) do
        count = count + 1
        local target_progress = 66 + count * 2
        progress:target(target_progress)
        
        local data = objs[ttype]
        if on_lni then
            data = on_lni(w2l, ttype, data)
        end
        
        local content = w2l:backend_lni(ttype, data)
        if content then
            files[ttype .. '.ini'] = function() return content end
        end
        progress(1)
    end

    --转换其他文件
    if files['war3map.w3i'] then
        local w3i = w2l:read_w3i(files['war3map.w3i']('war3map.w3i'))
        local lni = w2l:w3i2lni(w3i)
        files['mapinfo.ini'] = function() return lni end
        files['war3map.w3i'] = nil
    end

	--刷新字符串
	if w2l.wts then
		local content = w2l.wts:refresh()
		files['war3map.wts'] = function() return content end
	end
end

return to_lni
