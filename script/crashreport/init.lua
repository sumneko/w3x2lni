local messagebox = require 'ffi.messagebox'
local lang = require 'tool.lang'

messagebox(lang.ui.ERROR, '%s', io.stdin:read 'a')
