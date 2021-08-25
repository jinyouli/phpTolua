
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



secretValue = 'c21f1ac3611de25abf25984ab7e85c47b3791a2c'

secret = hex2bin(secretValue)
current_time = os.time() * 1000
waitingtime = 30000
time = math.floor(current_time / waitingtime)

cycle = tostring(string.format("0x%06X",time))
cycle = string.sub(cycle,3,#cycle)

if #cycle > 8 then
    cycle = string.sub(cycle,#cycle-7,#cycle) 
else
    addnum = 8 - #cycle
    for i=1,addnum,1 do
        cycle = '0' .. cycle
    end
end

hexstr = cycle
str = ''
for i = #hexstr, 0, -2 do  
    local doublebytestr = string.sub(hexstr, i-1, i);  
    local n = tonumber(doublebytestr, 16);  

    if 0 == n or n == nil then  
        str = '\00' .. str  
    else  
        str = string.format("%c", n) .. str  
    end
end 

size = 8 - #str
for i = 1, size, 1 do  
    str = '\00' .. str
end 

local sha = require "sha2"
local hmac = sha.hmac
local mac = hmac(sha.sha1, secret, str)

local num = string.sub(mac, 40, 40);
local start = tonumber(num, 16) * 2 + 1;

mac_part = string.sub(mac, start, start + 7);
code = math.floor(bit:_and(tonumber(mac_part, 16),0x7fffffff))
result = tostring(code)

if #result > 8 then
    result = string.sub(result, #result - 7, #result);
else
    restNum = 7 - #result
    for i = 0, restNum, 1 do  
        result = '0' .. result
    end  
end

print(result)



