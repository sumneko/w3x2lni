-------------------------------------------------
---      *** SHA-1 algorithm for Lua ***      ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local floor   = math.floor
local bnot    = bit.bnot
local band    = bit.band
local bor     = bit.bor
local bxor    = bit.bxor
local shl     = bit.lshift
local shr     = bit.rshift
local h0, h1, h2, h3, h4

-------------------------------------------------

local function LeftRotate(val, nr)
	return shl(val, nr) + shr(val, 32 - nr)
end

-------------------------------------------------

local function ToHex(num)
	local i, d
	local str = ""
	for i = 1, 8 do
		d = band(num, 15)
		if (d < 10) then
			str = strchar(d + 48) .. str
		else
			str = strchar(d + 87) .. str
		end
		num = floor(num / 16)
	end
	return str
end

-------------------------------------------------

local function PreProcess(str)
	local bitlen, i
	local str2 = ""
	bitlen = strlen(str) * 8
	str = str .. strchar(128)
	i = 56 - band(strlen(str), 63)
	if (i < 0) then
		i = i + 64
	end
	for i = 1, i do
		str = str .. strchar(0)
	end
	for i = 1, 8 do
		str2 = strchar(band(bitlen, 255)) .. str2
		bitlen = floor(bitlen / 256)
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
			w[i] = LeftRotate(bxor(bxor(w[i - 3], w[i - 8]), bxor(w[i - 14], w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 0, 79 do
			if (i < 20) then
				f = bor(band(b, c), band(bnot(b), d))
				k = 1518500249
			elseif (i < 40) then
				f = bxor(bxor(b, c), d)
				k = 1859775393
			elseif (i < 60) then
				f = bor(bor(band(b, c), band(b, d)), band(c, d))
				k = 2400959708
			else
				f = bxor(bxor(b, c), d)
				k = 3395469782
			end
			t = LeftRotate(a, 5) + f + e + k + w[i]	
			e = d
			d = c
			c = LeftRotate(b, 30)
			b = a
			a = t
		end
		h0 = band(h0 + a, 4294967295)
		h1 = band(h1 + b, 4294967295)
		h2 = band(h2 + c, 4294967295)
		h3 = band(h3 + d, 4294967295)
		h4 = band(h4 + e, 4294967295)
		str = strsub(str, 65)
	end
end

-------------------------------------------------

function Sha1(str)
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
