-- require"printtable"
--require"socket"
local array = {1,2,3,4}
--ptb(os)
function selectOne(array)

--      math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6)) 
        math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 
        --math.randomseed(os.time())
        local random1 = math.random(1,#array)
        return array[random1]
    
end

-- v1有随机种子，v2没有
function getRandom_v1(argt)
	local count = {0,0,0,0}
	local r
	math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 
	
	local random1 = math.random(1,argt.randomTime)
	logf("random1 = %s",random1)
	
	for i =1,10000000 do
		local random1 = math.random(1,#array)
		--os.execute("sleep " .. 1)
		r = array[random1]
		count[r] = count[r] + 1 
		--print(r)
	end
	--print(count)
	-- local endTime = os.time()
	-- ptb(count)
	logf(table2json(count))
	-- local TimeCost = endTime-beginTime
	-- print("TimeCost = "..TimeCost)
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.count = count
	return sendAck({ Retn = "200", Desc = "OK"},response)

end


function getRandom_v2(argt)
	local count = {0,0,0,0}
	local r

	local random1 = math.random(1,argt.randomTime)
	logf("random1 = %s",random1)
	
	for i =1,10000000 do
		-- math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 
		local random1 = math.random(1,#array)
		--os.execute("sleep " .. 1)
		r = array[random1]
		count[r] = count[r] + 1 
		--print(r)
	end
	--print(count)
	-- local endTime = os.time()
	-- ptb(count)
	logf(table2json(count))
	-- local TimeCost = endTime-beginTime
	-- print("TimeCost = "..TimeCost)
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.code = "412"
	response.desc = HTTPCODE[response.code]..":666"
	return sendAck({ Retn = "200", Desc = HTTPCODE["200"]},response)

end

--HTTP状态码
HTTPCODE = {
	["Version"] = "RFC2616 HTTP 1.1",
    ["100"] = "Continue",
    ["101"] = "Switching Protocols",
    ["200"] = "OjbK",
    ["201"] = "Created",
    ["202"] = "Accepted",
    ["203"] = "Non-Authoritative Information",
    ["204"] = "No Content",
    ["205"] = "Reset Content",
    ["206"] = "Partial Content",
    ["300"] = "Multiple Choices",
    ["301"] = "Moved Permanently",
    ["302"] = "Found",
    ["303"] = "See Other",
    ["304"] = "Not Modified",
    ["305"] = "Use Proxy",
    ["307"] = "Temporary Redirect",
    ["400"] = "Bad Request",
    ["401"] = "Unauthorized",
    ["402"] = "Payment Required",
    ["403"] = "Forbidden",
    ["404"] = "Not Found",
    ["405"] = "Method Not Allowed",
    ["406"] = "Not Acceptable",
    ["407"] = "Proxy Authentication Required",
    ["408"] = "Request Timeout",
    ["409"] = "Conflict",
    ["410"] = "Gone",
    ["411"] = "Length Required",
    ["412"] = "Precondition Failed",
    ["413"] = "Request Entity Too Large",
    ["414"] = "Request-URI Too Long",
    ["415"] = "Unsupported Media Type",
	["416"] = "Requested Range Not Satisfiable",
	["417"] = "Expectation Failed",
	["409"] = "Conflict",
	["500"] = "Internal Server Error",
	["501"] = "Not Implemented",
	["502"] = "Bad Gateway",
	["503"] = "Service Unavailable",
	["504"] = "Gateway Timeout",
	["505"] = "HTTP Version Not Supported",
}



lib_cmdtable["getRandom_v1"] = getRandom_v1	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/getRandom -d '{"randomTime":"100"}'
lib_cmdtable["getRandom_v2"] = getRandom_v2	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v2/getRandom -d '{"randomTime":"100"}'
