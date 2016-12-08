local w3xparser = require 'w3xparser'
local txt = w3xparser.txt

return function (w2l, content)
	return txt(content)
end
