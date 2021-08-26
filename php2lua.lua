
local bit={data32={}}
for i=1,32 do
    bit.data32[i]=2^(32-i)
end

function bit:d2b(arg)
    local   tr={}
    for i=1,32 do
        if arg >= self.data32[i] then
        tr[i]=1
        arg=arg-self.data32[i]
        else
        tr[i]=0
        end
    end
    return   tr
end   --bit:d2b

function    bit:b2d(arg)
    local   nr=0
    for i=1,32 do
        if arg[i] ==1 then
        nr=nr+2^(32-i)
        end
    end
    return  nr
end   --bit:b2d

function    bit:_xor(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}

    for i=1,32 do
        if op1[i]==op2[i] then
            r[i]=0
        else
            r[i]=1
        end
    end
    return  self:b2d(r)
end --bit:xor

function    bit:_and(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}
    
    for i=1,32 do
        if op1[i]==1 and op2[i]==1  then
            r[i]=1
        else
            r[i]=0
        end
    end
    return  self:b2d(r)
    
end --bit:_and

function    bit:_or(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}
    
    for i=1,32 do
        if  op1[i]==1 or   op2[i]==1   then
            r[i]=1
        else
            r[i]=0
        end
    end
    return  self:b2d(r)
end --bit:_or

function    bit:_not(a)
    local   op1=self:d2b(a)
    local   r={}

    for i=1,32 do
        if  op1[i]==1   then
            r[i]=0
        else
            r[i]=1
        end
    end
    return  self:b2d(r)
end --bit:_not



function hex2bin( hexstr )
	local str = ""
    for i = 1, string.len(hexstr) - 1, 2 do  
    	local doublebytestr = string.sub(hexstr, i, i+1);  
    	local n = tonumber(doublebytestr, 16);  
    	if 0 == n then  
        	str = str .. '\00'
    	else  
        	str = str .. string.format("%c", n)
    	end
    end 
    return str
end


-- `````````````````````````````````````````````````

local rsa_mod = "104890018807986556874007710914205443157030159668034197186125678960287470894290830530618284943118405110896322835449099433232093151168250152146023319326491587651685252774820340995950744075665455681760652136576493028733914892166700899109836291180881063097461175643998356321993663868233366705340758102567742483097";
local rsa_exp = '257';
local keysize = 1024;

function restore_code_from_char(restore)
{
    for (i = 0; i < 10; ++i) {
        local num = string.sub(restore, i, i);
        -- 转 ASCII码
        local c = string.byte(num) 

        if (c > 47 && c < 58)
            c -= 48;
        else {
            if (c > 82)
                --$c; // S
            if (c > 78)
                --$c; // O
            if (c > 75)
                --$c; // L
            if (c > 72)
                --$c; // I
            c -= 55;
        }
        restore = string.sub(restore,0,i) .. string.char(c) .. string.sub(restore,i,#cycle)
    }
    return restore;
}

function bchexdec(hex)
{
    dec = 0;
    len = #hex;
    for (i = 1; i <= len; i++)
        bcpow = 16;
        for (m = 0; m<(len - i); m++) {
            bcpow = bcpow * 16;
        }
        local hexStr = string.sub(code, i-1, i-1);

        dec = bcadd(dec, bcmul(tostring(tonumber(string,format("0x%06X",hexStr),10)), bcpow));
    return dec;
}

function str2hex(str)
	--判断输入类型	
	if (type(str)~="string") then
	    return nil,"str2hex invalid input type"
	end
	--滤掉分隔符
	str=str:gsub("[%s%p]",""):upper()
	--检查内容是否合法
	if(str:find("[^0-9A-Fa-f]")~=nil) then
	    return nil,"str2hex invalid input content"
	end
	--检查字符串长度
	if(str:len()%2~=0) then
	    return nil,"str2hex invalid input lenth"
	end
	--拼接字符串
	local index=1
	local ret=""
	for index=1,str:len(),2 do
	    ret=ret..string.char(tonumber(str:sub(index,index+1),16))
	end
 
	return ret
end

function encrypt(text)
{
    num = 100;
    text = tonumber(str2hex(text), 16);
    local cover = text ^ rsa_exp;
    n = cover % rsa_mod;
    ret = '';
    while (n > 0) {
        ret = string.char(n % 256) .. ret;
        x = n / 256;
        n = math.floor(x * num + 0.5) / num;
    }
    return ret;
}


function decrypt(code, key)
{
    ret = '';
    for (i = 0; i < #code; ++i) {

        local codeStr = string.sub(code, i, i);
        local keyStr = string.sub(key, i, i);
        c = string.byte(codeStr);
        k = string.byte(keyStr);

        -- ASCII码 转 字符
        local xor = bit:_xor(c,k)
        ret = ret .. string.char(xor);
    }
    return ret;
}

function create_key(size)
{
    local rand = random(999999);
    return string.sub(sha1(rand),0,size);                         
    -- sha1运算随机生成数字后截取指定数量的字节
}

-- @字符串，通过恢复码恢复设备URL

local server = "https://www.battlenet.com.cn";
local restore_uri = "/enrollment/initiatePaperRestore.htm";
local restore_validate_uri = "/enrollment/validatePaperRestore.htm";

orgin = 'CN-2108-1723-2724'
x = string.gsub(orgin, "-", "")
-- print("\n",x);
print(x)
print('...')


local restore = 'H7Q11XFZ76'
local q_sourcestr = string.format("%q", restore)
local upperstr = string.upper(q_sourcestr);
print(upperstr)


enc_key = create_key(20);







 

-- secretValue = 'c21f1ac3611de25abf25984ab7e85c47b3791a2c'

-- secret = hex2bin(secretValue)
-- current_time = os.time() * 1000
-- waitingtime = 30000
-- time = math.floor(current_time / waitingtime)

-- cycle = tostring(string.format("0x%06X",time))
-- cycle = string.sub(cycle,3,#cycle)

-- if #cycle > 8 then
--     cycle = string.sub(cycle,#cycle-7,#cycle) 
-- else
--     addnum = 8 - #cycle
--     for i=1,addnum,1 do
--         cycle = '0' .. cycle
--     end
-- end

-- hexstr = cycle
-- str = ''
-- for i = #hexstr, 0, -2 do  
--     local doublebytestr = string.sub(hexstr, i-1, i);  
--     local n = tonumber(doublebytestr, 16);  

--     if 0 == n or n == nil then  
--         str = '\00' .. str  
--     else  
--         str = string.format("%c", n) .. str  
--     end
-- end 

-- size = 8 - #str
-- for i = 1, size, 1 do  
--     str = '\00' .. str
-- end 

-- local sha = require "sha2"
-- local hmac = sha.hmac
-- local mac = hmac(sha.sha1, secret, str)

-- local num = string.sub(mac, 40, 40);
-- local start = tonumber(num, 16) * 2 + 1;

-- mac_part = string.sub(mac, start, start + 7);
-- code = math.floor(bit:_and(tonumber(mac_part, 16),0x7fffffff))
-- result = tostring(code)

-- if #result > 8 then
--     result = string.sub(result, #result - 7, #result);
-- else
--     restNum = 7 - #result
--     for i = 0, restNum, 1 do  
--         result = '0' .. result
--     end  
-- end

-- print(result)



