VERSION = "V2.0.1"
-- include "one_provinceTable"
include "local_oneD_provinceTable"
--V2.0.0�汾��Ŀ����ֱ�ӽ���������ת��Ϊʡ������(��Ϊʡ��)
--V2.0.1�汾��Ŀ�����޸�ǰһ���汾��©��
--�ع����������ļ�

FILEPATH = "/home/tangcz/newdata/"
-- FILEPATH = "/home/tangcz/testdata/"
-- FILEPATH = "/home/tangcz/simpledata/"
--FILEPATH = "/home/tangcz/numdata/"

--����slrunִ��ʱ��
CMD_TIMEOUT = 0

--������־����
SLOG_CLASS = "DEBUG"

--�������ܣ����������ݰ��ո����ָ������֣�������һ��table
--������data:�ַ���(��������) sep:�ָ���
--��������ֺ��table���������һ��
--��ע���ɿ��Ǹ�дΪrepeat..until
--TODO��Ŀǰ�㷨��ʱ�临�Ӷ���O(2(n-1)),nΪÿһ�е�������(���ָ�����+1)���ɸ�дΪ˫ָ�룬��O(n)ʱ���ڽ��
-- {����,����,10,1340100,����SCP38,13748117,798,��,������������2,910001,BJHSS01BNK,"13661210000,13661210001,13810010000,13810010001,13661210002,13810010002,13661210003","����SMSC61,����SMSC62,����SMSC63,����SMSC64,����SMSC65,����SMSC66,����SMSC67,����SMSC68,����SMSC73,����SMSC75,����SMSC77,����SMSC79",13800100500,527}
--[=[
�����о���·������
1-40����Ҫ��8������ȡ1-4,6-9,11-14,16-19,21-24,-26-29,-31-34,36-40
����1:
1.(1,4)1-4;
2.(6,9)6-9;
3.(11,14)11-14;
4.(16,19)16-19;
5-7ͬ��
8.(36,39)36-39;
9.(41,nil)return
--]=]
function split(data,sep)
    local count = 0
    local arry = {}
    local back = 1											--��һ����1��ʼ
    local front = string.find(data,sep,back)				--�ҵ���һ��sep
    while front do											--����������һ������ǰһ��ѭ���ҵ�����һ��sep
		front = front - 1									--�˻�sepǰ
		table.insert(arry,string.sub(data, back, front))	--��һ������һ��sepǰ������Ҫ��ȡ������
		back = front + 2									--�ڶ����ӵ�һ��sep��1λ��ʼ������front�Ѿ��˺���һ����������Ҫ+2����+1
		front = string.find(data, sep, back)				--�����ҵڶ���sep
		count = count + 1									--�������˶��ٲ�
    end
	--�������һ��
	table.insert(arry,string.sub(data,back+1,string.len(data)))
	-- logf("last column = %s",string.sub(data,back+1,string.len(data)))
	-- logf("oneFile = %s",table2json(arry))
    return arry
end



--�������ܣ���ָ��·�����ж�ȡ�ļ������ݶ��Ż��֣�������һ��table
--�������ļ���
--��������л��ֺ��table,����������
--��ע���ɿ��Ǹ�дΪrepeat..until

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
	local data = file:read()	--�ӵ�2�п�ʼ��
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




-- function Lottery(item,arry)--�齱��
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

function num2location_v6(argt)
	--���ϵͳ��ʼ״̬
	-- local BeginTime = os.time()
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Begin result.Result[1].count = %s",result.Result[1].count)
	local BeginRow = result.Result[1].count
	
	--���������ļ����������ļ�
	local r = fs.ls(FILEPATH)	--fs.ls�൱��ִ��ls -a����
	local allfile = r.Result
	--ɾ��.&..
	table.remove(allfile,1)
	table.remove(allfile,1)
	for i,v in pairs (allfile) do
		oneFile(v)
	end
	
	--���ϵͳ����״̬
	-- local EndTime = os.time()
	 -- local TimeCost = EndTime - BeginTime	--ʱ����ʵû���κ����壬slrun�᷵�صȴ�ʱ���ִ��ʱ�䣬���һ���ȷ��С�����3λ(��λ��)
	local result = sdc.sqlSelect("select count(*) as count from numtabmob;")
	-- logf("result = %s",table2json(result))
	-- logf("result.Result[1] = %s",table2json(result.Result[1]))
	-- logf("Final result.Result[1].count = %s",result.Result[1].count)
	local EndRow = result.Result[1].count
	local AffectedRow = EndRow - BeginRow
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.TimeCost = TimeCost
	response.AffectedRow = AffectedRow	
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
	
