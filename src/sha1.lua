-------------------------------------------------
---      *** BitLibEmu for Lua ***            ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

----------------------------------------

function bnot(x)
	return 4294967295 ~ x
end

----------------------------------------

function lshift(x,n)
	return (x << n) & 4294967295
end

----------------------------------------

function rshift(x,n)
	return (x & 4294967295) >> n
end

----------------------------------------

function band(x,y)
	return (x & y) & 4294967295
end

----------------------------------------

function bor(x,y)
	return (x | y) & 4294967295
end

----------------------------------------

function bxor(x,y)
	return (x ~ y) & 4294967295
end


-------------------------------------------------
---      *** SHA-1 algorithm for Lua ***      ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local h0, h1, h2, h3, h4

-------------------------------------------------

local function LeftRotate(val, nr)
	return lshift(val, nr) + rshift(val, 32 - nr)
end

-------------------------------------------------

local function ToHex(num)
	local i, d
	local str = ""
	for i = 1, 8 do
		d = num & 15
		if (d < 10) then
			str = strchar(d + 48) .. str
		else
			str = strchar(d + 87) .. str
		end
		num = num // 16
	end
	return str
end

-------------------------------------------------

local function PreProcess(str)
	local bitlen, i
	local str2 = ""
	bitlen = #str * 8
	str = str .. strchar(128)
	i = 56 - (#str & 63)
	if (i < 0) then
		i = i + 64
	end
	for i = 1, i do
		str = str .. strchar(0)
	end
	for i = 1, 8 do
		str2 = strchar(bitlen & 255) .. str2
		bitlen = bitlen // 256
	end
	return str .. str2
end

-------------------------------------------------

local function MainLoop(str)
	local a, b, c, d, e, f, k, t
	local i, j
	local w = {}
	while (str ~= "") do
		for i = 0, 15 do
			w[i] = 0
			for j = 1, 4 do
				w[i] = w[i] * 256 + strbyte(str, i * 4 + j)
			end
		end
		for i = 16, 79 do
			w[i] = LeftRotate(((w[i - 3] ~ w[i - 8]) ~ (w[i - 14] ~ w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 0, 79 do
			if (i < 20) then
				f = (b & c) | ((~b) & d)
				k = 1518500249
			elseif (i < 40) then
				f = ((b ~ c) ~ d)
				k = 1859775393
			elseif (i < 60) then
				f = (b & c) | (b & d) | (c & d)
				k = 2400959708
			else
				f = (b ~ c) ~ d
				k = 3395469782
			end
			t = LeftRotate(a, 5) + f + e + k + w[i]	
			e = d
			d = c
			c = LeftRotate(b, 30)
			b = a
			a = t
		end
		h0 = (h0 + a) & 4294967295
		h1 = (h1 + b) & 4294967295
		h2 = (h2 + c) & 4294967295
		h3 = (h3 + d) & 4294967295
		h4 = (h4 + e) & 4294967295
		str = strsub(str, 65)
	end
end

-------------------------------------------------

return function (str)
	str = PreProcess(str)
	h0  = 1732584193
	h1  = 4023233417
	h2  = 2562383102
	h3  = 0271733878
	h4  = 3285377520
	MainLoop(str)
	return  ToHex(h0) ..
		ToHex(h1) ..
		ToHex(h2) ..
		ToHex(h3) ..
		ToHex(h4)
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
