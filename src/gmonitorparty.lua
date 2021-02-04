require"math"
POWER = 10 --十进制

local count = 0
function genMonitorparty_test(count)
	-- math.randomseed(os.time())
	-- math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	local initial = 10000
	-- local count = 0
	local monitor = initial + count
	count = count + 1
	return monitor, count
-- 然后不断产生随机数
	---[=[ 
	-- for i=1, 5 do
		-- local monitor = math.random()
		-- print(monitor)
		-- genMonitorparty(count)
	-- end
	--]=]
	
end


--通过闭包来实现局部变量不断加一
function incr()
    local i=0
    return function()	--尾调用
        i=i+1
        return i
    end
end


c1 = incr()
c2 = incr()
for i = 1,5 do

	-- print(genMonitorparty(0))
-- local r, e = genMonitorparty(e)
print("i = "..i)
print("c1 = "..c1())
print("c2 = "..c2())
end