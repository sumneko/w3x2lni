-------------------------------------------------
---      *** BitLibEmu for Lua ***            ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local mod   = math.fmod
local floor = math.floor
bit = {}

----------------------------------------

local function cap(x)
	return mod(x,4294967296)
end

----------------------------------------

function bit.bnot(x)
	return 4294967295-cap(x)
end

----------------------------------------

function bit.lshift(x,n)
	return cap(cap(x)*2^n)
end

----------------------------------------

function bit.rshift(x,n)
	return floor(cap(x)/2^n)
end

----------------------------------------

function bit.band(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)==1 and mod(y,2)==1) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end

----------------------------------------

function bit.bor(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)==1 or mod(y,2)==1) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end

----------------------------------------

function bit.bxor(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)~=mod(y,2)) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end
