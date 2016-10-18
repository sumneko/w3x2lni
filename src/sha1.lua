(function()
	local exepath = package.cpath:sub(1, package.cpath:find(';')-6)
	package.path = package.path .. ';' .. exepath .. '..\\?.lua'
end)()

require 'luabind'
require 'filesystem'
require 'utility'


require "sha1.BitLibEmu"
require "sha1.Sha1"
require "sha1.BigInt"

local rootpath = fs.get(fs.DIR_EXE):remove_filename():remove_filename():remove_filename()
local sha1_dir = rootpath / 'src' / 'sha1'

local function load_public(str)
    local tbl = {}
    for line in str:gmatch '[^\r\n]+' do
        tbl[#tbl+1] = line
    end
    return tbl[1], tbl[2]
end

local function encrypt(c, e_bn, n_bn)
    local c_bn = BigInt_HexToNum(c)
    local m_bn = BigInt_ModPower(c_bn, e_bn, n_bn)
    return BigInt_NumToHex(m_bn)
end

local function decrypt(m, d_bn, n_bn)
    local m_bn = BigInt_HexToNum(m)
    local c_bn = BigInt_ModPower(m_bn, d_bn, n_bn)
    return BigInt_NumToHex(c_bn)
end

local function get_sign(content, d_bn, n_bn)
    return decrypt(Sha1(content), d_bn, n_bn)
end

local function check_sign(content, sign, e_bn, n_bn)
    return Sha1(content) == encrypt(sign, e_bn, n_bn)
end

local function main()
    local d = io.load(sha1_dir / 'ppk')
    if not d then
        print('没有私钥')
        return
    end

    local e, n = load_public(io.load(sha1_dir / 'pub'))
    print('d =', d)
    print('e =', e)
    print('n =', n)

    local d_bn = BigInt_HexToNum(d)
    local e_bn = BigInt_HexToNum(e)
    local n_bn = BigInt_HexToNum(n)

    local m = '测试文本'
    
    print('')
    print('')
    print('输入文件的sha1如下')
    print(Sha1(m))

    print('')
    print('')
    print('开始计算签名')
    local sign = get_sign(m, d_bn, n_bn)
    print('签名计算完毕')
    print(sign)

    print('')
    print('')
    print('开始验证签名')
    print(check_sign(m, sign, e_bn, n_bn))
end

main()



