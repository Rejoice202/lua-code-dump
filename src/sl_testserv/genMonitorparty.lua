include "sdc"
include "http"
include "redis"
include "eoputil"
include "eopglobletab"
include "conf"

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
	
	local subsid = argt.subsid
	--local r = redis.exec("HMGET %s f1 f2 f3",subsid) --正确的代码
	local r = redis.exec("HMGET %s cat dog fish ",subsid)
	--logf("redis over")
	local f1 ,f2 ,f3 = r.Result[1],r.Result[2] ,r.Result[3] 
	local response = {}
	response.f1 = f1
	response.f2 = f2
	response.f3 = f3
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
            -- local r = redis.exec({"HMSET", callidentifier, "sponsor", sponsor, "APPID", SEP_APP_ID, "plat", plat, "platurl", Cap_Host})
			local r = redis.exec("HMSET "..callidentifier.." sponsor "..sponsor.." APPID "..SEP_APP_ID.." plat "..plat.." platurl "..Cap_Host)
			logf(table2json(r))
	
			
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

function tbGetRedis(argt)
    
	local callidentifier = "333"
	-- local r = redis.exec({"HMGET", callidentifier, "sponsor", "APPID", "plat", "platurl"})		
	local r = redis.exec("HMGET "..callidentifier.." sponsor APPID plat platurl")		
	logf(table2json(r))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.globalExist = global1
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

function genMonitorparty(argt)
	local initial = 10000
	redis.exec("incr count")
	local r = redis.exec("get count")
	-- logf("r = %s",table2json(r))
	logf("r.Result = %s",r.Result)
	local number = initial + tonumber(r.Result)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.number = number
	return sendAck({ Retn = "200", Desc = "OK"},response)
	
end

function genMonitorparty_slr(argt)
	local initial = 10000
	
	local number = initial + tonumber(_SLENV.SLRSN)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.number = number
	return sendAck({ Retn = "200", Desc = "OK" },response)
	
end


--通过闭包来实现局部变量不断加一
function incr()
    incrvar = 0
    return function()	--尾调用
        incrvar = incrvar+1
        return incrvar
    end
end

function genMonitorparty_fn(argt)
	local initial = 10000
	c1 = incr()
	logf("c1 = %s",c1())
	logf("c1 = %s",c1())
	logf("c1 = %s",c1())
	local number = initial + c1()
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.number = number
	return sendAck({ Retn = "200", Desc = "OK" },response)
	
end



-- lib_cmdtable["setredis_v1"] = setredis
-- lib_cmdtable["getredis_v1"] = getredis
-- lib_cmdtable["globaltest1_v1"] = globaltest1
-- lib_cmdtable["globaltest2_v1"] = globaltest2
-- lib_cmdtable["tbSetRedis_v1"] = tbSetRedis
-- lib_cmdtable["tbGetRedis_v1"] = tbGetRedis	--curl -v -k http://127.0.0.1:6081/testserv/v1/tbSetRedis -d '{"flag":"0","subsid":"subsid1"}'
lib_cmdtable["genMonitorparty_v1"] = genMonitorparty_redis	--curl -v -k http://127.0.0.1:6081/testserv/v1/genMonitorparty -d '{"flag":"0","subsid":"subsid1"}'
lib_cmdtable["genMonitorparty_v2"] = genMonitorparty_slr	--curl -v -k http://127.0.0.1:6081/testserv/v2/genMonitorparty -d '{"flag":"0","subsid":"subsid1"}'
lib_cmdtable["genMonitorparty_v3"] = genMonitorparty_fn	--curl -v -k http://127.0.0.1:6081/testserv/v3/genMonitorparty -d '{"flag":"0","subsid":"subsid1"}'
