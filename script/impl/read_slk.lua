local w3xparser = require 'w3xparser'
local slk = w3xparser.slk

return function (w2l, content)
	return slk(content)
end
