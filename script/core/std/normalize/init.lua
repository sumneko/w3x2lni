--[[
 Normalized Lua API for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2011-2017 Gary V. Vaughan
 Copyright (C) 2002-2014 Reuben Thomas <rrt@sc3d.org>
]]
--[[--
 Normalize API differences between supported Lua implementations.

 Respecting the values set in the `std._debug` settings module, inject
 deterministic identically behaving cross-implementation low-level
 functions into the callers environment.

 Writing Lua libraries that target several Lua implementations can be a
 frustrating exercise in working around lots of small differences in APIs
 and semantics they share (or rename, or omit).   _normalize_ provides the
 means to simply access deterministic implementations of those APIs that
 have the the same semantics across all supported host Lua
 implementations.   Each function is as thin and fast an implementation as
 is possible within that host Lua environment, evaluating to the Lua C
 implementation with no overhead where host semantics allow.

 The core of this module is to transparently set the environment up with
 a single API (as opposed to requiring caching functions from a module
 table into module locals):

      local _ENV = require 'std.normalize' {
         'package',
         'std.prototype',
         strict = 'std.strict',
      }

 It is not yet complete, and in contrast to the kepler project
 lua-compat libraries, neither does it attempt to provide you with as
 nearly compatible an API as is possible relative to some specific Lua
 implementation - rather it provides a variation of the "lowest common
 denominator" that can be implemented relatively efficiently in the
 supported Lua implementations, all in pure Lua.

 At the moment, only the functionality used by stdlib is implemented.

 @module std.normalize
]]



local _ = {
   base = require 'std.normalize._base',
   strict = require 'std.normalize._strict',
   typecheck = require 'std.normalize._typecheck',
}

local _ENV = _.strict {
   _G = _G,
   _VERSION = _VERSION,
   ARGCHECK_FRAME = _.typecheck.ARGCHECK_FRAME,
   any = _.typecheck.any,
   argerror = _.typecheck.argerror,
   argscheck = _.typecheck.argscheck,
   concat = table.concat,
   config = package.config,
   debug_getfenv = debug.getfenv or false,
   debug_getinfo = debug.getinfo,
   debug_getupvalue = debug.getupvalue,
   debug_setfenv = debug.setfenv or false,
   debug_setupvalue = debug.setupvalue,
   debug_upvaluejoin = debug.upvaluejoin,
   error = error,
   exit = os.exit,
   format = string.format,
   getfenv = getfenv or false,
   getmetamethod = _.base.getmetamethod,
   getmetatable = getmetatable,
   gmatch = string.gmatch,
   gsub = string.gsub,
   load = load,
   loadstring = loadstring or load,
   match = string.match,
   next = next,
   open = io.open,
   opt = _.typecheck.opt,
   pack = _.base.pack,
   pairs = pairs,
   pcall = pcall,
   rawset = rawset,
   remove = table.remove,
   require = require,
   searchpath = package.searchpath,
   select = select,
   setfenv = setfenv or false,
   setmetatable = setmetatable,
   sort = table.sort,
   strict = _.strict,
   tointeger = _.base.tointeger,
   tostring = tostring,
   type = type,
   types = _.typecheck.types,
   unpack = table.unpack or unpack,
   upper = string.upper,
   xpcall = xpcall,
}
_ = nil


local ARGCHECK_FRAME = ARGCHECK_FRAME



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


-- At this point, only the locals imported above are visible (even in
-- Lua 5.1). If 'std.strict' is available, we'll also get a runtime
-- error if any of the code below tries to use an undeclared variable.


local dirsep, pathsep, pathmark, execdir, igmark =
   match(config, '^([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)')


-- It's hard to test at require-time whether the host `os.exit` handles
-- boolean argument properly (ostensibly to defer to it in that case).
-- We're shutting down anyway, so sacrifice a bit of speed for timely
-- diagnosis of float and nil valued argument (with the argscheck
-- annotation, later in the file), since that probably indicates a bug
-- in your code!
local _exit = exit
local function exit(...)
   local n, status = select('#', ...), ...
   if tointeger(n) == 0 or status == true then
      _exit(0)
   elseif status == false then
      _exit(1)
   end
   _exit(status)
end


local normalize_getfenv
if debug_getfenv then

   normalize_getfenv = function(fn)
      local n = tointeger(fn or 1)
      if n then
         if n > 0 then
            -- Adjust for this function's stack frame, if fn is non-zero.
            n = n + 1 + ARGCHECK_FRAME
         end

         -- Return an additional nil result to defeat tail call elimination
         -- which would remove a stack frame and break numeric *fn* count.
         return getfenv(n), nil
      end

      if type(fn) ~= 'function' then
         -- Unwrap functors:
         -- No need to recurse because Lua doesn't support nested functors.
         -- __call can only (sensibly) be a function, so no need to adjust
         -- stack frame offset either.
         fn =(getmetatable(fn) or {}).__call or fn
      end

      -- In Lua 5.1, only debug.getfenv works on C functions; but it
      -- does not work on stack counts.
      return debug_getfenv(fn)
   end

