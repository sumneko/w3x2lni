--[[
 Normalized Lua API for Lua 5.1, 5.2 & 5.3
 Coryright (C) 2014-2017 Gary V. Vaughan
]]
--[[--
 Depending on the state in `std._debug`, define functions for efficient
 runtime argument type checking.   This module is effectively a
 minimal implementation of `typecheck`, limited to the functionality
 required by normalize proper, so that `typecheck` itself can depend
 on `normalize` without introducing a dependency cycle.

 @module std.normalize._typecheck
]]

local _ENV = require 'std.normalize._strict' {
   _debug = require 'std._debug',
   concat = table.concat,
   error = error,
   format = string.format,
   getmetamethod = require 'std.normalize._base'.getmetamethod,
   ipairs = ipairs,
   pack = require 'std.normalize._base'.pack,
   setmetatable = setmetatable,
   sort = table.sort,
   tointeger = require 'std.normalize._base'.tointeger,
   tonumber = tonumber,
   type = type,
   unpack = table.unpack or unpack,
}


-- There an additional stack frame to count over from inside functions
-- with argchecks enabled.
local ARGCHECK_FRAME = 0



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local function argerror(name, i, extramsg, level)
   level = tointeger(level) or 1
   local s = format("bad argument #%d to '%s'", tointeger(i), name)
   if extramsg ~= nil then
      s = s .. ' (' .. extramsg .. ')'
   end
   error(s, level > 0 and level + 2 + ARGCHECK_FRAME or 0)
end


local function iscallable(x)
   return type(x) == 'function' or getmetamethod(x, '__call')
end


