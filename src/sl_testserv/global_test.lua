include "sdc"
include "http"
include "redis"
include "eoputil"
include "eopglobletab"
include "conf"


local function globaltest3(argt)
	
	logf("in same server, other file")
	logf("argt=%s",table2json(argt))

	local events = {"Begin","Answer","Release"}
    logf("events = %s",table2json(events))

	-- logf("global1=")
	-- logf(global1)
	local url = "http://10.1.35.10:18788/v1/scep/subscriptions/callevents/notifications/number"
	local r = http.post("demo",url,events)
	logf("r = %s",table2json(r))
	
	local result = {}
	aacTimeoutCode = "100"
	aacTimeoutDesc = HTTPCODE[aacTimeoutCode]
	callhttpTimeoutCode = "1999"
	if r.Retn == callhttpTimeoutCode then
		result.code = aacTimeoutCode
		result.description = aacTimeoutDesc
		sendAck({Retn = "500", Desc = HTTPCODE["500"]}, result)
	end
	
	
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.events = events
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

--[[
local function globaltest2(argt)

	logf("argt=%s",table2json(argt))
	logf("global1=")
	logf(global1)
	return sendAck({ Retn = "200", Desc = "OK"})
end
--]]

lib_cmdtable["globaltest3_v1"] = globaltest3	
-- curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/globaltest3 -d '{"randomTime":"100"}'
