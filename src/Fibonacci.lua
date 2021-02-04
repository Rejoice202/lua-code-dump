---------------------------------------------------
--[[
算法的时间复杂度研究
以计算斐波纳契数列的时间为例，分别采用
1.递归:61
2.备忘录:12
3.动态规划:2
计算一千万次
]]
---------------------------------------------------

local beginTime = os.time()

-- 递归
function Fibonacci_v1(n)
	if n < 3 then
		return 1
	end
	return Fibonacci_v1(n-1) + Fibonacci_v1(n-2)
end

-- 备忘录
function Fibonacci_v2(n)
	local dp = {1,1}
	if n < 3 then
		return dp[n]
	end
	for i = 3,n do
		dp[i] = dp[i-1]+dp[i-2]
	end
	return dp[n]
end

-- O(1)空间的动态规划
function Fibonacci_v3(n)
	local f1,f2 = 1,1
	if n < 3 then
		return 1
	end
	local fn
	for i = 3,n do
		fn = f1+f2
		f1,f2 = f2,fn
	end
	return fn
end
-- print(Fibonacci_v3(10))

for i = 1,100000000 do
	-- Fibonacci_v1(10)
	-- Fibonacci_v2(10)
	Fibonacci_v3(10)
end

local endTime = os.time()
local timeCost = endTime - beginTime
print(timeCost)
