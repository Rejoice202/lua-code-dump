require"printtable"
-- require"math"



-- 功能：数组去重
-- 备注：必须是已排序的数组
function AdjustArray(array)
	--logf("adjustarray,%s times,#array=%s",count,#array)
	for i = #array,2,-1 do --从后往前比较，比较时会用i和i-1号元素来比较，所以最多遍历到2
		--logf("i = %s, #array-1 = %s",i,#array-1)
		if array[i] == array[i-1] then --and array[i] ~= nil then	
		--	logf("duplicate i = %s",i)
			table.remove(array,i)
			-- return AdjustArray(array)	--重置循环下标
		end
	end
	return array
end

-- local array1 = {1,2,2,3,3,3,4,4,4,4}
local array1 = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan","jiangsu","jiangsu","jiangsu","jiangsu","shandong","shanghai","hunan","nanjing","beijing","zhejiang","hunan","shandong","shanghai","jiangsu"}

table.sort(array1)
-- array1 = AdjustArray(array1)
local Begin = os.time() 

for i=1,100000000 do
	AdjustArray(array1)
end
-- ptb(array1)
local End = os.time() 

print(End-Begin)

--一千万4s
--一亿次33s