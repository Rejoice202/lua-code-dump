require"printtable"
-- local p = {1,3,7,15,31,63}
-- local p = {1,2,4,8,16,32}
local p = {0.1}
local W = 10
-- 生成前n项数组p
function genp(p, n)
	for i = 2,n do
		p[i] = (sumTb(p, i)+1)/W
	end
end


-- 求数组p的前n项和，并加上项数
function sumTb(p, n)
	local sum = 0
	for i = 2,n do
		sum = sum + p[i-1]
	end
	return sum
end

local n = 7
-- print("sumTb "..n..":"..sumTb(p, n))
genp(p, n)
ptb(p)