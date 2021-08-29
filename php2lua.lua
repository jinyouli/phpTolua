
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

    local result = ''
    for i = 1, 10, 1 do
        local num = restore:sub(i, i);
        -- 转 ASCII码
        local c = string.byte(num) 

        if c > 47 and c < 58 then
            c = c - 48;
        else 
            if c > 82 then 
                c = c - 1;
            end
            if c > 78 then
                c = c - 1;
            end
            if c > 75 then
                c = c - 1;
            end
            if c > 72 then
                c = c - 1;
            end
            
            c = c - 55;
        end
        result = result .. string.char(c) 
    end

    return result;
end

function bchexdec(hex)
    dec = 0;
    len = #hex;

    for i = 1, len, 1 do
        bcpow = 16;
        m = i - 1;
        n = len - i + 1;

        -- for me = 1, n, 1 do 
        --     bcpow = bcpow * 16;
        -- end
        bcpow = math.pow(16,n)

        local hexStr = hex:sub(m, m);
        num = tonumber(hexStr, 16)

        if num ~= nil then 

            bcmul = num * math.floor(bcpow);
            dec = dec + bcmul;
        end
        
    end

    return string.format("%.0f", dec);
end

function str2hex(str)

	--拼接字符串
	local index=1
	local ret=""
	for index=1,str:len(),1 do
        value = str:sub(index,index)
	    ret = ret .. StringToHex(value)
	end
 
	return ret
end


function StringToHex(str)
    Strlen = string.len(str)
    Hex = 0x0
    for i = 1, Strlen do
        temp = string.byte(str,i)
        if ((temp >= 48) and (temp <= 57)) then
            temp = temp - 48
        elseif ((temp >= 97) and (temp <= 102)) then
            temp = temp - 87
        elseif ((temp >= 65) and (temp <= 70)) then
            temp = temp - 55
        end
        Hex =  Hex + temp*(16^(Strlen-i))
    end
    return (Hex)
end

function encrypt(text)
    local num = 100;
    -- text = str2hex(text)

    atext = '4e15dde09b3dae2657425bd54c71e7a080957ae03038636237626537326462373863666532656237';
    text = bchexdec(atext)
       
    local n =  math.fmod(rsa_mod,math.pow(text,rsa_exp))

    ret = '';
    while (n > 0) 
    do
        a = math.floor(math.fmod(n,256))
        ret = string.char(a) .. ret;
        x = n / 256;
        n = math.floor(x * num + 0.5) / num;
    end
    
    return ret;
end


function decrypt(code, key)
    ret = '';
    for i = 1, #code, 1 do
        local codeStr = code:sub(i, i);
        local keyStr = key:sub(i, i);
        c = string.byte(codeStr);
        k = string.byte(keyStr);

        -- ASCII码 转 字符
        local xor = bit:_xor(c,k)
        ret = ret .. string.char(xor);
    end
    return ret;
end

local sha = require "sha2"
local sha1 = sha.sha1

function create_key(size)
    local rand = math.random(999999);
    return string.sub(sha1(tostring(rand)),0,size);                         
    -- sha1运算随机生成数字后截取指定数量的字节
end



-- ````````````````````````````````````````````````````````````````````````````````````````````

-- @字符串，通过恢复码恢复设备URL
local server = "https://www.battlenet.com.cn";
local restore_uri = "/enrollment/initiatePaperRestore.htm";
local restore_validate_uri = "/enrollment/validatePaperRestore.htm";


orgin = 'CN-2108-1723-2724'
serial = string.gsub(orgin, "-", "")
challenge = 'challenge'

local restore = 'H7Q11XFZ76'
restore_code = restore_code_from_char(restore);

local serialStr = serial .. challenge
local hmac = sha.hmac
local mac = hmac(sha.sha1, restore_code, serialStr)

enc_key = create_key(20);

enc_key = '4e516c1721855e56392e';
mac = 'N???=?&WB[?Lq砀?z?';

data = serial .. encrypt(mac .. enc_key);

response = '7f39809dd70a42a822ff';
data = decrypt(response, enc_key);

print(data)





 

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



