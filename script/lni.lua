local mt = {}
local lni = require 'lni-c'
function mt:loader(...)
	return lni(...)
end
return mt
