-- divideTable
require"printtable"
local ori = {1,2,3,4,5}

-- 功能：划分数组
function divideTable(ori,st,ed)
	local temptable = {}
	for i = st,ed do
		table.insert(temptable,ori[i])
	end
	return temptable
end

ptb(ori)
print("-------------")
local spanningTree = {}
local st = 1
for i = 1,#ori do
	if ori[i]%2 == 0 or i == #ori then
		local subtable = divideTable(ori,st,i)
		table.insert(spanningTree,subtable)
		st = i
	end
end
ptb(spanningTree)