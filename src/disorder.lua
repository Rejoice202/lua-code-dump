require"printtable"

-- 几位数
MAX = 3

-- 生成n位有序数字
local num = {}
for i = 1,MAX do
	num[i] = i
end



for i = 2,MAX do
	local newNum = {}
	newNum[i] = num[1]
	print("i")
	ptb(newNum)
	for j = 1,MAX do
		if j~=i then
			print("j")
			newNum[j] = num[2]
			ptb(newNum)
			for k = 1,MAX do
				if k~=j and k~=i then
					print("k")
					newNum[k] = num[3]
					ptb(newNum)
					break
				end
			end
			break
		end
		break
	end
	print("第"..tostring(i-1).."次遍历")
	ptb(newNum)
end

function getNewNum()
	
	for i = 2,MAX do
		local newNum = {}
		newNum[i] = num[1]
		print("i")
		ptb(newNum)
		if not newNum[i] then 
			-- 好难啊，先学Python算了，有空再研究
		end
	end

end



--[[
local tmp

tmp = num[#num]
num[#num] = num[1]
num[1] = tmp


for i = 2,MAX do
	tmp = num[i-1]
	num[i-1] = num[i]
	num[i] = tmp
end
--]]