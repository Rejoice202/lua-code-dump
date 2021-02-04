require"printtable"
require"math"
--函数功能：将输入数据按照给定分隔符划分，并存入一个table
--参数：a:字符串 b:分隔符
--输出：划分后的table
--备注：可考虑改写为repeat..until
function split(data,sep)
    local count = 0
    local start = 1
    local arry = {}
    local lastStart = string.find(data,sep,start)
    if (lastStart ~= nil) then
        count = count+1
    end
	--如果要从尾部往前输出，table.insert(arry,1,string.sub(data, start, lastStart-1))
	table.insert(arry,string.sub(data, start, lastStart-1))
    while(lastStart ~= nil) do--2,4,6
        start = string.find(data, sep, lastStart+1)
        --print(start)--4,6,0
        if(start ~= nil) then
            table.insert(arry,string.sub(data,lastStart+1,start-1))
            count = count+1
        else
            -- table.insert(arry,1,string.sub(data,lastStart+1,string.len(data)))
			table.insert(arry,string.sub(data,lastStart+1,string.len(data)))
        end
        lastStart = start
    end
    return arry
end


--函数功能：从指定路径按行读取文件，根据逗号划分，并存入一个table
--参数：文件的绝对路径(Optional)
--输出：按行划分后的table
--备注：可考虑改写为repeat..until

-- function getTable(argt)
	-- local filePath = argt.path or "/home/tangcz/test/data2.txt"
function getTable(docname)
	--local filePath = "/home/ismp_simu/numdata/"
	local filePath = "/home/tangcz/numdata/"
	--local fileName = filePath.."zj14401.txt"
	local fileName = filePath..docname..".txt"
    local file = io.open(fileName,"r")
	-- print("file = "..type(file))
	-- io.input(file)
	-- print(file:read())
    if (file == nil) then print("Error") end
    local arry = {}
    local data = file:read()
	-- print(data)
    local count = 0
    while data ~= nil do
        count = count + 1
        -- print(data)
        table.insert(arry,split(data,","))
        data = file:read()
		-- print(data)
    end
    -- print(table.getn(arry))
    return arry
end




function Lottery(item,arry)--抽奖
	print("this time item = "..item)
    for i = 1,#arry do
        if(tonumber(arry[i][2]) >= item) then
			print("more than ")
            return arry[i][1]
		else
			print("not exist")
        end
    end
end

-- math.randomseed(os.time())
-- local arry = getTable()
-- local item = {}
-- for i = 1,3,1 do
    -- item = Lottery(math.random(0,100),arry)
    -- print(item)
-- end



-- local data = "12345679,hfdjkka,3213,re3"
-- local r = split(data,",")
-- ptb(r)
local nametab = {"zj14765","zj14765"}
for i,v in pairs (nametab) do
	print("docname = "..v)
	r = getTable(v)
		for i,v in pairs(r) do
			print(r[i][4])
		end
end
-- local r = getTable()
-- print("-------------------------")
-- print(r[1][1])
-- print(r[1][2])
-- for i,v in pairs(r) do
	-- print(r[i][4])
-- end
--[[————————————————
--版权声明：本文为CSDN博主「osummertime」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/osummertime/article/details/72236768
--]]