end

--��Σ��ļ���
--�� �ܣ����ı����л��ֺ󣬸��ķ�ʡ����е����ţ�����������Ŵ������ݿ�
function oneFile(docname)

	local oneProvince = {}
	local r = getTable(docname)	--r���������ļ�(����)
	-- logf("One file data r = %s",table2json(r))
	
	for i,v in pairs(CAPCITY) do 
		-- logf("i = %s, v = %s",i, v)
		oneProvince = byProvince(r, i)	--��ȡ��ת�����ŵĵ�ʡ����
		-- logf("oneProvince = %s",table2json(oneProvince))
		InsertIntoDB(oneProvince)
	end
	
	
	
	--���ļ���ʡ���ֳɲ�ͬtable
	-- zhejiangarray = byProvince(r, "�㽭")
	-- guangdongarray = byProvince(r, "�㶫")
	
	-- logf("zhejiangarray ...")
	-- ptb(zhejiangarray)
	-- logf("type zhejiangarray[1][1] = %s",type(zhejiangarray[1][1]))
 	-- logf("zhejiangarray[1][1] = %s",zhejiangarray[1][1])
	
	-- InsertIntoDB(zhejiangarray)
	-- InsertIntoDB(guangdongarray)
	
end 

--���ܣ����ݵ�һ���жϹ���ʡ�������г�������תΪʡ������
--������r:�����л��ֵ�table province:ANSI���������ʡ��
--TODO��PROVINCEARRAY[province]����û��Ҫ��ȫ�ֱ�����ÿ����һ���ֲ������Ϳ�����
function byProvince(r, province)
	-- logf("province = %s",province)
	-- logf("type CAPCITY[province] = %s",type(CAPCITY[province]))
	
	-- if not CAPCITY[province] then 
		-- return logf("CAPCITY NOT EXIST")
	-- end
	
	-- local zhejiangarray = {}
	local PROARRAY = {}
	
	
	for i,v in pairs(r) do
		--logf("province = %s, capital = %s",r[i][1],r[i][2])
		if r[i][1] == province then 
			-- logf("matched province = %s",r[i][1])
			--logf("type r[i] = %s",type(r[i]))
			table.insert(PROARRAY,r[i])
		else 
			-- logf("not match province = %s,type = %s",r[i][1],type(r[i][1]))
		end
	end
	
	--��ȡʡ��������ţ���Ϊʡ��
	--������ͨ��ʡ�����ƻ�ȡʡ�ţ��ƺ�Ҳ�����˹���ȡʡ��
	local capitalID
	for i,v in pairs(PROARRAY) do
	--�򵥵Ľ���һ�������ά����
	--PROARRAY��provinceʡ��ȫ�����ݣ���������
	--PROARRAY[i]�ǵ�i�У����� �㽭�����ݣ�571,1510000 �����һ��
	--PROARRAY[2]�ǵ�2�У��ڶ����ǳ�����
		if PROARRAY[i][2] == CAPCITY[province] then 
			capitalID = PROARRAY[i][3]
		end
	end
	
	
	-- logf("PROARRAY = %s",table2json(PROARRAY))
	
	-- logf("province = %s, capitalID = %s",province, capitalID)
	if capitalID then
		-- logf("PROARRAY = %s",table2json(PROARRAY))
		for i,v in pairs(PROARRAY) do
			PROARRAY[i][3] = capitalID
		end
	end
	
	-- logf("PROVINCEARRAY = %s",table2json(PROVINCEARRAY))
	
	return PROARRAY
		--logf("locationid = %s, num = %s",r[i][3],r[i][4])	
		--table.insert(numberarray,r[i][4])
end

--���ܣ���һ��table�ڵĵ�3��(����)�͵�4��(����)�������ݿ�
--��Σ�oneProvince:table
function InsertIntoDB(oneProvince)

	for i,v in pairs(oneProvince) do
		-- logf("locationid = %s, num = %s",oneProvince[i][3],oneProvince[i][4])
		-- setErrExit(false)
		sqlcmd = string.format("insert into numtabmob (locationid,phonenum) values ('%s','%s');",oneProvince[i][3],oneProvince[i][4]) 
		-- datapair =  
		-- ('',''),('','')
		-- sqlcmd = "insert into numtabmob (locationid,phonenum) values "..('%s','%s');",oneProvince[i][3],oneProvince[i][4])
		local result = sdc.sqlRun(sqlcmd)
		-- table.insert(numberarray,oneProvince[i][4])
		-- PROVINCEARRAY
	end
	
