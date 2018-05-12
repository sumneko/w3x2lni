local messagebox = require 'ffi.messagebox'
local lang = require 'share.lang'

messagebox(lang.ui.ERROR, '%s', io.stdin:read 'a')
