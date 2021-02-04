VERSION = "V2.0.0"
-- include "one_provinceTable"
include "local_oneD_provinceTable"
--�˰汾��Ŀ����ֱ�ӽ���������ת��Ϊʡ������(��Ϊʡ��)
--�ع����������ļ�

--FILEPATH = "/home/tangcz/newdata/"
-- FILEPATH = "/home/tangcz/testdata/"
FILEPATH = "/home/tangcz/simpledata/"
--FILEPATH = "/home/tangcz/numdata/"

--����slrun����ʱִ��
CMD_TIMEOUT = 60

--�������ܣ����������ݰ��ո����ָ������֣�������һ��table
--������data:�ַ���(��������) sep:�ָ���
--��������ֺ��table���������һ��
--��ע���ɿ��Ǹ�дΪrepeat..until
--TODO��Ŀǰ�㷨��ʱ�临�Ӷ���O(2(n-1)),nΪÿһ�е�������(���ָ�����+1)���ɸ�дΪ˫ָ�룬��O(n)ʱ���ڽ��
function split(data,sep)
    local count = 0
    local start = 1
    local arry = {}
    local lastStart = string.find(data,sep,start)
    if (lastStart ~= nil) then
        count = count+1
    end
	--���Ҫ��β����ǰ�����table.insert(arry,1,string.sub(data, start, lastStart-1))
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
		--TODO:˫ָ��
		-- lastStart = string.find(data, sep, start+1)
    end
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

function num2location_v4(argt)
	--���ϵͳ��ʼ״̬
	local BeginTime = os.time()
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
	local EndTime = os.time()
	 local TimeCost = EndTime - BeginTime	--ʱ����ʵû���κ����壬slrun�᷵�صȴ�ʱ���ִ��ʱ�䣬���һ���ȷ��С�����3λ(��λ��)
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

--��Σ��ļ���
--�� �ܣ����ı����л��ֺ󣬸��ķ�ʡ����е����ţ�����������Ŵ������ݿ�
function oneFile(docname)

	local oneProvince = {}
	local r = getTable(docname)	--r���������ļ�(����)
	logf("One file data r = %s",table2json(r))
	
	for i,v in pairs(CAPCITY) do 
		logf("i = %s, v = %s",i, v)
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
--TODO��PROVINCEARRAY[province]����û��Ҫ ��ȫ�ֱ�����ÿ����һ���ֲ������Ϳ�����
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
	
	--��ȡʡ��������ţ���Ϊʡ��
	--������ͨ��ʡ�����ƻ�ȡʡ�ţ��ƺ�Ҳ�����˹���ȡʡ��
	local capitalID
	for i,v in pairs(PROVINCEARRAY[province]) do
	--ʷ��ǰ����ʹ�õ�����ά���飬�򵥵Ľ���һ��
	--PROVINCEARRAY[province]��provinceʡ��ȫ�����ݣ���������
	--PROVINCEARRAY[province][i]�ǵ�i�У����� �㽭�����ݣ�571,1510000 �����һ��
	--PROVINCEARRAY[province][2]�ǵ�2�У��ڶ����ǳ�����
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

--���ܣ���һ��table�ڵĵ�3��(����)�͵�4��(����)�������ݿ�
--��Σ�oneProvince:table
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
