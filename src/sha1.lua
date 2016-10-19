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
local strunpack = string.unpack
local h0, h1, h2, h3, h4

-------------------------------------------------

local function LeftRotate(val, nr)
	return (val << nr) | ((val & 0xFFFFFFFF) >> (32 - nr))
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
	for n = 1, #str, 64 do
		w[0x01], w[0x02], w[0x03], w[0x04], w[0x05], w[0x06], w[0x07], w[0x08],
		w[0x09], w[0x0A], w[0x0B], w[0x0C], w[0x0D], w[0x0E], w[0x0F], w[0x10]
		= strunpack(('>LLLLLLLLLLLLLLLL'), str, n)
		for i = 17, 80 do
			w[i] = LeftRotate(((w[i - 3] ~ w[i - 8]) ~ (w[i - 14] ~ w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 1, 80 do
			if (i <= 20) then
				f = (b & c) | ((~b) & d)
				k = 1518500249
			elseif (i <= 40) then
				f = ((b ~ c) ~ d)
				k = 1859775393
			elseif (i <= 60) then
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
		h0 = (h0 + a) & 0xFFFFFFFF
		h1 = (h1 + b) & 0xFFFFFFFF
		h2 = (h2 + c) & 0xFFFFFFFF
		h3 = (h3 + d) & 0xFFFFFFFF
		h4 = (h4 + e) & 0xFFFFFFFF
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
