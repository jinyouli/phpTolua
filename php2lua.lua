
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


function hex2str(hex)
	--判断输入类型
	if (type(hex)~="string") then
		return nil,"hex2str invalid input type"
	end
	--拼接字符串
	local index=1
	local ret=""
	for index=1,hex:len() do
		ret=ret..string.format("%02X",hex:sub(index):byte())
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

function byte2bin(n)
    local t = {}
    for i=42,0,-1 do
        t[#t+1] = math.floor(n / 2^i)
        n = n % 2^i
    end
    return table.concat(t)
end

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



secret = hex2bin('c21f1ac3611de25abf25984ab7e85c47b3791a2c')
current_time = os.time() * 1000
waitingtime = 30000
time = math.floor(current_time / waitingtime)
time = 1629804213799


cycle = tostring(string.format("0x%06X",time))

if #cycle > 10 then
    cycle = string.sub(cycle,#cycle-7,#cycle) 
else
    cycle = string.sub(cycle,#cycle-3,#cycle)
    addnum = 8 - #cycle
    for i=1,addnum,1 do
        cycle = '0' .. cycle
    end
end

hexstr = cycle
str = ''
for i = #hexstr, 0, -2 do  
    local doublebytestr = string.sub(hexstr, i-1, i);  
    print(doublebytestr)
    print('..')

    

    local n = tonumber(doublebytestr, 16);  



    if 0 == n or n == nil then  
        str = '\00' .. str  
    else  
        str = string.format("%c", n) .. str  
    end
end 

print(str)

print('..')
print((tostring(cycle)))
print(#str)
print('..')

-- local str = ""
-- str = str .. '\00'
-- str = str .. '\00'
-- str = str .. '\00'
-- str = str .. '\00'
-- str = str .. string.format("%c", 3)
-- str = str .. string.format("%c", 60)
-- str = str .. string.format("%c", 222)
-- str = str .. string.format("%c", 200)

-- str = '\00' ..'\00' .. '\00' .. '\00' .. '\00' .. str



local sha = require "sha2"
local hmac = sha.hmac
-- local your_hmac = hmac(sha.sha1, secret, cycle) 
local your_hmac = hmac(sha.sha1, secret, str)
print('..')
print(your_hmac)

-- aa2edf176cb2e38a0a78bdbfe7275154fede16e3

mac_part = 'ab38fa16'
print(tonumber(mac_part, 16))
print(bit:_and(tonumber(mac_part, 16),0x7fffffff))


















