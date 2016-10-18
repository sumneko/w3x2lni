-------------------------------------------------
---      *** BigInteger for Lua ***           ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

---------------------------------------
--- Lua 5.0/5.1/WoW Header ------------
---------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local max     = math.max
local min     = math.min
local floor   = math.floor
local ceil    = math.ceil
local mod     = math.fmod
local getn    = function(t) return #t end
local setn    = function() end
local tinsert = table.insert

---------------------------------------
--- Helper Functions ------------------
---------------------------------------

local function Digit(x,i)					--returns i-th digit or zero
	local d = x[i]						--if out of bounds
	if (d==nil) then
		return 0
	end
	return d
end

---------------------------------------

local function Clean(x)						--remove leading zeros
	local i = getn(x)
	while (i>1 and x[i]==0) do
		x[i] = nil
		i = i-1
	end
	setn(x,i)
end

---------------------------------------
--- String Conversion -----------------
---------------------------------------

local function Hex(i)						--convert number to ascii
	if (i>-1 and i<10) then
		return strchar(48+i)
	end
	if (i>9 and i<16) then
		return strchar(55+i)
	end
	return strchar(48)
end

---------------------------------------

local function Dec(i)						--convert ascii to number
	if (i==nil) then
		return 0
	end
	if (i>47 and i<58) then
		return i-48
	end
	if (i>64 and i<71) then
		return i-55
	end
	if (i>96 and i<103) then
		return i-87
	end
	return 0
end

---------------------------------------

function BigInt_NumToHex(x)					--convert number to hexstring
	local s,i,j,c = ""
	for i = 1,getn(x) do
		c = x[i]
		for j = 1,6 do
			s = Hex(mod(c,16))..s
			c = floor(c/16)
		end
	end
	i = 1
	while (i<strlen(s) and strbyte(s,i)==48) do
		i = i+1
	end
	return strsub(s,i)
end

---------------------------------------

function BigInt_HexToNum(h)					--convert hexstring to number
	local x,i,j = {}
	for i = 1,ceil(strlen(h)/6) do
		x[i] = 0
		for j = 1,6 do
			x[i] = 16*x[i]+Dec(strbyte(h,max(strlen(h)-6*i+j,0)))
		end
	end
	Clean(x)
	return x
end

---------------------------------------
--- Math Functions --------------------
---------------------------------------

function BigInt_Add(x,y)					--add numbers
	local z,l,i,r = {},max(getn(x),getn(y))
	z[1] = 0
	for i = 1,l do
		r = Digit(x,i)+Digit(y,i)+z[i]
		if (r>16777215) then
			z[i] = r-16777216
			z[i+1] = 1
		else
			z[i] = r
			z[i+1] = 0
		end
	end
	Clean(z)
	return z
end

---------------------------------------

function BigInt_Sub(x,y)					--subtract numbers
	local z,l,i,r = {},max(getn(x),getn(y))
	z[1] = 0
	for i = 1,l do
		r = Digit(x,i)-Digit(y,i)-z[i]
		if (r<0) then
			z[i] = r+16777216
			z[i+1] = 1
		else
			z[i] = r
			z[i+1] = 0
		end
	end
	if (z[l+1]==1) then
		return nil
	end
	Clean(z)
	return z
end

---------------------------------------

function BigInt_Mul(x,y)					--multiply numbers
	local z,t,i,j,r = {},{}
	for i = getn(y),1,-1 do
		t[1] = 0
		for j = 1,getn(x) do
			r = x[j]*y[i]+t[j]
			t[j+1] = floor(r/16777216)
			t[j] = r-t[j+1]*16777216
		end
		tinsert(z,1,0)
		z = BigInt_Add(z,t)
	end
	Clean(z)
	return z
end

---------------------------------------

local function Div2(x)						--divide number by 2, (modifies
	local u,v,i = 0						--passed number and returns
	for i = getn(x),1,-1 do					--remainder)
		v = x[i]
		if (u==1) then
			x[i] = floor(v/2)+8388608
		else
			x[i] = floor(v/2)
		end
		u = mod(v,2)
	end
	Clean(x)
	return u
end

---------------------------------------

local function SimpleDiv(x,y)					--divide numbers, result
	local z,u,v,i,j = {},0					--must fit into 1 digit!
	j = 16777216
	for i = 1,getn(y) do					--This function is costly and
		z[i+1] = y[i]					--may benefit most from an
	end							--optimized algorithm!
	z[1] = 0
	for i = 23,0,-1 do
		j = j/2
		Div2(z)
		v = BigInt_Sub(x,z)
		if (v~=nil) then
 			u = u+j
			x = v
		end
	end
	return u,x
end

---------------------------------------

function BigInt_Div(x,y)					--divide numbers
	local z,u,i,v = {},{},getn(x)
	for v = 1,min(getn(x),getn(y))-1 do
		tinsert(u,1,x[i])
		i = i - 1
	end
	while (i>0) do
		tinsert(u,1,x[i])
		i = i - 1
		v,u = SimpleDiv(u,y)
		tinsert(z,1,v)
	end
	Clean(z)
	return z,u
end

---------------------------------------

function BigInt_ModPower(b,e,m)					--calculate b^e mod m
	local t,s,r = {},{1}
	for r = 1,getn(e) do
		t[r] = e[r]
	end
	repeat
		r = Div2(t)
		--print(getn(t))
		if (r==1) then
			r,s = BigInt_Div(BigInt_Mul(s,b),m)
		end
		r,b = BigInt_Div(BigInt_Mul(b,b),m)
	until (getn(t)==1 and t[1]==0)
	return s
end

---------------------------------------
--- ModPower Step Functions -----------
---------------------------------------

function BigInt_MP_StepInit(b,e,m)				--initialize nonblocking ModPower,
	local x,i = {b,{},m,{1},1}				--pass resulting table to StepExec!
	for i = 1,getn(e) do
		x[2][i] = e[i]
	end
	return x
end

---------------------------------------

function BigInt_MP_StepExec(x)					--execute next calculation step,
	local r							--finished if result~=nil.
	if (x[5]==1) then
		x[5] = 2
		r = Div2(x[2])
		if (r==1) then
			r,x[4] = BigInt_Div(BigInt_Mul(x[4],x[1]),x[3])
		end
		return nil
	end
	if (x[5]==2) then
		x[5] = 1
		r,x[1] = BigInt_Div(BigInt_Mul(x[1],x[1]),x[3])
		if (getn(x[2])==1 and x[2][1]==0) then
			x[5] = 0
			return x[4]
		end
		return nil
	end
	return nil
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
