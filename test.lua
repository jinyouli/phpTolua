
-- local socket = require("socket")
-- print(socket._VERSION)


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

function    bit:_rshift(a,n)
    local   op1=self:d2b(a)
    local   r=self:d2b(0)
    
    if n < 32 and n > 0 then
        for i=1,n do
            for i=31,1,-1 do
                op1[i+1]=op1[i]
            end
            op1[1]=0
        end
    r=op1
    end
    return  self:b2d(r)
end --bit:_rshift

function    bit:_lshift(a,n)
    local   op1=self:d2b(a)
    local   r=self:d2b(0)
    
    if n < 32 and n > 0 then
        for i=1,n   do
            for i=1,31 do
                op1[i]=op1[i+1]
            end
            op1[32]=0
        end
    r=op1
    end
    return  self:b2d(r)
end --bit:_lshift


function bit:print(ta)
    local sr=""
    for i=1,32 do
		if ta[i] then
        	sr=sr..ta[i]
		end
    end
    print(sr)
end

bs=bit:d2b(7)
bit:print(bs)                          
-->00000000000000000000000000000111
bit:print(bit:d2b(bit:_not(7)))         
-->11111111111111111111111111111000
bit:print(bit:d2b(bit:_rshift(7,2)))    
-->00000000000000000000000000000001
bit:print(bit:d2b(bit:_lshift(7,2)))    
-->00000000000000000000000000011100
print(bit:b2d(bs))                      -->     7
print(bit:_xor(7,2))                    -->     5
print(bit:_and(7,4))                    -->     4
print(bit:_or(5,2))                     -->     7



-- 转成Ascii
function numToAscii(num)
    num = num % 256;
    return string.char(num);
end

-- int转二进制
function int32ToBufStr(num)
    local str = "";
    str = str .. numToAscii(bit:_rshift(num, 24));
    str = str .. numToAscii(bit:_rshift(num, 16));
    str = str .. numToAscii(bit:_rshift(num, 8));
    str = str .. numToAscii(num);
    return str;
end


secret = hex2bin('c21f1ac3611de25abf25984ab7e85c47b3791a2c')

print(secret)


time = 54320248
cycle = int32ToBufStr(time)

print('....')
print(cycle)
print('aaa.....')

function numToHex(num)
    num = num % 256;
    return string.char(num);
end

function bit:connect(ta)
    local sr=""
    for i=1,32 do
		if ta[i] then
        	sr=sr..ta[i]
		end
    end
    return sr
end

function stringTonum(arg)
    local bs = bit:d2b(arg)
    local a = bit:connect(bs)
    return a
end

function bit:d2b2(arg)

    local   tr={}
    tr[0] = stringTonum(bit:_rshift(arg,24));
    tr[1] = stringTonum(bit:_rshift(arg,16));
    tr[2] = stringTonum(bit:_rshift(arg,8));
    tr[3] = stringTonum(arg);
    return  tr
end  

print(table.concat(bit:d2b2(time)))   

cycle = bit:b2d(table.concat(bit:d2b2(time)))

-- void uint32_pack(char *out, uint32 in)
-- {
-- 	out[0] = in&0xff; in>>=8;
-- 	out[1] = in&0xff; in>>=8;
-- 	out[2] = in&0xff; in>>=8;
-- 	out[3] = in&0xff;
-- }


print(cycle)
-- bit:print(bit:d2b(bit:_lshift(time,24)))   
-- print(bit:_lshift(time,24))



local sha = require "sha2"
local hmac = sha.hmac
-- local your_hmac = hmac(sha.sha1, secret, cycle) 
local your_hmac = hmac(sha.sha1, secret, table.concat(bit:d2b2(time)) )
print('your_hash =')
print(your_hmac)

-- 79a3a13ea85d9af13cc5fc96beaf794ab04d221b

















