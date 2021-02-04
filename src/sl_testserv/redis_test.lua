-- include "sdc"
include "http"
include "redis"
-- include "eoputil"
-- include "eopglobletab"
-- include "conf"

local function delRedis(argt)
	for i = 1,999 do
		redis.exec("DEL %s",i)
	end
	
	local response = {}
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


local function setredis(argt)
	local a = argt.a
	local b = argt.b
	local c = argt.c
	local subsid = argt.subsid
	local Locationrequestid, messageid, number = a,b,c
	--redis.exec("HMSET %s f1 %s f2 %s f3 %s",subsid,a,b,c)
	--redis.exec("SET %s %s EX 30", Locationrequestid, messageid .."|" ..number)
	redis.exec("SET REQUESTID %s EX 3600",messageid)
	--logf("redis  over")
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

local function getredis(argt)
	
	local key = argt.key
	--local r = redis.exec("HMGET %s f1 f2 f3",subsid)
	local r = redis.exec("GET %s",key)
	logf("r = %s",table2json(r))
	local response = {}
	-- response.f1 = f1
	-- response.f2 = f2
	-- response.f3 = f3
	response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

local function globaltest1(argt)
	logf("make global1")
	logf("argt=%s",table2json(argt))
	local a = argt.a
	local b = argt.b
	local c = argt.c
	global1 = a..b..c
	logf("global1=")
	logf(global1)
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

local function globaltest2(argt)
	logf("with global1 in same file")
	logf("argt=%s",table2json(argt))
	logf("global1=")
	logf(global1)
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

function tbSetRedis(argt)
			-- local argt = {}
			local callidentifier = "333"
			local sponsor = "1"
			local SEP_APP_ID = "ID"
			local plat = "0"
			local Cap_Host = ""
            local r = redis.exec({"HMSET", callidentifier, "sponsor", sponsor, "APPID", SEP_APP_ID, "plat", plat, "platurl", Cap_Host})
			-- local r = redis.exec("HMSET "..callidentifier.." sponsor "..sponsor.." APPID "..SEP_APP_ID.." plat "..plat.." platurl "..Cap_Host)
			logf(table2json(r))
	
			
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

function tbGetRedis(argt)
    
	local callidentifier = "333"
	local r = redis.exec({"HMGET", callidentifier, "sponsor", "APPID", "plat", "platurl"})		
	-- local r = redis.exec("HMGET "..callidentifier.." sponsor APPID plat platurl")		
	logf(table2json(r))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end
-- 随机获取AAC地址&删除指定AAC地址
function setTbRedis_v1(argt)

	
	local r = redis.exec({"SMEMBERS", "AACHOST_LIST"})
	logf(table2json(r))
	
	local srandResult = redis.exec("SRANDMEMBER AACHOST_LIST 1")
	logf(table2json(srandResult))
	logf("srandResult.Result = %s",srandResult.Result[1])
	
	if argt.flag == "1" then
		local sremResult = redis.exec("SREM AACHOST_LIST zhejiang.aac.eop.ebupt")
		logf(table2json(sremResult))
	end	
	
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
end


function incrRedis_v1(argt)

	local sisResult = redis.exec("SISMEMBER AACHOST_LIST zhejiang.aac.eop.ebupt")
	logf(table2json(sisResult))
	
	

	local srandResult = redis.exec("SRANDMEMBER AACHOST_LIST 1")
	logf(table2json(srandResult))
	logf("srandResult.Result = %s",srandResult.Result[1])

	local incrResult = redis.exec("INCR %s",srandResult.Result[1])
	logf("incrResult = %s",table2json(incrResult))
	local failedTime = 300
	redis.exec("EXPIRE %s %s", srandResult.Result[1], failedTime)
	
	if incrResult.Result == 7 then
		local sremResult = redis.exec("SREM AACHOST_LIST %s",srandResult.Result[1])
		redis.exec("DEL %s",srandResult.Result[1])
		logf(table2json(sremResult))
	end
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)
	

end


function hmset_v1(argt)

	local hmsetResult = redis.exec("HMSET DETECT_SCPHOST_LIST 16.scp 300 18.scp 270")
	logf(table2json(hmsetResult))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)
	

end


function hgetall_v1(argt)

	local hgetallResult = redis.exec("HGETALL DETECT_SCPHOST_LIST")
	logf(table2json(hgetallResult))
	
	for i,v in pairs (hgetallResult.Result) do
		logf("i = %s, v = %s",i,v)
	end
	
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)
	

end

function set_v1(argt)

	local scardResult = redis.exec("SCARD AACHOST_LIST")
	logf(table2json(scardResult))
	for i,v in pairs (scardResult) do
		logf("i = %s, v = %s",i,v)
	end
	
	local sisResult = redis.exec("SISMEMBER AACHOST_LIST zhejiang.aac.eop.ebupt")
	logf(table2json(sisResult))
	for i,v in pairs (sisResult) do
		logf("i = %s, v = %s",i,v)
	end

	local smembersResult = redis.exec("SMEMBERS AACHOST_LIST")
	logf(table2json(smembersResult))
	for i,v in pairs (smembersResult.Result) do
		logf("i = %s, v = %s",i,v)
	end
	
	-- logf("scardResult.Result = %s, sisResult.Result = %s, smembersResult.Result = %s",scardResult.Result, sisResult.Result, smembersResult.Result)
	
	
	logf("smembersResult.Result = %s",table2json(smembersResult.Result))
	
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)
end





lib_cmdtable["delRedis_v1"] = delRedis	--curl -v -k http://127.0.0.1:6081/testserv/v1/delRedis
lib_cmdtable["setredis_v1"] = setredis
lib_cmdtable["getredis_v1"] = getredis	--curl -v -k http://127.0.0.1:6081/testserv/v1/getredis -d '{"key":"tps"}'
lib_cmdtable["globaltest1_v1"] = globaltest1
lib_cmdtable["globaltest2_v1"] = globaltest2
lib_cmdtable["tbSetRedis_v1"] = tbSetRedis
lib_cmdtable["tbGetRedis_v1"] = tbGetRedis	--curl -v -k http://127.0.0.1:6081/testserv/v1/tbSetRedis -d '{"flag":"0","subsid":"subsid1"}'
lib_cmdtable["setTbRedis_v1"] = setTbRedis_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/setTbRedis -d '{"flag":"1","subsid":"subsid1"}'
lib_cmdtable["incrRedis_v1"] = incrRedis_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/incrRedis -d '{"flag":"1","subsid":"subsid1"}'
lib_cmdtable["hmset_v1"] = hmset_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/hmset -d '{"flag":"1","subsid":"subsid1"}'
lib_cmdtable["hgetall_v1"] = hgetall_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/hgetall -d '{"flag":"1","subsid":"subsid1"}'
lib_cmdtable["set_v1"] = set_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/set
