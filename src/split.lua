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


--函数功能：将输入数据按照给定分隔符划分，并存入一个table
--参数：data:字符串(整行数据) sep:分隔符
--输出：划分后的table，即矩阵的一行
--备注：可考虑改写为repeat..until
--TODO：目前算法的时间复杂度是O(2(n-1)),n为每一行的数据量(即分隔符数+1)，可改写为双指针，在O(n)时间内解决
-- {北京,北京,10,1340100,北京SCP38,13748117,798,否,北京彩信中心2,910001,BJHSS01BNK,"13661210000,13661210001,13810010000,13810010001,13661210002,13810010002,13661210003","北京SMSC61,北京SMSC62,北京SMSC63,北京SMSC64,北京SMSC65,北京SMSC66,北京SMSC67,北京SMSC68,北京SMSC73,北京SMSC75,北京SMSC77,北京SMSC79",13800100500,527}
--两只脚会并拢的走法：
--[[
重新研究走路方法：
1-40，需要走8步，提取1-4,6-9,11-14,16-19,21-24,-26-29,-31-34,36-39
方法1:
1.(1,4)1-4;
2.(6,9)6-9;
3-7同理
8.(36,39)36-39;
9.(41,nil)return
--]]
--[=[
(1,5)
in loop while
(5,5),(5,10)
(10,10),(10,15)
(15,15),(15,20)
(15,15),(15,20)
end
(20,20)
--]=]
function split_v1(data,sep)
    local count = 0
    local back = 1
    local arry = {}
	local tmp
    local front = string.find(data,sep,back)
    if (front ~= nil) then
        count = count+1
    end
	--如果要从尾部往前输出，table.insert(arry,1,string.sub(data, start, lastStart-1))
	-- 第一步和最后一步都要单独的走法
	table.insert(arry,string.sub(data, back, front-1))
	
    while back and front do --"2,4,6"
		back = front
		front = string.find(data, sep, back+1)
		table.insert(arry,string.sub(data, back+1, front-1))
        
		--[=[
		--logf(start)--4,6,0
        if start then
            table.insert(arry,string.sub(data,lastStart+1,start-1))
            count = count+1
			lastStart = string.find(data,sep,tonumber(start)+1)
        else
            -- table.insert(arry,1,string.sub(data,lastStart+1,string.len(data)))
        end
		--]=]
    end
	--补充最后一列
	table.insert(arry,string.sub(data,back+1,string.len(data)))
	-- logf("last column = %s",string.sub(data,back+1,string.len(data)))
	-- logf("oneFile = %s",table2json(arry))
    return arry
end


-- {北京,北京,10,1340100,北京SCP38,13748117,798,否,北京彩信中心2,910001,BJHSS01BNK,"13661210000,13661210001,13810010000,13810010001,13661210002,13810010002,13661210003","北京SMSC61,北京SMSC62,北京SMSC63,北京SMSC64,北京SMSC65,北京SMSC66,北京SMSC67,北京SMSC68,北京SMSC73,北京SMSC75,北京SMSC77,北京SMSC79",13800100500,527}
-- 一轮走两步，分开脚的走法
--[=[
(1,4)1-4;
in loop while
(9,4)6-9;(9,14)11-14;
(19,14)16-19;(19,24)21-24;
(29,24)26-29;(29,34)31-34;
end

--]=]
function split_v2(data,sep)
    local count = 0
    local back = 1
    local arry = {}
	local tmp
    local front = string.find(data,sep,back)
    if (front ~= nil) then
        count = count+1
    end
	--如果要从尾部往前输出，table.insert(arry,1,string.sub(data, start, lastStart-1))
	-- 第一步和最后一步都要单独的走法
	table.insert(arry,string.sub(data, back, front))
	
    while back and front do --"2,4,6"
		back = string.find(data, sep, front+2)-1
		table.insert(arry,string.sub(data, front+2, back))
        
		front = string.find(data, sep, back+2)-1
		table.insert(arry,string.sub(data, back+2, front))
		--[=[
		--logf(start)--4,6,0
        if start then
            table.insert(arry,string.sub(data,lastStart+1,start-1))
            count = count+1
			lastStart = string.find(data,sep,tonumber(start)+1)
        else
            -- table.insert(arry,1,string.sub(data,lastStart+1,string.len(data)))
        end
		--]=]
    end
	--补充最后一列
	table.insert(arry,string.sub(data,back+1,string.len(data)))
	-- logf("last column = %s",string.sub(data,back+1,string.len(data)))
	-- logf("oneFile = %s",table2json(arry))
    return arry