local argscheck
do
   -- Set argscheck according to whether argcheck is required.
   if _debug.argcheck then

      ARGCHECK_FRAME = 1

      local function icalls(name, checks, argu)
         return function(state, i)
            if i < state.checks.n then
               i = i + 1
               local r = pack(state.checks[i](state.argu, i))
               if r.n > 0 then
                  return i, r[1], r[2]
               end
               return i
            end
         end, {argu=argu, checks=checks}, 0
      end

      argscheck = function(name, ...)
         return setmetatable(pack(...), {
            __concat = function(checks, inner)
               if not iscallable(inner) then
                  error("attempt to annotate non-callable value with 'argscheck'", 2)
               end
               return function(...)
                  local argu = pack(...)
                  for i, expected, got in icalls(name, checks, argu) do
                     if got or expected then
                        local buf, extramsg = {}
                        if expected then
                           got = got or 'got ' .. type(argu[i])
                           buf[#buf +1] = expected .. ' expected, ' .. got
                        elseif got then
                           buf[#buf +1] = got
                        end
                        if #buf > 0 then
                           extramsg = concat(buf)
                        end
                        return argerror(name, i, extramsg, 3), nil
                     end
                  end
                  -- Tail call pessimisation: inner might be counting frames,
                  -- and have several return values that need preserving.
                  -- Different Lua implementations tail call under differing
                  -- conditions, so we need this hair to make sure we always
                  -- get the same number of stack frames interposed.
                  local results = pack(inner(...))
                  return unpack(results, 1, results.n)
               end
            end,
         })
      end

   else

      -- Return `inner` untouched, for no runtime overhead!
      argscheck = function(...)
         return setmetatable({}, {
            __concat = function(_, inner)
               return inner
            end,
         })
      end

   end
end



--[[ ================= ]]--
--[[ Type annotations. ]]--
--[[ ================= ]]--


local function fail(expected, argu, i, got)
   if i > argu.n then
      return expected, 'got no value'
   elseif got ~= nil then
      return expected, 'got ' .. got
   end
   return expected
end


local function check(expected, argu, i, predicate)
   local arg = argu[i]
   local ok, got = predicate(arg)
   if not ok then
      return fail(expected, argu, i, got)
   end
end


local types = setmetatable({
   -- Accept argu[i].
   accept = function() end,

   -- Reject missing argument *i*.
   arg = function(argu, i)
      if i > argu.n then
         return 'no value'
      end
   end,

   -- Accept function valued or `__call` metamethod carrying argu[i].
   callable = function(argu, i)
      return check('callable', argu, i, iscallable)
   end,

   -- Accept argu[i] if it is an integer valued number, or can be
   -- converted to one by `tonumber`.
   integer = function(argu, i)
      local value = tonumber(argu[i])
      if type(value) ~= 'number' then
         return fail('integer', argu, i)
      end
      if tointeger(value) == nil then
         return nil, 'number has no integer representation'
      end
   end,

   -- Accept missing argument *i* (but not explicit `nil`).
   missing = function(argu, i)
      if i <= argu.n then
         return nil
      end
   end,

   -- Accept string valued or `__string` metamethod carrying argu[i].
   stringy = function(argu, i)
      return check('string', argu, i, function(x)
         return type(x) == 'string' or getmetamethod(x, '__tostring')
      end)
   end,

   -- Accept non-nil valued argu[i].
   value = function(argu, i)
      if i > argu.n then
         return 'value', 'got no value'
      elseif argu[i] == nil then
         return 'value'
      end
   end,
}, {
   __index = function(_, k)
      -- Accept named primitive valued argu[i].
      return function(argu, i)
         return check(k, argu, i, function(x)
            return type(x) == k
         end)
      end
   end,
})


local function any(...)
   local fns = {...}
   return function(argu, i)
      local buf, expected, got, r = {}
      for _, predicate in ipairs(fns) do
         r = pack(predicate(argu, i))
         expected, got = r[1], r[2]
         if r.n == 0 then
            -- A match!
            return
         elseif r.n == 2 and expected == nil and #got > 0 then
            -- Return non-type based mismatch immediately.
            return expected, got
         elseif expected ~= 'nil' then
            -- Record one of the types we would have matched.
            buf[#buf + 1] = expected
         end
      end
      if #buf == 0 then
         return got
      elseif #buf > 1 then
         sort(buf)
         buf[#buf -1], buf[#buf] = buf[#buf -1] .. ' or ' .. buf[#buf], nil
      end
      expected = concat(buf, ', ')
      if got ~= nil then
         return expected, got
      end
      return expected
   end
end


local function opt(...)
   return any(types['nil'], ...)
end



return {
   --- Add this to any stack frame offsets when argchecks are in force.
   -- @int ARGCHECK_FRAME
   ARGCHECK_FRAME = ARGCHECK_FRAME,

   --- Call each argument in turn until one returns non-nil.
   --
   -- This function satisfies the @{ArgCheck} interface in order to be
   -- useful as an argument to @{argscheck} when one of several other
   -- @{ArgCheck} functions can satisfy the requirement for a given
   -- argument.
   -- @function any
   -- @tparam ArgCheck ... type predicate callables
   -- @treturn ArgCheck a new function that calls all passed
   --    predicates, and combines error messages if all fail
   -- @usage
   --    len = argscheck('len', any(types.table, types.string)) .. len
   any = any,

   --- Raise a bad argument error.
   -- @see std.normalize.argerror
   argerror = argerror,

   --- A rudimentary argument type validation decorator.
   --
   -- Return the checked function directly if `_debug.argcheck` is reset,
   -- otherwise use check function arguments using predicate functions in
   -- the corresponding positions in the decorator call.
   -- @function argscheck
   -- @string name function name to use in error messages
   -- @tparam func predicate return true if checked function argument is
   --    valid, otherwise return nil and an error message suitable for
   --    *extramsg* argument of @{argerror}
   -- @tparam func ... additional predicates for subsequent checked
   --    function arguments
   -- @raises argerror when an argument validator returns failure
   -- @see argerror
   -- @usage
   --    local unpack = argscheck('unpack', types.table) ..
   --    function(t, i, j)
   --       return table.unpack(t, i or 1, j or #t)
   --    end
   argscheck = argscheck,

   --- Low-level type conformance check helper.
   --
   -- Use this, with a simple @{Predicate} function, to write concise argument
   -- type check functions.
   -- @function check
   -- @string expected name of the expected type
   -- @tparam table argu a packed table (including `n` field) of all arguments
   -- @int i index into *argu* for argument to action
   -- @tparam Predicate predicate check whether `argu[i]` matches `expected`
   -- @usage
   --    function callable(argu, i)
   --       return check('string', argu, i, function(x)
   --          return type(x) == 'string'
   --       end)
   --    end
   check = check,

   --- Create an @{ArgCheck} predicate for an optional argument.
   --
   -- This function satisfies the @{ArgCheck} interface in order to be
   -- useful as an argument to @{argscheck} when a particular argument
   -- is optional.
   -- @function opt
   -- @tparam ArgCheck ... type predicate callables
   -- @treturn ArgCheck a new function that calls all passed
   --    predicates, and combines error messages if all fail
   -- @usage
   --    getfenv = argscheck(
   --       'getfenv', opt(types.integer, types.callable)
   --    ) .. getfenv
   opt = opt,

   --- A collection of @{ArgCheck} functions used by `normalize` APIs.
   -- @table types
   -- @tfield ArgCheck accept always succeeds
   -- @tfield ArgCheck callable accept a function or functor
   -- @tfield ArgCheck integer accept integer valued number
   -- @tfield ArgCheck nil accept only `nil`
   -- @tfield ArgCheck stringy accept a string or `__tostring` metamethod
   --    bearing object
   -- @tfield ArgCheck table accept any table
   -- @tfield ArgCheck value accept any non-`nil` value
   types = types,
}



--- Types
-- @section types

--- Signature of an @{argscheck} callable.
-- @function ArgCheck
-- @tparam table argu a packed table (including `n` field) of all arguments
-- @int index into *argu* for argument to action
-- @return[1] nothing, to accept `argu[i]` 
-- @treturn[2] string error message, to reject `argu[i]` immediately
-- @treturn[3] string the expected type of `argu[i]`
-- @treturn[3] string a description of rejected `argu[i]`
-- @usage
--    len = argscheck('len', any(types.table, types.string)) .. len

--- Signature of a @{check} type predicate callable.
-- @function Predicate
-- @param x object to action
-- @treturn boolean `true` if *x* is of the expected type, otherwise `false`
-- @treturn[opt] string description of the actual type for error message