else

   -- Thanks to http://lua-users.org/lists/lua-l/2010-06/msg00313.html
   normalize_getfenv = function(fn)
      if fn == 0 then
         return _G
      end
      local n = tointeger(fn or 1)
      if n then
         fn = debug_getinfo(n + 1 + ARGCHECK_FRAME, 'f').func
      elseif type(fn) ~= 'function' then
         fn = (getmetatable(fn) or {}).__call or fn
      end

      local name, env
      local up = 0
      repeat
         up = up + 1
         name, env = debug_getupvalue(fn, up)
      until name == '_ENV' or name == nil
      return env
   end

end


local function rawlen(x)
   -- Lua 5.1 does not implement rawlen, and while # operator ignores
   -- __len metamethod, `nil` in sequence is handled inconsistently.
   if type(x) ~= 'table' then
      return #x
   end

   local n = #x
   for i = 1, n do
      if x[i] == nil then
         return i -1
      end
   end
   return n
end


local function len(x)
   local m = getmetamethod(x, '__len')
   if m then
      return m(x)
   elseif getmetamethod(x, '__tostring') then
      x = tostring(x)
   end
   return rawlen(x)
end


local function ipairs(l)
   if getmetamethod(l, '__len') then
      -- Use a closure to capture len metamethod result if necessary.
      local n = len(l)
      return function(l, i)
         i = i + 1
         if i <= n then
            return i, l[i]
         end
      end, l, 0
   end

   -- ...otherwise, find the last item as we go without calling `len()`.
   return function(l, i)
      i = i + 1
      if l[i] ~= nil then
         return i, l[i]
      end
   end, l, 0
end


