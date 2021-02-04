--[[
local mt = { __index = access }

 access = {
   
}


--新建access对象
function access.new(self)
    return setmetatable({}, mt) 
end
--]]
local function checkUEID(argt)
	--local accessobj = access.new()
	
	local rule = {
	bindnumber = { mo = "O", ck = "^1[0-9]{10}$" },
	device_type = { mo = "O" },
	device_version = { mo = "O" },
	device_name = { mo = "O" },
	locationinfo = { mo = "O" },
	timestamp = { mo = "O" },
	failcode = { mo = "O" },
	reason = { mo = "M" }
	}
	--local r, e = check(accessobj.argt, rule)
	
	local r, e = check(argt, rule)
	
	if not r then
	logf("[ERROR]:Invalid parameter %s", e)
	
	end

	local a = true
	local b = false
	logf(type(a))
	logf(type(b))
	logf("%s",a)
	logf("%s",b)
	logf(a)
	logf(b)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


function checkDeliveryinfolist_v1(argt)

	logf("argt = %s",table2json(argt))
	logf(type(argt))
	logf(type(argt.deliveryinfolist))
	
	local Response = { 
        code        = "0000002",
        description = "Invalid Input Value"
    }

	local rule = {       
        sepid = { mo = "M" },
		deliveryinfolist  = { mo = "M" },
    }
    local r, e = check(argt, rule)
    if not r then 
        Response.description = Response.description ..": " ..e
        return sendAck({Retn = "400", Desc = "Bad Reauest"}, Response)
    end
	
	--待优化为ck = rule的嵌套参数校验
	local rule_deliveryinfolist = {       
		address = { mo = "M" },
		deliverystatus  = { mo = "M" },
		sendtime  = { mo = "O" },
    }
    local r, e = check(argt.deliveryinfolist, rule_deliveryinfolist)
    if not r then 
        Response.description = Response.description ..": " ..e
        return sendAck({Retn = "400", Desc = "Bad Reauest"}, Response)
    end
	
    return sendAck({Retn = "200", Desc = "ok"})

end

function checkDeliveryinfolist_v2(argt)
	
	logf("argt = %s",table2json(argt))
	logf(type(argt))
	logf(type(argt.deliveryinfolist))
	
	local Response = { 
        code        = "0000002",
        description = "Invalid Input Value"
    }

	local rule = {       
        sepid = { mo = "M" },
		deliveryinfolist = { mo = "M" },
		["deliveryinfolist/address"] = { mo = "M" },
		["deliveryinfolist/deliverystatus"] = { mo = "M" },
    }
    local r, e = check(argt, rule)
    if not r then 
        Response.description = Response.description ..": " ..e
        return sendAck({Retn = "400", Desc = "Bad Reauest"}, Response)
    end
	
    return sendAck({Retn = "200", Desc = "ok"})

end



lib_cmdtable["checkUEID_v1"] = checkUEID
lib_cmdtable["checkDeliveryinfolist_v1"] = checkDeliveryinfolist_v1	
lib_cmdtable["checkDeliveryinfolist_v2"] = checkDeliveryinfolist_v2	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/checkDeliveryinfolist -d '{"sepid":"sepid","deliveryinfolist":"subsid1"}'

	