end





-----------------------------------------------------------------------------------------------


-- ���ܣ��ض�����ȥ�أ�ֻ�Ƚ�ĳ�ض���ά����ĵ�3��
-- ��ע�������������������
function AdjustArray_sorted(array)
	--logf("adjustarray,%s times,#array=%s",count,#array)
	for i = #array,2,-1 do --�Ӻ���ǰ�Ƚϣ��Ƚ�ʱ����i��i-1��Ԫ�����Ƚϣ�������������2
		--logf("i = %s, #array-1 = %s",i,#array-1)
		if array[i][3] == array[i-1][3] then --and array[i] ~= nil then	
		--	logf("duplicate i = %s",i)
			table.remove(array,i)
			-- return AdjustArray(array)	--����ѭ���±�
		end
	end
	return array
end


-- hashmap����ȥ�ط�
function AdjustArray(array)
	local duplicateindex = {}
	for i,v in pairs (array) do 
			-- �����ļ����л��֣�ÿһ�еĵ�3�������ţ���Ҫ�Դ�Ϊ��׼������ȥ��
			duplicateindex[array[i][3]] = array[i][1]
	end
	-- ���������ţ�ֵ��ʡ��
	return duplicateindex
end



--����location2province����
function location2province(argt)
	
	local result = sdc.sqlSelect("select count(*) as count from location2province;")
	local BeginRow = result.Result[1].count
	
	--���������ļ����������ļ�
	local r = fs.ls(FILEPATH)	--fs.ls�൱��ִ��ls -a����
	local allfile = r.Result
	--ɾ��.&..
	table.remove(allfile,1)
	table.remove(allfile,1)
	-- ������-ʡ�����redis
	for i,v in pairs (allfile) do
		getProvinceid(v)
	end
	
	-- ��redis��SET�а�ȫ��ȥ�غ�����ݷŽ�mysql
	for i = 1,999 do 
		local provinceName = redis.exec("smembers %s",i)
		-- logf("provinceName = %s",table2json(provinceName))
		if eop_province[provinceName.Result[1]] then
			sdc.sqlRun("insert into location2province (locationId,provinceID) values ('%s','%s');",i,eop_province[provinceName.Result[1]])
		end
	end
		
	
	--���ϵͳ����״̬
	local result = sdc.sqlSelect("select count(*) as count from location2province;")
	local EndRow = result.Result[1].count
	local AffectedRow = EndRow - BeginRow
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.AffectedRow = AffectedRow	
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
end


-- ���룺�����ļ���ȥ�غ������&ʡ��
function insertIntoRedis(array)

	for i,v in pairs(array) do
		-- setErrExit(false)
		logf("locationid = %s, provinceID = %s",i,v)
		local rediscmd = string.format("SADD %s %s",i,v)
		local result = redis.exec(rediscmd)
	end


end




--��Σ��ļ���
--�� �ܣ����ı����л��ֺ󣬽����ź�ʡ�Ŵ������ݿ�
function getProvinceid(docname)

	-- local oneProvince = {}
	local r = getTable(docname)	--r���������ļ�(����)
	-- logf("One file data r = %s",table2json(r))
	logf("len = %s",#r)
	r = AdjustArray(r)
	logf("after adjust len = %s",#r)
	
	--�ȷŽ�redis��set��ȫ��ȥ��
	insertIntoRedis(r)
	--[[
	for i,v in pairs(r) do
		-- setErrExit(false)
		-- logf("locationid = %s, provinceID = %s",r[i][3],r[i][1])
		logf("locationid = %s, provinceID = %s",i,v)
		local sqlcmd = string.format("insert into location2province (locationId,provinceID) values ('%s','%s');",i,v)
		local result = sdc.sqlRun(sqlcmd)
		-- table.insert(numberarray,r[i][4])
	end
	--]]
end 



-- ����-����
lib_cmdtable["num2location_v6"] = num2location_v6	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v6/num2location

-- ����-ʡ��
lib_cmdtable["location2province_v1"] = location2province	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/location2province