local function keys(t)
   local r = {}
   for k in pairs(t) do
      r[#r + 1] = k
   end
   return r
end


if not pcall(load, '_=1') then
   local loadfunction = load
   load = function(...)
      if type(...) == 'string' then
         return loadstring(...)
      end
      return loadfunction(...)
   end
end


local function normalize_load(chunk, chunkname)
   local m = getmetamethod(chunk, '__call')
   if m then
      chunk = m
   elseif getmetamethod(chunk, '__tostring') then
      chunk = tostring(chunk)
   end
   if getmetamethod(chunkname, '__tostring') then
      chunkname = tostring(chunkname)
   end
   return load(chunk, chunkname)
end


local function merge(t, r)
   r = r or {}
   for k, v in next, t do
      r[k] = r[k] or v
   end
   return r
end


if not not pairs(setmetatable({},{__pairs=function() return false end})) then
   -- Add support for __pairs when missing.
   local _pairs = pairs
   function pairs(t)
      return(getmetamethod(t, '__pairs') or _pairs)(t)
   end
end


local pathmatch_patt = '[^' .. pathsep .. ']+'

local searchpath = searchpath or function(name, path, sep, rep)
   name = gsub(name, sep or '%.', rep or dirsep)

   local errbuf = {}
   for template in gmatch(path, pathmatch_patt) do
      local filename = gsub(template, pathmark, name)
      local fh = open(filename, 'r')
      if fh then
         fh:close()
         return filename
      end
      errbuf[#errbuf + 1] = "\tno file '" .. filename .. "'"
   end
   return nil, concat(errbuf, '\n')
end


local normalize_setfenv
if debug_setfenv then

   normalize_setfenv = function(fn, env)
      local n = tointeger(fn or 1)
      if n then
         if n > 0 then
            n = n + 1 + ARGCHECK_FRAME
         end
         return setfenv(n, env), nil
      end
      if type(fn) ~= 'function' then
         fn =(getmetatable(fn) or {}).__call or fn
      end
      return debug_setfenv(fn, env)
   end

else

   -- Thanks to http://lua-users.org/lists/lua-l/2010-06/msg00313.html
   normalize_setfenv = function(fn, env)
      local n = tointeger(fn or 1)
      if n then
         if n > 0 then
            n = n + 1 + ARGCHECK_FRAME
         end
         fn = debug_getinfo(n, 'f').func
      elseif type(fn) ~= 'function' then
         fn =(getmetatable(fn) or {}).__call or fn
      end

      local up, name = 0
      repeat
         up = up + 1
         name = debug_getupvalue(fn, up)
      until name == '_ENV' or name == nil
      if name then
         debug_upvaluejoin(fn, up, function() return name end, 1)
         debug_setupvalue(fn, up, env)
      end
      return n ~= 0 and fn or nil
   end

end


local shallow_copy = merge


local function render(x, vfns, roots)
   if vfns.term(x) then
      return vfns.elem(x)
   end

   roots = roots or {}

   local function stop_roots(x)
      return roots[x] or render(x, vfns, shallow_copy(roots))
   end

   local buf, pair, sep = {vfns.open(x)}, vfns.pair, vfns.sep
   roots[x] = vfns.elem(x) -- recursion protection

   local seqp, kp, vp -- proper sequence?, previous key and value
   local keylist = vfns.sort(keys(x))
   for i, k in ipairs(keylist) do
      local v = x[k]
      buf[#buf + 1] = sep(x, kp, vp, k, v, seqp) -- buffer << separator
      if k == 1 then
         seqp = true
      else
         seqp = seqp and type(kp) == 'number' and k == kp + 1
      end
      buf[#buf + 1] = pair(x, kp, vp, k, v, stop_roots(k), stop_roots(v), seqp)
      kp, vp = k, v
   end
   buf[#buf + 1] = sep(x, kp, vp) -- buffer << trailing separator
   buf[#buf + 1] = vfns.close(x) -- buffer << table close
   return concat(buf) -- stringify buffer
end


local function always(x)
   return function(...) return x end
end


local function keysort(a, b)
   if type(a) == 'number' then
      return type(b) ~= 'number' or a < b
   else
      return type(b) ~= 'number' and tostring(a) < tostring(b)
   end
end


local strvtable = {
   open = always '{',
   close = always '}',

   elem = setmetatable({
      ['\a'] = [[\a]],
      ['\b'] = [[\b]],
      ['\t'] = [[\t]],
      ['\n'] = [[\n]],
      ['\v'] = [[\v]],
      ['\f'] = [[\f]],
      ['\r'] = [[\r]],
      ['\\'] = [[\\]],
   }, {
      __call = function(map, x)
         return gsub(tostring(x), '[\a\b\t\n\v\f\r]', function(c)
            return map[c]
         end)
      end,
   }),

   pair = function(x, kp, vp, k, v, kstr, vstr, seqp)
      if seqp then
         return vstr
      end
      return kstr .. '=' .. vstr
   end,

   sep = function(x, kp, vp, k, v, seqp)
      if kp == nil or k == nil then
         return ''
      elseif seqp and type(kp) == 'number' and k ~= kp + 1 then
         return '; '
      end
      return ', '
   end,

   sort = function(keys)
      sort(keys, keysort)
      return keys
   end,

   term = function(x)
      return type(x) ~= 'table' or getmetamethod(x, '__tostring')
   end,
}


local function str(x)
   return render(x, strvtable)
end


local function math_type(x)
   if type(x) ~= 'number' then
      return nil
   end
   return tointeger(x) and 'integer' or 'float'
end


local _unpack = unpack
local function unpack(t, i, j)
   return _unpack(t, tointeger(i) or 1, tointeger(j) or len(t))
end


do
   local have_xpcall_args = false
   local function catch(arg) have_xpcall_args = arg end
   xpcall(catch, function() end, true)

   if not have_xpcall_args then
      local _xpcall = xpcall
      xpcall = function(fn, errh, ...)
         local argu = pack(...)
         return _xpcall(function()
            return fn(unpack(argu, 1, argu.n))
         end, errh)
      end
   end
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local T = types


local F = {
   _VERSION = _G._VERSION,
   arg = _G.arg,

   --- Raise a bad argument error.
   -- Equivalent to luaL_argerror in the Lua C API. This function does not
   -- return.   The `level` argument behaves just like the core `error`
   -- function.
   -- @function argerror
   -- @string name function to callout in error message
   -- @int i argument number
   -- @string[opt] extramsg additional text to append to message inside
   --    parentheses
   -- @int[opt=1] level call stack level to blame for the error
   -- @usage
   --    local function slurp(file)
   --       local h, err = input_handle(file)
   --       if h == nil then
   --           argerror('std.io.slurp', 1, err, 2)
   --       end
   --       ...
   argerror = argscheck(
      'argerror', T.stringy, T.integer, T.accept, opt(T.integer)
   ) .. argerror,

   assert = _G.assert,
   collectgarbage = _G.collectgarbage,
   dofile = _G.dofile,
   error = _G.error,

   --- Get a function or functor environment.
   --
   -- This version of getfenv works on all supported Lua versions, and
   -- knows how to unwrap functors (table's with a function valued
   -- `__call` metamethod).
   -- @function getfenv
   -- @tparam function|int fn stack level, C or Lua function or functor
   --    to act on
   -- @treturn table the execution environment of *fn*
   -- @usage
   --    callers_environment = getfenv(1)
   getfenv = argscheck(
      'getfenv', opt(T.integer, T.callable)
   ) .. normalize_getfenv,

   --- Return named metamethod, if callable, otherwise `nil`.
   -- @function getmetamethod
   -- @param x item to act on
   -- @string n name of metamethod to look up
   -- @treturn function|nil metamethod function, or `nil` if no
   --    metamethod
   -- @usage
   --    normalize = getmetamethod(require 'std.normalize', '__call')
   getmetamethod = argscheck(
      'getmetamethod', T.arg, T.stringy
   ) .. getmetamethod,

   getmetatable = _G.getmetatable,

   --- Iterate over elements of a sequence, until the first `nil` value.
   --
   -- Returns successive key-value pairs with integer keys starting at 1,
   -- up to the index returned by the `__len` metamethod if any, or else
   -- up to last non-`nil` value.
   --
   -- Unlike Lua 5.1, any `__index` metamethod is respected.
   --
   -- Unlike Lua 5.2+, any `__ipairs` metamethod is **ignored**!
   -- @function ipairs
   -- @tparam table t table to iterate on
   -- @treturn function iterator function
   -- @treturn table *t* the table being iterated over
   -- @treturn int the previous iteration index
   -- @usage
   --    t, u = {}, {}
   --    for i, v in ipairs {1, 2, nil, 4} do t[i] = v end
   --    assert(len(t) == 2)
   --
   --    for i, v in ipairs(pack(1, 2, nil, 4)) do u[i] = v end
   --    assert(len(u) == 4)
   ipairs = argscheck('ipairs', T.table) .. ipairs,

   --- Deterministic, functional version of core Lua `#` operator.
   --
   -- Respects `__len` metamethod (like Lua 5.2+), or else if there is
   --   a `__tostring` metamethod return the length of the string it
   -- returns.   Otherwise, always return one less than the lowest
   -- integer index with a `nil` value in *x*, where the `#` operator
   -- implementation might return the size of the array part of a table.
   -- @function len
   -- @param x item to act on
   -- @treturn int the length of *x*
   -- @usage
   --    x = {1, 2, 3, nil, 5}
   --    --> 5 3
   --    print(#x, len(x))
   len = argscheck('len', any(T.table, T.stringy)) .. len,

   --- Load a string or a function, just like Lua 5.2+.
   -- @function load
   -- @tparam string|function ld chunk to load
   -- @string source name of the source of *ld*
   -- @treturn function a Lua function to execute *ld* in global scope.
   -- @usage
   --    assert(load 'print "woo"')()
   load = argscheck(
      'load', any(T.callable, T.stringy), opt(T.stringy)
   ) .. normalize_load,

   loadfile = _G.loadfile,
   next = _G.next,

   --- Return a list of given arguments, with field `n` set to the length.
   --
   -- The returned table also has a `__len` metamethod that returns `n`, so
   -- `ipairs` and `unpack` behave sanely when there are `nil` valued elements.
   -- @function pack
   -- @param ... tuple to act on
   -- @treturn table packed list of *...* values, with field `n` set to
   --    number of tuple elements (including any explicit `nil` elements)
   -- @see unpack
   -- @usage
   --    --> 5
   --    len(pack(nil, 2, 5, nil, nil))
   pack = pack,

   --- Like Lua `pairs` iterator, but respect `__pairs` even in Lua 5.1.
   -- @function pairs
   -- @tparam table t table to act on
   -- @treturn function iterator function
   -- @treturn table *t*, the table being iterated over
   -- @return the previous iteration key
   -- @usage
   --    for k, v in pairs {'a', b='c', foo=42} do process(k, v) end
   pairs = argscheck('pairs', T.table) .. pairs,

   pcall = _G.pcall,
   print = _G.print,
   rawequal = _G.rawequal,
   rawget = _G.rawget,

   --- Length of a string or table object without using any metamethod.
   -- @function rawlen
   -- @tparam string|table x object to act on
   -- @treturn int raw length of *x*
   -- @usage
   --    --> 0
   --    rawlen(setmetatable({}, {__len=function() return 42}))
   rawlen = argscheck('rawlen', any(T.string, T.table)) .. rawlen,

   rawset = _G.rawset,
   select = _G.select,

   --- Set a function or functor environment.
   --
   -- This version of setfenv works on all supported Lua versions, and
   -- knows how to unwrap functors.
   -- @function setfenv
   -- @tparam function|int fn stack level, C or Lua function or functor
   --    to act on
   -- @tparam table env new execution environment for *fn*
   -- @treturn function function acted upon
   -- @usage
   --    function clearenv(fn) return setfenv(fn, {}) end
   setfenv = argscheck(
      'setfenv', any(T.integer, T.callable), T.table
   ) .. normalize_setfenv,

   setmetatable = _G.setmetatable,

   --- Return a compact stringified representation of argument.
   -- @function str
   -- @param x item to act on
   -- @treturn string compact string representing *x*
   -- @usage
   --    -- {baz,5,foo=bar}
   --    print(str{foo='bar','baz', 5})
   str = str,

   tonumber = _G.tonumber,
   tostring = _G.tostring,
   type = _G.type,

   --- Either `table.unpack` in newer-, or `unpack` in older Lua implementations.
   -- @function unpack
   -- @tparam table t table to act on
   -- @int[opt=1] i first index to unpack
   -- @int[opt=len(t)] j last index to unpack
   -- @return ... values of numeric indices of *t*
   -- @see pack
   -- @usage
   --    local a, b, c = unpack(pack(nil, 2, nil))
   --    assert(a == nil and b == 2 and c == nil)
   unpack = argscheck(
      'unpack', T.table, opt(T.integer), opt(T.integer)
   ) .. unpack,

   --- Support arguments to a protected function call, even on Lua 5.1.
   -- @function xpcall
   -- @tparam function f protect this function call
   -- @tparam function errh error object handler callback if *f* raises
   --    an error
   -- @param ... arguments to pass to *f*
   -- @treturn[1] boolean `false` when `f(...)` raised an error
   -- @treturn[1] string error message
   -- @treturn[2] boolean `true` when `f(...)` succeeded
   -- @return ... all return values from *f* follow
   -- @usage
   --    -- Use errh to get a backtrack after curses exits abnormally
   --    xpcall(main, errh, arg, opt)
   xpcall = argscheck('xpcall', T.callable, T.callable) .. xpcall,
}

local G = {
   coroutine = {
      create = _G.coroutine.create,
      resume = _G.coroutine.resume,
      running = _G.coroutine.running,
      status = _G.coroutine.status,
      wrap = _G.coroutine.wrap,
      yield = _G.coroutine.yield,
   },
   debug = {
      debug = _G.debug.debug,
      gethook = _G.debug.gethook,
      getinfo = _G.debug.getinfo,
      getlocal = _G.debug.getlocal,
      getmetatable = _G.debug.getmetatable,
      getregistry = _G.debug.getregistry,
      getupvalue = _G.debug.getupvalue,
      getuservalue = _G.debug.getuservalue,
      sethook = _G.debug.sethook,
      setmetatable = _G.debug.setmetatable,
      setupvalue = _G.debug.setupvalue,
      setuservalue = _G.debug.setuservalue,
      traceback = _G.debug.traceback,
      upvalueid = _G.debug.upvalueid,
      upvaluejoin = _G.debug.upvaluejoin,
   },
   io = {
      close = _G.io.close,
      flush = _G.io.flush,
      input = _G.io.input,
      lines = _G.io.lines,
      open = _G.io.open,
      output = _G.io.output,
      popen = _G.io.popen,
      read = _G.io.read,
      stderr = _G.io.stderr,
      stdin = _G.io.stdin,
      stdout = _G.io.stdout,
      tmpfile = _G.io.tmpfile,
      type = _G.io.type,
      write = _G.io.write,
   },
   math = {
      abs = _G.math.abs,
      acos = _G.math.acos,
      asin = _G.math.asin,
      atan = _G.math.atan,
      ceil = _G.math.ceil,
      cos = _G.math.cos,
      deg = _G.math.deg,
      exp = _G.math.exp,
      floor = _G.math.floor,
      fmod = _G.math.fmod,
      huge = _G.math.huge,
      log = _G.math.log,
      max = _G.math.max,
      min = _G.math.min,
      modf = _G.math.modf,
      pi = _G.math.pi,
      rad = _G.math.rad,
      random = _G.math.random,
      randomseed = _G.math.randomseed,
      sin = _G.math.sin,
      sqrt = _G.math.sqrt,
      tan = _G.math.tan,

      --- Convert to an integer and return if possible, otherwise `nil`.
      -- @function math.tointeger
      -- @param x object to act on
      -- @treturn[1] integer *x* converted to an integer if possible
      -- @return[2] `nil` otherwise
      tointeger = argscheck('tointeger', T.arg) .. tointeger,

      --- Return 'integer', 'float' or `nil` according to argument type.
      --
      -- To ensure the same behaviour on all host Lua implementations,
      -- this function returns 'float' for integer-equivalent floating
      -- values, even on Lua 5.3.
      -- @function math.type
      -- @param x object to act on
      -- @treturn[1] string 'integer', if *x* is a whole number
      -- @treturn[2] string 'float', for other numbers
      -- @return[3] `nil` otherwise
      type = argscheck('type', T.arg) .. math_type,
   },
   os = {
      clock = _G.os.clock,
      date = _G.os.date,
      difftime = _G.os.difftime,
      execute = _G.os.execute,

      --- Exit the program.
      -- @function os.exit
      -- @tparam bool|number[opt=true] status report back to parent process
      -- @usage
      --    exit(len(records.processed) > 0)
      exit = argscheck('exit', any(T.boolean, T.integer, T.missing)) .. exit,

      getenv = _G.os.getenv,
      remove = _G.os.remove,
      rename = _G.os.rename,
      setlocale = _G.os.setlocale,
      time = _G.os.time,
      tmpname = _G.os.tmpname,
   },
   package = {
      config = _G.package.config,
      cpath = _G.package.cpath,

      --- Package module constants for `package.config` substrings.
      -- @table package
      -- @string dirsep directory separator in path elements
      -- @string execdir replaced by the executable's directory in a path
      -- @string igmark ignore everything before this when building
      --    `luaopen_` function name
      -- @string pathmark mark substitution points in a path template
      -- @string pathsep element separator in a path template
      dirsep = dirsep,
      execdir = execdir,
      igmark = igmark,
      pathmark = pathmark,
      pathsep = pathsep,

      loadlib = _G.package.loadlib,
      path = _G.package.path,
      preload = _G.package.preload,
      searchers = _G.package.searchers or _G.package.loaders,

      --- Searches for a named file in a given path.
      --
      -- For each `package.pathsep` delimited template in the given path,
      -- search for an readable file made by first substituting for *sep*
      -- with `package.dirsep`, and then replacing any
      -- `package.pathmark` with the result.   The first such file, if any
      -- is returned.
      -- @function package.searchpath
      -- @string name name of search file
      -- @string path `package.pathsep` delimited list of full path templates
      -- @string[opt='.'] sep *name* component separator
      -- @string[opt=`package.dirsep`] rep *sep* replacement in template
      -- @treturn[1] string first template substitution that names a file
      --    that can be opened in read mode
      -- @return[2] `nil`
      -- @treturn[2] string error message listing all failed paths
      searchpath = argscheck(
         'searchpath', T.string, T.string, opt(T.string), opt(T.string)
      ) .. searchpath,
   },
   string = {
      byte = _G.string.byte,
      char = _G.string.char,
      dump = _G.string.dump,
      find = _G.string.find,
      format = _G.string.format,
      gmatch = _G.string.gmatch,
      gsub = _G.string.gsub,
      lower = _G.string.lower,
      match = _G.string.match,
      rep = _G.string.rep,

      --- Low-level recursive data to string rendering.
      -- @function string.render
      -- @param x data to be renedered
      -- @tparam RenderFns vfns table of virtual functions to control rendering
      -- @tparam[opt] table roots used internally for cycle detection
      -- @treturn string a text recursive rendering of *x* using *vfns*
      -- @usage
      --    function printarray(x)
      --       return render(x, arrayvfns)
      --    end
      render = argscheck('render', T.accept, T.table, opt(T.table)) .. render,

      reverse = _G.string.reverse,
      sub = _G.string.sub,
      upper = _G.string.upper,
   },
   table = {
      concat = _G.table.concat,
      insert = _G.table.insert,

      --- Return an unordered list of all keys in a table.
      -- @function table.keys
      -- @tparam table t table to operate on
      -- @treturn table an unorderd list of keys in *t*
      -- @usage
      --    --> {'key2', 1, 42, 2, 'key1'}
      --    keys{'a', 'b', key1=1, key2=2, [42]=3}
      keys = argscheck('keys', T.table) .. keys,

      --- Destructively merge keys and values from one table into another.
      -- @function table.merge
      -- @tparam table t take fields from this table
      -- @tparam[opt={}] table u and copy them into here, unless they are set already
      -- @treturn table *u*
      -- @usage
      --    --> {'a', 'b', d='d'}
      --    merge({'a', 'b'}, {'c', d='d'})
      merge = argscheck('merge', T.table, opt(T.table)) .. merge,

      remove = _G.table.remove,
      sort = _G.table.sort,
   },
}
F._G = G
G.package.loaded = {
   _G = G,
   coroutine = G.coroutine,
   debug = G.debug,
   io = G.io,
   math = G.math,
   os = G.os,
   package = G.package,
   string = G.string,
   table = G.table,
}
for k, v in next, _G.package.loaded do
   G.package.loaded[k] = G.package.loaded[k] or v
end
F.require = function(modname)
   return G.package.loaded[modname] or _G.require(modname)
end
for k, v in next, F do
   G[k] = G[k] or v
end


local function split(s, matching)
   local r = {}
   gsub(s, matching, function(segment)
      r[#r + 1] = segment
   end)
   return r
end


-- Dereference table *env* with *keylist* making missing subtables as we go.
-- The last element of *keylist* is assumed to be the final key at which
-- some value will be loaded, and is not followed, but is the second return
-- value.
-- @tparam table env environment table to start from
-- @tparam table keylist a list of subtables to recursively walk from *env*
-- @treturn table innermost table having followed *keylist* from *env*
-- @treturn string the last element of *keylist*
local function mksubtables(env, keylist)
   while #keylist > 1 do
      local subkey = remove(keylist, 1)
      env[subkey] = env[subkey] or {}
      env = env[subkey]
   end
   keylist = remove(keylist, 1)
   return env, keylist
end


-- Return dot-delimited segments of elements of t between indexes i and j.
-- @tparam table t a list of segments
-- @int i first element to return
-- @int j last element to return
-- @treturn string selected segments of *t* concatenated with '.'s between
local function slice(t, i, j)
   return concat({unpack(t, i, j)}, '.')
end


-- Convert a string into a loadable module, optionally followed by table keys.
-- Initially with the whole of *spec* as a module name, then splitting *spec*
-- at each dot from right to left, search for a module named after the left
-- half and containing nested keys named after the right half, and return
-- that.
-- @string spec dot delimited symbol name to import
-- @int level call depth for error message stack traces
-- @return value of a module, after dereferencing optional following
--    table keys
local function stringimport(spec, level)
   local v = split(spec, '[^%.]+')
   local vlen, err = #v, {}

   for i = vlen, 1, -1 do
      local module, j = slice(v, 1, i), i + 1
      local ok, pkg = pcall(G.require, module)
      if not ok then
         err[#err + 1] = pkg
      else
         while pkg ~= nil and j <= vlen do
            local subkey = v[j]
            pkg, j = pkg[subkey], j + 1
         end
         if pkg == nil then
            err[#err + 1] = format(
               "\tno entry for '%s' in module '%s'", slice(v, i + 1, vlen), module
            )
         else
            return pkg
         end
      end
   end
   error(concat(err, '\n'), level + 1)
end


-- Import value into name key of env table.
-- String values are replaced by the equivalent symbol they name in the
-- normalized module table, except that strings assigned to ALLCAPS names
-- are treated as string constants and not looked up as module symbols.
-- @tparam table env environment table
-- @string name key to index into *env*
-- @param value value to store at *name* in *env*
-- @int level call depth for error message stack traces
-- @treturn table modified *env*
local function import(env, name, value, level)
   local i = tointeger(name)
   if i and type(value) == 'string' then
      name = match(value, '[^%.]+$')
      if name == nil then
         error(
           "could not infer name from module '" .. value .. "' at #" .. i,
           level + 1
         )
      end
   end

   local dst, k = mksubtables(env, split(name, '[^%.]+'))
   if type(value) == 'string' and (i or upper(name) ~= name) then
      value = stringimport(value, level + 1)
   end
   dst[k] = value
   return env
end


-- Replace host Lua functions with normalized equivalents.
-- @tparam table userenv user's lexical environment table
-- @treturn table *userenv* with normalized functions
local function normalize(userenv, level)
   -- Top level functions are always available.
   local env = shallow_copy(F)

   -- Everything else must be requested by name.
   for name, value in next, userenv do
      env = import(env, name, value, level + 1)
   end

   return env
end


return setmetatable(G, {
   --- Metamethods
   -- @section metamethods

   --- Normalize caller's lexical environment.
   --
   -- Using 'std.strict' when available and selected, otherwise a (Lua 5.1
   -- compatible) function to set the given environment.
   --
   -- With an empty table argument, the core (not-table) normalize
   -- functions are loaded into the callers environment.   For consistent
   -- behaviour between supported host Lua implementations, the result
   -- must always be assigned back to `_ENV`.   Additional core modules
   -- must be named to be loaded at all (i.e. no 'debug' table unless it
   -- is explicitly listed in the argument table).
   --
   -- Additionally, external modules are loaded using `require`, with `.`
   -- separators in the module name translated to nested tables in the
   -- module environment. For example 'std.prototype' in the usage below
   -- will add to the environment table the equivalent of:
   --
   --       local prototype = require 'std.prototype'
   --
   -- Alternatively, you can assign a loaded module symbol to a specific
   -- environment table symbol with `key=value` syntax.   For example the
   -- the 'math.tointeger' from the usage below is equivalent to:
   --
   --       local int = require 'std.normalize.math'.tointeger
   --
   -- Compare this to loading the non-normalized implementation from the
   -- host Lua with a table entry such as:
   --
   --       int = require 'math'.tointeger,
   --
   -- Finally, explicit string assignment to ALLCAPS keys are not loaded
   -- from modules at all, but behave as a constant string assignment:
   --
   --       INT = 'math.tointeger',
   -- @function __call
   -- @tparam table env environment table
   -- @tparam[opt=1] int level stack level for `setfenv`, 1 means set
   --    caller's environment
   -- @treturn table *env* with this module's functions merge id.   Assign
   --    back to `_ENV`
   -- @usage
   --    local _ENV = require 'std.normalize' {
   --       'string',
   --       'std.prototype',
   --       int = 'math.tointeger',
   --    }
   __call = function(_, env, level)
      level = 1 + (level or 1)
      return strict(normalize(env, level), level), nil
   end,

   --- Lazy loading of normalize modules.
   -- Don't load everything on initial startup, wait until first attempt
   -- to access a submodule, and then load it on demand.
   -- @function __index
   -- @string name submodule name
   -- @treturn table|nil the submodule that was loaded to satisfy the missing
   --    `name`, otherwise `nil` if nothing was found
   -- @usage
   -- local version = require 'std.normalize'.version
   __index = function(self, name)
      local ok, t = pcall(require, 'std.normalize.' .. name)
      if ok then
         rawset(self, name, t)
         return t
      end
   end,
})


--- Types
-- @section types

--- Table of functions for string.render.
-- @table RenderFns
-- @tfield RenderElem elem return unique string representation of an element
-- @tfield RenderTerm term return true for elements that should not be
--    recursed
-- @tfield RenderSort sort return list of keys in order to be rendered
-- @tfield RenderOpen open return a string for before first element of a table
-- @tfield RenderClose close return a string for after last element of a table
-- @tfield RenderPair pair return a string rendering of a key value pair
--    element
-- @tfield RenderSep sep return a string to render between elements
-- @see string.render
-- @usage
--     arrayvfns = {
--       elem = tostring,
--       term = function(x)
--          return type(x) ~= 'table' or getmetamethod(x, '__tostring')
--       end,
--       sort = function(keys)
--          local r = {}
--          for i = 1, #keys do
--             if type(keys[i]) == 'number' then r[#r + 1] = keys[i] end
--          end
--          return r
--       end,
--       open = function(_) return '[' end,
--       close = function(_) return ']' end,
--       pair = function(x, kp, vp, k, v, kstr, vstr, seqp)
--          return seqp and vstr or ''
--       end,
--       sep = function(x, kp, vp, kn, vn, seqp)
--          return seqp and kp ~= nil and kn ~= nil and ', ' or ''
--       end,
--     )

--- Type of function for uniquely stringifying rendered element.
-- @function RenderElem
-- @param x element to operate on
-- @treturn string stringified *x*

--- Type of predicate function for terminal elements.
-- @function RenderTerm
-- @param x element to operate on
-- @treturn bool true for terminal elements that should be rendered
--    immediately

--- Type of function for sorting keys of a recursively rendered element.
-- @function RenderSort
-- @tparam table keys list of table keys, it's okay to mutate and return
--    this parameter
-- @treturn table sorted list of keys for pairs to be rendered

--- Type of function to get string for before first element.
-- @function RenderOpen
-- @param x element to operate on
-- @treturn string string to render before first element

--- Type of function te get string for after last element.
-- @function RenderClose
-- @param x element to operate on
-- @treturn string string to render after last element

--- Type of function to render a key value pair.
-- @function RenderPair
-- @param x complete table elmeent being operated on
-- @param kp unstringified previous pair key
-- @param vp unstringified previous pair value
-- @param k unstringified pair key to render
-- @param v unstringified pair value to render
-- @param kstr already stringified pair key to render
-- @param vstr already stringified pair value to render
-- @param seqp true if all keys so far have been a contiguous range of
--    integers
-- @treturn string stringified rendering of pair *kstr* and *vstr*

--- Type of function to render a separator between pairs.
-- @function RenderSep
-- @param x complet table element being operated on
-- @param kp unstringified previous pair key
-- @param vp unstringified previous pair value
-- @param kn unstringified next pair key
-- @param vn unstringified next pair value
-- @param seqp true if all keys so far have been a contiguous range of
--    integers
-- @treturn string stringified rendering of separator between previous and
--    next pairs

