include "redis"


INIT = 1000
END = 1100

function delNumtabmobInRedis_v1()

	for i = INIT,END,5 do 
		local numKey1 = "numtabmob_"..tostring(i)
		local numKey2 = "numtabmob_"..tostring(i+1)
		local numKey3 = "numtabmob_"..tostring(i+2)
		local numKey4 = "numtabmob_"..tostring(i+3)
		local numKey5 = "numtabmob_"..tostring(i+4)
		redis.exec("DEL %s %s %s %s %s",numKey1, numKey2, numKey3, numKey4, numKey5)
	end

	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)

end





function hmsetNumtabmobInRedis_v1()

	for i = 1000,9999,1 do 
		-- local numKey = "numtabmob_"..tostring(i)
		-- redis.exec("hmset %s %s %s %s %s",numKey, numKey2, numKey3, numKey4, numKey5)
		redis.exec(string.format("HSET numtabmob_%s %s %s", tostring(i), "1370000", "571"))
	end

	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.srandResult = srandResult.Result[1]
	return sendAck({ Retn = "200", Desc = "OK"},response)

end




lib_cmdtable["delNumtabmobInRedis_v1"] = delNumtabmobInRedis_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/delNumtabmobInRedis -d '{"flag":"1","subsid":"subsid1"}'

lib_cmdtable["hmsetNumtabmobInRedis_v1"] = hmsetNumtabmobInRedis_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/hmsetNumtabmobInRedis -d '{"flag":"1","subsid":"subsid1"}'
