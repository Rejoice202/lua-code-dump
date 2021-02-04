local VERSION = "V3.0.0"
--此版本不是从V2上升级而来，是从V1上做了性能优化升级而来。并不像V2一样依赖中文字符编码
--3.0.0主要优化方向为：将函数赋值给局部变量后再调用，因为lua访问局部变量非常快
local FILEPATH = "/home/tangcz/testdata/"
-- local FILEPATH = "/home/tangcz/numdata/"

--设置slrun不限时执行
CMD_TIMEOUT = 0

--用局部变量引用函数
local findStr = string.find
local insertTb = table.insert
local removeTb = table.remove
local subStr = string.sub
local lenStr = string.len

--函数功能：将输入数据按照给定分隔符划分，并存入一个table
--参数：data:字符串 sep:分隔符
--输出：划分后的table
--备注：可考虑改写为repeat..until
function split(data,sep)
    local count = 0
    local start = 1
    local arry = {}
    local lastStart = findStr(data,sep,start)
    if (lastStart ~= nil) then
        count = count+1
    end
	--如果要从尾部往前输出，insertTb(arry,1,subStr(data, start, lastStart-1))
	insertTb(arry,subStr(data, start, lastStart-1))
    while(lastStart ~= nil) do --"2,4,6"
        start = findStr(data, sep, lastStart+1)
        --logf(start)--4,6,0
        if(start ~= nil) then
            insertTb(arry,subStr(data,lastStart+1,start-1))
            count = count+1
        else
            -- insertTb(arry,1,subStr(data,lastStart+1,lenStr(data)))
			insertTb(arry,subStr(data,lastStart+1,lenStr(data)))
        end
        lastStart = start
    end
    return arry
end


--函数功能：从指定路径按行读取文件，根据逗号划分，并存入一个table
--参数：文件名(Optional)
--输出：按行划分后的table
--备注：可考虑改写为repeat..until

-- function getTable(argt)
	-- local filePath = argt.path or "/home/tangcz/test/data2.txt"
function getTable(docname)
	
	--local file = io.open("/home/tangcz/test/data2.txt","r+")
	--local fileName = FILEPATH.."zj17222"..".txt"
    local fileName = FILEPATH..docname
    local file = io.open(fileName,"r")
	logf("file = "..type(file))
	-- io.input(file)
	-- logf(file:read())
    if (file == nil) then logf("Error") end
    local arry = {}
    local data = file:read()
	local data = file:read()	--第2行开始读
	-- logf(data)
    -- local count = 0
	local genColun = split
    while data ~= nil do
        -- count = count + 1
        -- logf(data)
        insertTb(arry, genColun(data,","))
        data = file:read()	--读下一行
		-- logf(data)
    end
    -- logf(table.getn(arry))
    return arry
end




-- function Lottery(item,arry)--抽奖
	-- logf("this time item = "..item)
    -- for i = 1,#arry do
        -- if(tonumber(arry[i][2]) >= item) then
			-- logf("more than ")
            -- return arry[i][1]
		-- else
			-- logf("not exist")
        -- end
    -- end
-- end

-- math.randomseed(os.time())
-- local arry = getTable()
-- local item = {}
-- for i = 1,3,1 do
    -- item = Lottery(math.random(0,100),arry)
    -- logf(item)
-- end



-- local data = "12345679,hfdjkka,3213,re3"
-- local r = split(data,",")
-- ptb(r)
--local r = getTable()
-- logf("-------------------------")
-- logf(r[1][1])
-- logf(r[1][2])
-- for i,v in pairs(r) do
	-- logf(r[i][4])
-- end

function num2location_v5(argt)
	--监控系统初始状态
	local BeginTime = os.time()
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Begin result.Result[1].count = %s",result.Result[1].count)
	local BeginRow = result.Result[1].count
	
	
	local r = fs.ls(FILEPATH)
	local allfile = r.Result
	removeTb(allfile,1)
	removeTb(allfile,1)
	logf("allfile = %s",table2json(allfile))
	logf("allfile[1] = %s, allfile[2] = %s",allfile[1],allfile[2])
	local genMatrix = oneFile
	for i,v in pairs (allfile) do
		genMatrix(v)
	end
	
	--监控系统最终状态
	local EndTime = os.time()
	local TimeCost = EndTime - BeginTime
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Final result.Result[1].count = %s",result.Result[1].count)
	local EndRow = result.Result[1].count
	local AffectedRow = EndRow - BeginRow
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.TimeCost = TimeCost
	response.AffectedRow = AffectedRow	
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
	
end

function oneFile(docname)

	local numberarray = {}
	local landnum = {}
	local sqlcmd
	
	local r = getTable(docname)
	
	-- for i,v in pairs(r) do
		-- logf("l = %s, num = %s",r[i][3],r[i][4])	
		-- insertTb(numberarray,r[i][4])
	-- end
	local sdcRun = sdc.sqlRun
	for i,v in pairs(r) do
		-- logf("locationid = %s, num = %s",r[i][3]	,r[i][4])
		setErrExit(false)
		sqlcmd = string.format("insert into numtabmob (locationid,phonenum) values ('%s','%s');",r[i][3],r[i][4])
		local result = sdcRun(sqlcmd)
		insertTb(numberarray,r[i][4])
	end
	
end

--[[
功能：通过命令将城市区号转化为省会区号
入参列表：initial 初始值
		  ultimate 最终值
		  eliminate 剔除值(数组)
		  capitalID 省会区号
备注：直接操作mysql
--]]
function centralization(argt)
	local r = generateList(argt.initial, argt.ultimate, argt.eliminate)
	--logf("r = %s",table2json(r))
	local provinceID
	for i, v in pairs(r) do 
            if i == 1 then 
                provinceID = "'" ..v .."'"
            else
                provinceID = provinceID .."," .."'"..v .."'"
            end 
        end
	
	local sqlcmd = "update numtabmob set locationid = '"..argt.capitalID.."' where locationid in ("..provinceID..")"
	logf("sqlcmd = %s",sqlcmd)
	local r = sdc.sqlRun(sqlcmd)
	-- logf("result = %s",table2json(result))
	local AffectedRow = r.Result
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.Begin = Begin	
	-- response.End = End	
	-- response.TimeCost = TimeCost	
	response.AffectedRow = AffectedRow	
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
end


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
		insertTb(capitalID,i)
	end
	--将特定数值剔除
	if eliminate then
		for i,v in pairs(eliminate) do
			capitalID = deleteArray(capitalID, tonumber(v))
		end
	end
	
	return capitalID
end

function deleteArray(capitalID, eliminate)
	for i,v in pairs(capitalID) do
		if v == tonumber(eliminate) then
			removeTb(capitalID,i)
		end
	end
	return capitalID
end


lib_cmdtable["num2location_v5"] = num2location_v5	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v5/num2location
lib_cmdtable["centralization_v1"] = centralization --curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/centralization -d '{"initial":"550","ultimate":"561","eliminate":["551,560"],"capitalID":"551"}'