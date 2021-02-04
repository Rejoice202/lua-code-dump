function digit(num)
	local count = 0
	--local dividend = math.pow(10,count)
--	local result = math.floor(num/dividend)
	repeat 
		count = count + 1
		dividend = math.pow(10,count)
		result = math.floor(num/dividend)
		print("count = "..count)
		print("dividend = "..dividend)
		print("result = "..result)
	until (result == 0) 
	return count
end
	
local r = digit(1)
print(r.."位数")