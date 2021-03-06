VERSION = "V2.0.0"
--此版本可以直接将城市区号转化为省会区号(视为省号)
--一次只能转化一个省，且依赖ANSI编码的中文省名和省会名

FILEPATH = "/home/tangcz/testdata/"
--FILEPATH = "/home/tangcz/numdata/"

--函数功能：将输入数据按照给定分隔符划分，并存入一个table
--参数：data:字符串 sep:分隔符
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
    while(lastStart ~= nil) do --"2,4,6"
        start = string.find(data, sep, lastStart+1)
        --logf(start)--4,6,0
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
	-- logf(data)
    local count = 0
    while data ~= nil do
        count = count + 1
        -- logf(data)
        table.insert(arry,split(data,","))
        data = file:read()
		-- logf(data)
    end
    -- logf(table.getn(arry))
    return arry
end




-- function Lottery(item,arry)--抽奖
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

function num2location_v3(argt)
	--监控系统初始状态
	local BeginTime = os.time()
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Begin result.Result[1].count = %s",result.Result[1].count)
	local BeginRow = result.Result[1].count
	
	--处理整个文件夹内所有文件
	local r = fs.ls(FILEPATH)
	local allfile = r.Result
	--删除.&..
	table.remove(allfile,1)
	table.remove(allfile,1)
	for i,v in pairs (allfile) do
		oneFile(v)
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

--把一个文件按行划分，将每一行的号码和区号存入数据库
function oneFile(docname)

	local numberarray = {}
	local zhejiangarray = {}

	local landnum = {}
	local sqlcmd
	
	local r = getTable(docname)
	
	for i,v in pairs(r) do
		--logf("province = %s, capital = %s",r[i][1],r[i][2])
			if r[i][1] == "浙江" then 
				logf("matched province = %s",r[i][1])
				--logf("type r[i] = %s",type(r[i]))
				table.insert(zhejiangarray,r[i])
			else 
				logf("not match province = %s,type = %s",r[i][1],type(r[i][1]))
			end
		--logf("locationid = %s, num = %s",r[i][3],r[i][4])	
		--table.insert(numberarray,r[i][4])
	end
	
	logf("zhejiangarray ...")
	--ptb(zhejiangarray)
	logf("type zhejiangarray[1][1] = %s",type(zhejiangarray[1][1]))
	logf("zhejiangarray[1][1] = %s",zhejiangarray[1][1])
	
	local capitalID
	for i,v in pairs(zhejiangarray) do
		if zhejiangarray[i][2] == "杭州" then 
			capitalID = zhejiangarray[i][3]
		end
	end
	
	logf("capitalID = %s",capitalID)
	for i,v in pairs(zhejiangarray) do
			zhejiangarray[i][3] = capitalID
	end
	
	InsertIntoDB(zhejiangarray)
	
end


--功能：将一个table内的第3列(区号)和第4列(号码)插入数据库
--入参：r:table
function InsertIntoDB(r)

	for i,v in pairs(r) do
		logf("locationid = %s, num = %s",r[i][3],r[i][4])
		setErrExit(false)
		sqlcmd = string.format("insert into numtabmob (locationid,phonenum) values ('%s','%s');",r[i][3],r[i][4])
		local result = sdc.sqlRun(sqlcmd)
		-- table.insert(numberarray,r[i][4])
	end
	
end

lib_cmdtable["num2location_v3"] = num2location_v3	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v3/num2location
