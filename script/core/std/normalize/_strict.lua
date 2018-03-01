--[[
 Normalized Lua API for Lua 5.1, 5.2 & 5.3
 Coryright (C) 2014-2017 Gary V. Vaughan
]]
--[[--
 Depending on whether `std.strict` is installed, and the value of
 `std._debug.strict`, return a function for setting up a strict lexical
  environment for the caller.

 @module std.normalize._strict
]]

local _ENV = {
   _debug = require 'std._debug',
   pcall = pcall,
   require = require,
   setfenv = setfenv or function() end,
   setmetatable = setmetatable,
}
setfenv(1, _ENV)



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


-- If strict mode is required, use 'std.strict' if we have it.
local strict
if _debug.strict then
   -- `require 'std.strict'` will get the old stdlib implementation of
   -- strict, which doesn't support environment tables :(
   ok, strict = pcall(require, 'std.strict.init')
   if not ok then
      strict = false
   end
end


--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


return setmetatable({
   --- Set a module environment, using std.strict if available.
   --
   -- Either 'std.strict' when available, otherwise a(Lua 5.1 compatible)
   -- function to set the specified module environment.
   -- @function strict
   -- @tparam table env module environment table
   -- @treturn table *env*, which must be assigned to `_ENV`
   -- @usage
   --    local _ENV = require 'std.normalize._strict'.strict {}
   strict = strict or function(env)
      return env
   end,
}, {
   --- Module Metamethods
   -- @section modulemetamethods

   --- Set a module environment, using std.strict if available.
   -- @function strict:__call
   -- @tparam table env module environment table
   -- @tparam[opt=1] int level stack level for `setfenv`, 1 means set
   --    caller's environment
   -- @treturn table *env*, which must be assigned to `_ENV`
   -- @usage
   --    local _ENV = require 'std.normalize._strict' {}
   __call = function(_, env, level)
      setfenv(1+(level or 1), env)
      return env
   end,
})