end


--[=[
重新研究走路方法：
1-40，需要走8步，提取1-4,6-9,11-14,16-19,21-24,-26-29,31-34,36-40
方法1:
1.(1,4)1-4;
2.(6,9)6-9;
3.(11,14)11-14;
4.(16,19)16-19;
5-6同理
7.(31,34)31-34;
8.(36,nil)return
9.36-40;
--]=]
function split_v3(data,sep)
    local count = 0
    local arry = {}
    local back = 1											--第一步从1开始
    local front = string.find(data,sep,back)				--找到第一个sep
    while front do											--如果不是最后一步，即前一轮循环找到了下一个sep
		front = front-1										--退回sep前
		table.insert(arry,string.sub(data, back, front))	--第一步到第一个sep前，是需要提取的数据
		back = front + 2									--第二步从第一个sep后1位开始，由于front已经退后了一步，所以需要+2而非+1
		front = string.find(data, sep, back)				--尝试找第二个sep
		count = count+1										--计算走了多少步
		--logf(start)--4,6,0
		--[=[
        if start then
            table.insert(arry,string.sub(data,lastStart+1,start-1))
            count = count+1
			lastStart = string.find(data,sep,tonumber(start)+1)
        else
            -- table.insert(arry,1,string.sub(data,lastStart+1,string.len(data)))
        end
		--]=]
    end
	--补充最后一列
	table.insert(arry,string.sub(data,back+1,string.len(data)))
	-- logf("last column = %s",string.sub(data,back+1,string.len(data)))
	-- logf("oneFile = %s",table2json(arry))
    return arry
end












--函数功能：从指定路径按行读取文件，根据逗号划分，并存入一个table
--参数：文件的绝对路径(Optional)
--输出：按行划分后的table
--备注：可考虑改写为repeat..until

-- function getTable(argt)
	-- local filePath = argt.path or "/home/tangcz/test/data2.txt"
function getTable()
	local filePath = "/home/ismp_simu/numdata/"
	local fileName = filePath.."EOP-14764.txt"
    local file = io.open(fileName,"r+")
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




local BeginTime = os.time()



-- math.randomseed(os.time())
-- local arry = getTable()
-- local item = {}
-- for i = 1,3,1 do
    -- item = Lottery(math.random(0,100),arry)
    -- print(item)
-- end

--[=[
local data = "12345679,hfdjkka,3213,re3"
local r = split_v1(data,",")
ptb(r)
--]=]

--[=[
local data = "12345679,hfdjkka,3213,re3"
local r = split_v2(data,",")
ptb(r)
--]=]

---[[
-- for i=1,50000000 do
	local data = "12345679,hfdjkka,3213,re3"
	local r = split_v3(data,",")
	ptb(r)
-- end
--]]

--[[
for i=1,50000000 do 
	local data = "12345679,hfdjkka,3213,re3"
	local r = split(data,",")
	-- ptb(r)
end
--]]
-- local r = getTable()
-- print("-------------------------")
-- print(r[1][1])
-- print(r[1][2])
-- for i,v in pairs(r) do
	-- ptb(v)
-- end
local EndTime = os.time()
local TimeCost = EndTime - BeginTime

print(TimeCost)
--[[————————————————
--版权声明：本文为CSDN博主「osummertime」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/osummertime/article/details/72236768
--]]