
-- #!/usr/bin/env lua
-- If this variable is true, then strict type checking is performed for all
-- operations. This may result in slower code, but it will allow you to catch
-- errors and bugs earlier.
local strict = true

--------------------------------------------------------------------------------

local bigint = {}

local named_powers = require("named-powers-of-ten")

-- Create a new bigint or convert a number or string into a big
-- Returns an empty, positive bigint if no number or string is given
function bigint.new(num)
    local self = {
        sign = "+",
        digits = {}
    }

    -- Return a new bigint with the same sign and digits
    function self:clone()
        local newint = bigint.new()
        newint.sign = self.sign
        for _, digit in pairs(self.digits) do
            newint.digits[#newint.digits + 1] = digit
        end
        return newint
    end

    setmetatable(self, {
        __add = function(lhs, rhs)
            return bigint.add(lhs, rhs)
        end,
        __unm = function()
            if (self.sign == "+") then
                self.sign = "-"
            else
                self.sign = "+"
            end
            return self
        end,
        __sub = function(lhs, rhs)
            return bigint.subtract(lhs, rhs)
        end,
        __mul = function(lhs, rhs)
            return bigint.multiply(lhs, rhs)
        end,
        __div = function(lhs, rhs)
            return bigint.divide(lhs, rhs)
        end,
        __mod = function(lhs, rhs)
            local result, remainder = bigint.divide(lhs, rhs)
            return result
        end,
        __pow = function(lhs, rhs)
            return bigint.exponentiate(lhs, rhs)
        end
    })

    if (num) then
        local num_string = tostring(num)
        for digit in string.gmatch(num_string, "[0-9]") do
            table.insert(self.digits, tonumber(digit))
        end
        if string.sub(num_string, 1, 1) == "-" then
            self.sign = "-"
        end
    end

    return self
end

-- Check the type of a big
-- Normally only runs when global variable "strict" == true, but checking can be
-- forced by supplying "true" as the second argument.
function bigint.check(big, force)
    if (strict or force) then
        assert(#big.digits > 0, "bigint is empty")
        assert(type(big.sign) == "string", "bigint is unsigned")
        for _, digit in pairs(big.digits) do
            assert(type(digit) == "number", digit .. " is not a number")
            assert(digit < 10, digit .. " is greater than or equal to 10")
        end
    end
    return true
end

-- Return a new big with the same digits but with a positive sign (absolute
-- value)
function bigint.abs(big)
    bigint.check(big)
    local result = big:clone()
    result.sign = "+"
    return result
end

-- Convert a big to a number or string
function bigint.unserialize(big, output_type, precision)
    bigint.check(big)

    local num = ""
    if big.sign == "-" then
        num = "-"
    end


    if ((output_type == nil)
    or (output_type == "number")
    or (output_type == "n")
    or (output_type == "string")
    or (output_type == "s")) then
        -- Unserialization to a string or number requires reconstructing the
        -- entire number

        for _, digit in pairs(big.digits) do
            num = num .. math.floor(digit) -- lazy way of getting rid of .0$
        end

        if ((output_type == nil)
        or (output_type == "number")
        or (output_type == "n")) then
            return tonumber(num)
        else
            return num
        end

    else
        -- Unserialization to human-readable form or scientific notation only
        -- requires reading the first few digits
        if (precision == nil) then
            precision = 3
        else
            assert(precision > 0, "Precision cannot be less than 1")
            assert(math.floor(precision) == precision,
                   "Precision must be a positive integer")
        end

        -- num is the first (precision + 1) digits, the first being separated by
        -- a decimal point from the others
        num = num .. big.digits[1]
        if (precision > 1) then
            num = num .. "."
            for i = 1, (precision - 1) do
                num = num .. big.digits[i + 1]
            end
        end

        if ((output_type == "human-readable")
        or (output_type == "human")
        or (output_type == "h")) then
            -- Human-readable output contributed by 123eee555

            local name
            local walkback = 0 -- Used to enumerate "ten", "hundred", etc

            -- Walk backwards in the index of named_powers starting at the
            -- number of digits of the input until the first value is found
            for i = (#big.digits - 1), (#big.digits - 4), -1 do
                name = named_powers[i]
                if (name) then
                    if (walkback == 1) then
                        name = "ten " .. name
                    elseif (walkback == 2) then
                        name = "hundred " .. name
                    end
                    break
                else
                    walkback = walkback + 1
                end
            end

            return num .. " " .. name

        else
            return num .. "*10^" .. (#big.digits - 1)
        end

    end
end

-- Basic comparisons
-- Accepts symbols (<, >=, ~=) and Unix shell-like options (lt, ge, ne)
function bigint.compare(big1, big2, comparison)
    bigint.check(big1)
    bigint.check(big2)

    local greater = false -- If big1.digits > big2.digits
    local equal = false

    if (big1.sign == "-") and (big2.sign == "+") then
        greater = false
    elseif (#big1.digits > #big2.digits)
    or ((big1.sign == "+") and (big2.sign == "-")) then
        greater = true
    elseif (#big1.digits == #big2.digits) then
        -- Walk left to right, comparing digits
        for digit = 1, #big1.digits do
            if (big1.digits[digit] > big2.digits[digit]) then
                greater = true
                break
            elseif (big2.digits[digit] > big1.digits[digit]) then
                break
            elseif (digit == #big1.digits)
                   and (big1.digits[digit] == big2.digits[digit]) then
                equal = true
            end
        end

    end

    -- If both numbers are negative, then the requirements for greater are
    -- reversed
    if (not equal) and (big1.sign == "-") and (big2.sign == "-") then
        greater = not greater
    end

    return (((comparison == "<") or (comparison == "lt"))
            and ((not greater) and (not equal)) and true)
        or (((comparison == ">") or (comparison == "gt"))
            and ((greater) and (not equal)) and true)
        or (((comparison == "==") or (comparison == "eq"))
            and (equal) and true)
        or (((comparison == ">=") or (comparison == "ge"))
            and (equal or greater) and true)
        or (((comparison == "<=") or (comparison == "le"))
            and (equal or not greater) and true)
        or (((comparison == "~=") or (comparison == "!=") or (comparison == "ne"))
            and (not equal) and true)
        or false
end

-- BACKEND: Add big1 and big2, ignoring signs
function bigint.add_raw(big1, big2)
    bigint.check(big1)
    bigint.check(big2)

    local result = bigint.new()
    local max_digits = 0
    local carry = 0

    

    if (#big1.digits >= #big2.digits) then
        max_digits = #big1.digits
    else
        max_digits = #big2.digits
    end

    -- Walk backwards right to left, like in long addition
    for digit = 0, max_digits - 1 do
        local sum = (big1.digits[#big1.digits - digit] or 0)
                  + (big2.digits[#big2.digits - digit] or 0)
                  + carry

        if (sum >= 10) then
            carry = 1
            sum = sum - 10
        else
            carry = 0
        end

        result.digits[max_digits - digit] = sum
    end

    -- Leftover carry in cases when #big1.digits == #big2.digits and sum > 10, ex. 7 + 9
    if (carry == 1) then
        table.insert(result.digits, 1, 1)
    end

    return result

end

-- BACKEND: Subtract big2 from big1, ignoring signs
function bigint.subtract_raw(big1, big2)
    -- Type checking is done by bigint.compare
    assert(bigint.compare(bigint.abs(big1), bigint.abs(big2), ">="),
           "Size of " .. bigint.unserialize(big1, "string") .. " is less than "
           .. bigint.unserialize(big2, "string"))

    local result = big1:clone()
    local max_digits = #big1.digits
    local borrow = 0

    -- Logic mostly copied from bigint.add_raw ---------------------------------
    -- Walk backwards right to left, like in long subtraction
    for digit = 0, max_digits - 1 do
        local diff = (big1.digits[#big1.digits - digit] or 0)
                   - (big2.digits[#big2.digits - digit] or 0)
                   - borrow

        if (diff < 0) then
            borrow = 1
            diff = diff + 10
        else
            borrow = 0
        end

        result.digits[max_digits - digit] = diff
    end
    ----------------------------------------------------------------------------


    -- Strip leading zeroes if any, but not if 0 is the only digit
    while (#result.digits > 1) and (result.digits[1] == 0) do
        table.remove(result.digits, 1)
    end

    return result
end

-- FRONTEND: Addition and subtraction operations, accounting for signs
function bigint.add(big1, big2)
    -- Type checking is done by bigint.compare

    local result

    -- print('len1 =');
    -- print(big2);

    -- If adding numbers of different sign, subtract the smaller sized one from
    -- the bigger sized one and take the sign of the bigger sized one
    if (big1.sign ~= big2.sign) then
        if (bigint.compare(bigint.abs(big1), bigint.abs(big2), ">")) then
            result = bigint.subtract_raw(big1, big2)
            result.sign = big1.sign
        else
            result = bigint.subtract_raw(big2, big1)
            result.sign = big2.sign
        end

    elseif (big1.sign == "+") and (big2.sign == "+") then
        result = bigint.add_raw(big1, big2)

    elseif (big1.sign == "-") and (big2.sign == "-") then
        result = bigint.add_raw(big1, big2)
        result.sign = "-"
    end

    return result
end
function bigint.subtract(big1, big2)
    -- Type checking is done by bigint.compare in bigint.add
    -- Subtracting is like adding a negative
    local big2_local = big2:clone()
    if (big2.sign == "+") then
        big2_local.sign = "-"
    else
        big2_local.sign = "+"
    end
    return bigint.add(big1, big2_local)
end

-- BACKEND: Multiply a big by a single digit big, ignoring signs
function bigint.multiply_single(big1, big2)
    bigint.check(big1)
    bigint.check(big2)
    assert(#big2.digits == 1, bigint.unserialize(big2, "string")
                              .. " has more than one digit")

    local result = bigint.new()
    local carry = 0

    -- Logic mostly copied from bigint.add_raw ---------------------------------
    -- Walk backwards right to left, like in long multiplication
    for digit = 0, #big1.digits - 1 do
        local this_digit = big1.digits[#big1.digits - digit]
                         * big2.digits[1]
                         + carry

        if (this_digit >= 10) then
            carry = math.floor(this_digit / 10)
            this_digit = this_digit - (carry * 10)
        else
            carry = 0
        end

        result.digits[#big1.digits - digit] = this_digit
    end

    -- Leftover carry in cases when big1.digits[1] * big2.digits[1] > 0
    if (carry > 0) then
        table.insert(result.digits, 1, carry)
    end
    ----------------------------------------------------------------------------

    return result
end

-- FRONTEND: Multiply two bigs, accounting for signs
function bigint.multiply(big1, big2)
    -- Type checking done by bigint.multiply_single

    local result = bigint.new(0)
    local larger, smaller -- Larger and smaller in terms of digits, not size

    if (bigint.unserialize(big1) == 0) or (bigint.unserialize(big2) == 0) then
        return result
    end

    if (#big1.digits >= #big2.digits) then
        larger = big1
        smaller = big2
    else
        larger = big2
        smaller = big1
    end

    -- Walk backwards right to left, like in long multiplication
    for digit = 0, #smaller.digits - 1 do
        -- Sorry for going over column 80! There's lots of big names here
        local this_digit_product = bigint.multiply_single(larger,
                                                          bigint.new(smaller.digits[#smaller.digits - digit]))

        -- "Placeholding zeroes"
        if (digit > 0) then
            for placeholder = 1, digit do
                table.insert(this_digit_product.digits, 0)
            end
        end

        result = bigint.add(result, this_digit_product)
    end

    if (larger.sign == smaller.sign) then
        result.sign = "+"
    else
        result.sign = "-"
    end

    return result
end


-- Raise a big to a positive integer or big power (TODO: negative integer power)
function bigint.exponentiate(big, power)
    -- Type checking for big done by bigint.multiply
    assert(bigint.compare(power, bigint.new(0), ">"),
           " negative powers are not supported")
    local exp = power:clone()

    if (bigint.compare(exp, bigint.new(0), "==")) then
        return bigint.new(1)
    elseif (bigint.compare(exp, bigint.new(1), "==")) then
        return big
    else
        local result = big:clone()

        while (bigint.compare(exp, bigint.new(1), ">")) do
            result = bigint.multiply(result, big)
            exp = bigint.subtract(exp, bigint.new(1))
        end

        return result
    end

end

-- BACKEND: Divide two bigs (decimals not supported), returning big result and
-- big remainder
-- WARNING: Only supports positive integers
function bigint.divide_raw(big1, big2)
    -- Type checking done by bigint.compare
    if (bigint.compare(big1, big2, "==")) then
        return bigint.new(1), bigint.new(0)
    elseif (bigint.compare(big1, big2, "<")) then
        return bigint.new(0), bigint.new(0)
    else
        assert(bigint.compare(big2, bigint.new(0), "!="), "error: divide by zero")
        assert(big1.sign == "+", "error: big1 is not positive")
        assert(big2.sign == "+", "error: big2 is not positive")

        local result = bigint.new()

        local dividend = bigint.new() -- Dividend of a single operation, not the
                                      -- dividend of the overall function
        local divisor = big2:clone()
        local factor = 1

        -- Walk left to right among digits in the dividend, like in long
        -- division
        for _, digit in pairs(big1.digits) do
            dividend.digits[#dividend.digits + 1] = digit

            -- The dividend is smaller than the divisor, so a zero is appended
            -- to the result and the loop ends
            if (bigint.compare(dividend, divisor, "<")) then
                if (#result.digits > 0) then -- Don't add leading zeroes
                    result.digits[#result.digits + 1] = 0
                end
            else
                -- Find the maximum number of divisors that fit into the
                -- dividend
                factor = 0
                while (bigint.compare(divisor, dividend, "<=")) do
                    divisor = bigint.add(divisor, big2)
                    factor = factor + 1
                end

                -- Append the factor to the result
                if (factor == 10) then
                    -- Fixes a weird bug that introduces a new bug if fixed by
                    -- changing the comparison in the while loop to "<="
                    result.digits[#result.digits] = 1
                    result.digits[#result.digits + 1] = 0
                else
                    result.digits[#result.digits + 1] = factor
                end

                -- Subtract the divisor from the dividend to obtain the
                -- remainder, which is the new dividend for the next loop
                dividend = bigint.subtract(dividend,
                                           bigint.subtract(divisor, big2))

                -- Reset the divisor
                divisor = big2:clone()
            end

        end

        -- The remainder of the final loop is returned as the function's
        -- overall remainder
        return result, dividend
    end
end

-- FRONTEND: Divide two bigs (decimals not supported), returning big result and
-- big remainder, accounting for signs
function bigint.divide(big1, big2)
    local result, remainder = bigint.divide_raw(bigint.abs(big1),
                                                bigint.abs(big2))
    if (big1.sign == big2.sign) then
        result.sign = "+"
    else
        result.sign = "-"
    end

    return result, remainder
end

-- FRONTEND: Return only the remainder from bigint.divide
function bigint.modulus(big1, big2)
    local result, remainder = bigint.divide(big1, big2)

    -- Remainder will always have the same sign as the dividend per C standard
    -- https://en.wikipedia.org/wiki/Modulo_operation#Remainder_calculation_for_the_modulo_operation
    remainder.sign = big1.sign
    return remainder
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


function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function printf(...)
    print(string.format(...))
end

function demo_add(n1, n2)
    printf("bigint.add(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add(bigint.new(n1), bigint.new(n2)), "string")))
end

------------------------------------------------
--name:		bigInt
--create:	2015-4-1
--blog:		blog.csdn.net/xianyun2009
--QQ: 		836663997
--QQ group:	362337463
------------------------------------------------
local mod = 10000

function show(a)
	print(get(a))
end
function get(a)
	s = {a[#a]}
	for i=#a-1, 1, -1 do
		table.insert(s, string.format("%04d", a[i]))
	end
	return table.concat(s, "")
end
function create(s)
	if s["xyBitInt"] == true then return s end
	n, t, a = math.floor(#s/4), 1, {}
	a["xyBitInt"] = true
	if #s%4 ~= 0 then a[n + 1], t = tonumber(string.sub(s, 1, #s%4), 10), #s%4 + 1 end
	for i = n, 1, -1 do a[i], t= tonumber(string.sub(s, t, t + 3), 10), t + 4 end
	return a
end
function add(a, b)
	a, b, c, t = create(a), create(b), create("0"), 0
	for i = 1, math.max(#a,#b) do
		t = t + (a[i] or 0) + (b[i] or 0)
		c[i], t = t%mod, math.floor(t/mod)
	end
	while t ~= 0 do c[#c + 1], t = t%mod, math.floor(t/mod) end
	return c
end
function sub(a, b)
	a, b, c, t = create(a), create(b), create("0"), 0
	for i = 1, #a do
		c[i] = a[i] - t - (b[i] or 0)
		if c[i] < 0 then t, c[i] = 1, c[i] + mod  else t = 0 end
	end
	return c
end
function by(a, b)
	a, b, c, t = create(a), create(b), create("0"), 0
	for i = 1, #a do
		for j = 1, #b do
			t = t + (c[i + j - 1] or 0) + a[i] * b[j]
			c[i + j - 1], t = t%mod, math.floor(t / mod)
		end
		if t ~= 0 then c[i + #b], t = t + (c[i + #b] or 0), 0 end
	end
	return c
end


function bchexdec(hex)
    local dec = '0';
    len = #hex;
    sum = 0;

    for i = len, 1, -1 do
        bcpow = 16;
        m = i;
        n = len - i;

        bcpow = math.pow(16,n)
        local hexStr = hex:sub(m, m);
        num = tonumber(hexStr, 16)

        if num ~= nil then 
            bcpow = string.format("%.0f", bcpow)
            bcmul_temp = bigint.multiply(bigint.new(num), bigint.new(bcpow))
            bcmul = string.format("%.0f", bigint.unserialize(bcmul_temp))
            
            local result = bigint.add(bigint.new(dec), bigint.new(bcmul))
            dec = tostring(bigint.unserialize(result, "string"))
        end  
    end

    return dec;
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

    text = bchexdec(text)
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
data = serial .. encrypt(mac .. enc_key);

response = '7f39809dd70a42a822ff';
data = decrypt(response, enc_key);

print(data)




-- ````````````````````````````````````````````````````````````````````````````````````````````
 

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



