require 'filesystem'
fs.current_path(fs.path 'script')
local prebuilt = require 'prebuilt.prebuilt'

prebuilt:complete()
