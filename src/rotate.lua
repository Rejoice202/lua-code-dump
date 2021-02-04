require"printtable"

local matrix1 = 
{
	{1,2,3},
	{4,5,6},
	{7,8,9},
	{0,"A","B"},
}
local matrix2 = 
{
	{0,1,2,3},
	{4,5,6,7},
	{8,9,"A","B"},
	{"C","D","E","F"},
}
local matrix3 = 
{
	{0,1,2,3},
	{4,5,6,7},
	{8,9,"A","B"},
	-- {"C","D","E","F"},
}

local matrix4 = 
{
	{1,11},
	{2,5,11},
	{3,6,8,11},
	{4,7,9,10,11},
}


local matrix = matrix4

ptb(matrix)

-- 功能：获取稀疏矩阵中最长的边
function maxMatrihLen(matrix)
	local len = #matrix
	for i = 1,#matrix do
		if #matrix[i] > len then
			len = #matrix[i]
		end
	end
	print("maxMatrihLen = "..len)
	return len
end

-- 功能：稀疏矩阵右对齐
function rightAlignMatrix(matrix, len)
	for i = 1,#matrix do
		fillMatrix(matrix[i], len-#matrix[i])
	end
end

function fillMatrix(line, num)
	if num <= 0 then
		return
	end
	for i = 1,num do
		table.insert(line,1,nil)
	end
end

-- rightAlignMatrix(matrix, maxMatrihLen(matrix))
-- ptb(matrix)

function rotate(matrix, length)
	-- 翻转方阵
	local column = math.floor(length/2)
	local row = math.ceil(length/2)
	print(string.format("column = %s,row = %s",column,row))
	
	for i = 1,row do
	-- for i = row,1,-1 do
		for j = 1,column do
		-- for j = column,1,-1 do
			local temp = matrix[i][j]
			matrix[i][j] = matrix[j][length+1-i]
			matrix[j][length+1-i] = matrix[length+1-i][length+1-j]
			matrix[length+1-i][length+1-j] = matrix[length+1-j][i]
			matrix[length+1-j][i] = temp
-- print("---------------------after rotation ---------------------")
-- ptb(matrix)
		end
	end
end


function getLastCommonNode(matrix)
	local lenR = #matrix	--行数
	local lenC = #matrix[4]	--列数
	print(string.format("len = %s,%s",lenR,lenC))
	-- 找到最长的边，所有短边进行右对齐，再翻转
	local length = maxMatrihLen(matrix)
	-- 稀疏矩阵右对齐
	for i = 1,#matrix do
		fillMatrix(matrix[i], length-#matrix[i])
	end
	
	-- 列数大于行数时，把行数补充到与列数相等
	if lenR<length then
		for i = lenR+1,length do
			matrix[i] = {}
		end
	end
	
	rotate(matrix, length)
	
	local commonNode
	for i = 1,#matrix do
		for j = 1,#matrix[i]-1 do
			print(string.format("i:%s j:%s matrix[i][j]:%s matrix[i][j+1]:%s",i,j,matrix[i][j],matrix[i][j+1]))
			if matrix[i][j] ~= matrix[i][j+1] then
				commonNode = matrix[i-1][1]
				break
			end
		end
		if commonNode then
			break
		end
	end
	
	return commonNode
end
-- rotate(matrix)
print("---------------------after all the rotation ---------------------")
print("getLastCommonNode(matrix) = "..getLastCommonNode(matrix))
ptb(matrix)