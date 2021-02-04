require"math"
POWER = 10 --十进制

function digit(num)
	local count = 0
	repeat 
		count = count + 1
		dividend = math.pow(POWER,count)
		result = math.floor(num/dividend)
	until (result == 0) 
	return count
end
	

--exclusive OR
function xor (num1, num2)
	local result = ""
	repeat
		local s1 = num1%POWER
		local s2 = num2%POWER
		--print(s1,s2)
		if s1 == s2 then
			result = "0"..result
		else
			result = "1"..result
		end
		num1 = math.modf(num1/POWER)
		num2 = math.modf(num2/POWER)
		--print("result = "..result)
	until(num1 == 0 and num2 == 0)
	return result
end

--前向补0函数，未使用
function addzero(num,digit)
	print("before add",num)
	for i = 1, digit do
		num = "0"..num
	end
	print("after add",num)
	return num
end

function similarity(argt1,argt2)
	--格式校验：仅数字
	--待补充：2进制数字
	if type(argt1) ~= "number" or type(argt2) ~= "number" then
		return print("type error")
	end
	--长度校验：若不等长，则取出长串多余的部分，用于添加到结果里
	local dif = digit(argt1) - digit(argt2)
	local prefix = ""
	if digit(argt1) > digit(argt2) then
		prefix = string.sub(argt1, 1, dif)
		print(math.abs(dif))
	elseif digit(argt1) < digit(argt2) then
		prefix = string.sub(argt2, 1, dif)
	end
	local result = 	xor(argt1,argt2)
	local result = prefix..result
	print("original result = "..result)
	return tonumber(result,2)
	
end

local r = similarity(0x52,0x01)
print(r)
