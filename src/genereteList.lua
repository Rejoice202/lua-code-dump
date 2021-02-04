require("printtable")
--功能：生成从初始值到最终值，但中间有空隙的数组
--入参：初始值、最终值、剔除值
--出参：结果数组/nil
function generateList(initial, ultimate, eliminate)
	--初始值必须小于最终值
	if tonumber(initial)>tonumber(ultimate) then
		print("Invalid input")
		return 
	end
	--生成从初始值到最终值的数组
	local capitalID = {}
	for i = tonumber(initial),tonumber(ultimate) do
		table.insert(capitalID,i)
	end
	--将特定数值剔除
	if eliminate then
		for i,v in pairs(eliminate) do
			capitalID = deleteArray(capitalID, v)
		end
	end
	
	return capitalID
end

function deleteArray(capitalID, eliminate)
	for i,v in pairs(capitalID) do
		if v == tonumber(eliminate) then
			table.remove(capitalID,i)
		end
	end
	return capitalID
end

local r = generateList(1,11,{7,8,9})
if r then 
	ptb(r)
end