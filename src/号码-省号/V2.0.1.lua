VERSION = "V2.0.1"
-- include "one_provinceTable"
include "local_oneD_provinceTable"
--V2.0.0版本的目标是直接将城市区号转化为省会区号(视为省号)
--V2.0.1版本的目标是修复前一个版本的漏洞
--重构整个代码文件

--FILEPATH = "/home/tangcz/newdata/"
-- FILEPATH = "/home/tangcz/testdata/"
FILEPATH = "/home/tangcz/simpledata/"
--FILEPATH = "/home/tangcz/numdata/"

--设置slrun不限时执行
CMD_TIMEOUT = 60

--函数功能：将输入数据按照给定分隔符划分，并存入一个table
--参数：data:字符串(整行数据) sep:分隔符
--输出：划分后的table，即矩阵的一行
--备注：可考虑改写为repeat..until
--TODO：目前算法的时间复杂度是O(2(n-1)),n为每一行的数据量(即分隔符数+1)，可改写为双指针，在O(n)时间内解决
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
		--TODO:双指针
		-- lastStart = string.find(data, sep, start+1)
    end
    return arry
end


--函数功能：从指定路径按行读取文件，根据逗号划分，并存入一个table
--参数：文件名
--输出：按行划分后的table,即整个矩阵
--备注：可考虑改写为repeat..until

-- function getTable(argt)
	-- local filePath = argt.path or "/home/tangcz/test/data2.txt"
function getTable(docname)
	logf("----------------------------------------------This time : %s",docname)
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
	local data = file:read()	--从第2行开始读
	-- logf(data)
    -- local count = 0
    while data ~= nil do
        -- count = count + 1
        -- logf(data)
        table.insert(arry, split(data,","))
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

function num2location_v4(argt)
	--监控系统初始状态
	local BeginTime = os.time()
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Begin result.Result[1].count = %s",result.Result[1].count)
	local BeginRow = result.Result[1].count
	
	--处理整个文件夹内所有文件
	local r = fs.ls(FILEPATH)	--fs.ls相当于执行ls -a命令
	local allfile = r.Result
	--删除.&..
	table.remove(allfile,1)
	table.remove(allfile,1)
	for i,v in pairs (allfile) do
		oneFile(v)
	end
	
	--监控系统最终状态
	local EndTime = os.time()
	 local TimeCost = EndTime - BeginTime	--时间其实没有任何意义，slrun会返回等待时间和执行时间，而且还精确到小数点后3位(单位秒)
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

--入参：文件名
--功 能：将文本按行划分后，更改非省会城市的区号，将号码和区号存入数据库
function oneFile(docname)

	local oneProvince = {}
	local r = getTable(docname)	--r就是整个文件(矩阵)
	logf("One file data r = %s",table2json(r))
	
	for i,v in pairs(CAPCITY) do 
		logf("i = %s, v = %s",i, v)
		oneProvince = byProvince(r, i)	--获取已转换区号的单省数组
		-- logf("oneProvince = %s",table2json(oneProvince))
		InsertIntoDB(oneProvince)
	end
	
	
	
	--把文件按省划分成不同table
	-- zhejiangarray = byProvince(r, "浙江")
	-- guangdongarray = byProvince(r, "广东")
	
	-- logf("zhejiangarray ...")
	-- ptb(zhejiangarray)
	-- logf("type zhejiangarray[1][1] = %s",type(zhejiangarray[1][1]))
 	-- logf("zhejiangarray[1][1] = %s",zhejiangarray[1][1])
	
	-- InsertIntoDB(zhejiangarray)
	-- InsertIntoDB(guangdongarray)
	
end 

--功能：根据第一列判断归属省，将所有城市区号转为省会区号
--参数：r:按行列划分的table province:ANSI编码的中文省名
--TODO：PROVINCEARRAY[province]好像没必要 用全局变量，每次用一个局部变量就可以了
function byProvince(r, province)
	-- logf("province = %s",province)
	-- logf("type CAPCITY[province] = %s",type(CAPCITY[province]))
	
	-- if not CAPCITY[province] then 
		-- return logf("CAPCITY NOT EXIST")
	-- end
	
	-- local zhejiangarray = {}
	-- local PROVINCEARRAY = {}
	
	
	for i,v in pairs(r) do
		--logf("province = %s, capital = %s",r[i][1],r[i][2])
		if r[i][1] == province then 
			-- logf("matched province = %s",r[i][1])
			--logf("type r[i] = %s",type(r[i]))
			table.insert(PROVINCEARRAY[province],r[i])
		else 
			-- logf("not match province = %s,type = %s",r[i][1],type(r[i][1]))
		end
	end
	
	--获取省会城市区号，视为省号
	--现在是通过省会名称获取省号，似乎也可以人工获取省号
	local capitalID
	for i,v in pairs(PROVINCEARRAY[province]) do
	--史无前例的使用到了三维数组，简单的解释一下
	--PROVINCEARRAY[province]是province省的全部数据：整个矩阵
	--PROVINCEARRAY[province][i]是第i行：形如 浙江，杭州，571,1510000 矩阵的一行
	--PROVINCEARRAY[province][2]是第2列：第二列是城市名
		if PROVINCEARRAY[province][i][2] == CAPCITY[province] then 
			capitalID = PROVINCEARRAY[province][i][3]
		end
	end
	
	
	-- logf("PROVINCEARRAY = %s",table2json(PROVINCEARRAY))
	
	logf("province = %s, capitalID = %s",province, capitalID)
	if capitalID then
		logf("PROVINCEARRAY = %s",table2json(PROVINCEARRAY))
		for i,v in pairs(PROVINCEARRAY[province]) do
			PROVINCEARRAY[province][i][3] = capitalID
		end
	end
	
	-- logf("PROVINCEARRAY = %s",table2json(PROVINCEARRAY))
	
	return PROVINCEARRAY[province]
		--logf("locationid = %s, num = %s",r[i][3],r[i][4])	
		--table.insert(numberarray,r[i][4])
end

--功能：将一个table内的第3列(区号)和第4列(号码)插入数据库
--入参：oneProvince:table
function InsertIntoDB(oneProvince)

	for i,v in pairs(oneProvince) do
		logf("locationid = %s, num = %s",oneProvince[i][3],oneProvince[i][4])
		setErrExit(false)
		sqlcmd = string.format("insert into numtabmob (locationid,phonenum) values ('%s','%s');",oneProvince[i][3],oneProvince[i][4])
		local result = sdc.sqlRun(sqlcmd)
		-- table.insert(numberarray,oneProvince[i][4])
		-- PROVINCEARRAY
	end
	
end

lib_cmdtable["num2location_v4"] = num2location_v4	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v4/num2location
