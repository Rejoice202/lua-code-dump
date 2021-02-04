include "nms"

APINAME_SCPAS = {
	["/testserv/v1/servTpsStatistics"] = "CallEventNotify",
	["/testserv/v2/servTpsStatistics"] = "MessageStatusNotification",
	["/testserv/v3/servTpsStatistics"] = "DownIVRFile",
}

-- 分省SCPAS/分API统计TPS:接收消息
function servTpsStatistics(argt)

	local response = {}
	response.apple = "banana"
	response.cat = "dog"

	-- logf("argt.HttpHeader.Url = %s",argt.HttpHeader.Url)
	local provinceId
	local api = APINAME_SCPAS[argt.HttpHeader.Url]
	logf("api = %s",api)
	-- 呼叫事件通知的省号为direction对应的号码归属省
	if api == "CallEventNotify" then
		provinceId = getNotifyCallEventProvinceId(argt)
	elseif api == "MessageStatusNotification" then
	-- 除了呼叫事件通知就只有USSD状态上报，目前只有浙江SCP
		provinceId = 16
	else
		return sendAck({ Retn = "200", Desc = HTTPCODE["200"]},response)
	end
	local key = "_tps_"..provinceId.."_"..api
	local incrResult = redis.exec("INCR "..key)
	
	response.key = key
	response.incrResult = incrResult.Result
	return sendAck({ Retn = "200", Desc = HTTPCODE["200"]},response)
	
end

function getNotifyCallEventProvinceId(argt)
	local provinceId
	if argt.direction == "MO" then
		provinceId = 0	--string.find(c2DomainName(calling,"scp"),"(%S)%.scp")
	elseif argt.direction == "MT" then
		provinceId = 1
	end
	return provinceId
end


-- 上报统计的TPS
function tpsReport()
	
	local response = {}
	response.code = "0000000"
	response.description = WEBCODE[response.code]

	local jobId = "081015"	--081015 分省SCPAStps业务统计
	local rawTime = os.time()
	local rptTime = os.date("%Y-%m-%d %H:%M:%S", rawTime - rawTime % 60)	--2020-04-04 21:58:00
	local rptData = {
		{"provinceid", "downivrfile", "callevents", "ussd", "domainselect"},
	}
	local ivrTps, callTps, ussdTps, dataTps
	
	local key
	for index,provinceId in pairs(PROVINCEID_SCPAS) do
		key = "_tps_" .. provinceId .. "_"
		ivrTps = getTps(APINAME_IVR, key)
		callTps = getTps(APINAME_CALL, key)
		ussdTps = getTps(APINAME_USSD, key)
		dataTps = getTps(APINAME_DATA, key)
		table.insert(rptData, {provinceId, ivrTps, callTps, ussdTps, dataTps})
	end
	
	logf("jobId = %s, rptTime = %s, rptData = %s",jobId, rptTime, table2json(rptData))
	-- logf("rptData[1] = %s",table2json(rptData[1]))
	local rptpfmcResult = nms.rptpfmc(jobId, rptTime, rptData)
	response.code = rptpfmcResult.Retn
	response.description = rptpfmcResult.Desc
	-- logf("rptpfmcResult = %s",table2json(rptpfmcResult))
	if rptpfmcResult.Retn ~= "0000" then
		warnf("report eop data failure: Retn=%s, Desc=%s", rptpfmcResult.Retn, rptpfmcResult.Desc)
		return sendAck({Retn = "500", Desc = HTTPCODE["500"]}, response)
	end	
	
	return sendAck({Retn = "200", Desc = HTTPCODE["200"]}, response)
end

function getTps(APINAME_SET, key)

	local tps = 0
	local key_api
	for i,api in pairs(APINAME_SET) do
		key_api = key .. api
		local getIncr = redis.exec("GET "..key_api)
		if getIncr.Result then
			redis.exec("DEL "..key_api)
			tps = tps + getIncr.Result
		end
	end
	return tps
	
end


lib_cmdtable["servTpsStatistics_v1"] = servTpsStatistics	--curl -v -k http://127.0.0.1:6081/testserv/v1/servTpsStatistics -d '{"direction":"MO"}'
lib_cmdtable["servTpsStatistics_v2"] = servTpsStatistics	--curl -v -k http://127.0.0.1:6081/testserv/v2/servTpsStatistics
lib_cmdtable["servTpsStatistics_v3"] = servTpsStatistics	--curl -v -k http://127.0.0.1:6081/testserv/v3/servTpsStatistics
lib_cmdtable["tpsReport_v1"] = tpsReport	--curl -v -k http://127.0.0.1:6081/testserv/v1/tpsReport
