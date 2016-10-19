(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\?.lua'
end)()

require 'luabind'
require 'filesystem'
require 'utility'

local bignum = require 'bignum'
local _sha1 = require 'sha1'
local uni = require 'unicode'

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local rsa_dir = rootpath / 'src' / 'rsa'

local function load_public(str)
    local tbl = {}
    for line in str:gmatch '[^\r\n]+' do
        tbl[#tbl+1] = line
    end
    return tbl[1], tbl[2]
end

local function str2bn(str)
    local bn = {}
    for i = #str / 2, 1, -1 do
        local x = str:sub(i*2-1, i*2)
        bn[#bn+1] = load('return 0x'..x)()
    end
    return string.char(table.unpack(bn))
end

local function bn2str(bn)
    local str = {}
    for i = #bn, 1, -1 do
        str[#str+1] = ('%02X'):format(bn:sub(i, i):byte())
    end
    return table.concat(str)
end

local function sha1(str)
    return str2bn(_sha1(str))
end

local rsa = {}

function rsa:init(e, n, d)
    self.e_bn = bignum(str2bn(e))
    self.n_bn = bignum(str2bn(n))
    self.d_bn = bignum(str2bn(d))
end

function rsa:encrypt(c)
    local c_bn = bignum(c)
    local m_bn = c_bn:powmod(self.e_bn, self.n_bn)
    return tostring(m_bn)
end

function rsa:decrypt(m)
    local m_bn = bignum(m)
    local c_bn = m_bn:powmod(self.d_bn, self.n_bn)
    return tostring(c_bn)
end

--生成签名
--	文本
function rsa:get_sign(content)
	return self:decrypt(content)
end

--验证签名
--	文本
--	签名
function rsa:check_sign(content, sign)
	return content == self:encrypt(sign)
end

local function main()
    if not arg[1] then
        print('把要签名的文件拖到bat中')
        return
    end

    local d = io.load(rsa_dir / 'ppk')
    if not d then
        print('没有私钥')
        return
    end

    local e, n = load_public(io.load(rsa_dir / 'pub'))
    print('e =', e)
    print('n =', n)
    print('d =', d)

    rsa:init(e, n, d)

    local filepath = fs.path(uni.a2u(arg[1]))
    local m = io.load(filepath)
    if not m then
        print('文件读取失败', filepath:string())
        return
    end

    print('测试sha1算法')
    if sha1('156498461560') == str2bn('98CA2D94F68F3373E545017C3A17B72400BE00E2') then
        print('测试通过')
    else
        print('sha1算法错误')
        print(bn2str(sha1('156498461560')))
        return
    end

    print('')
    print('')
    print('输入文件的sha1如下')
    local sha1 = sha1(m)
    print(bn2str(sha1))

    print('')
    print('')
    print('开始计算签名')
    local sign = rsa:get_sign(sha1)
    print('签名计算完毕')
    print(bn2str(sign))

    print('')
    print('')
    print('开始验证签名')
    print(rsa:check_sign(sha1, sign))

    print('')
    print('')
    print('生成签名')
    io.save(fs.path(filepath:string() .. '.sign'), sign)
    print('用时', os.clock(), '秒')
end

main()



