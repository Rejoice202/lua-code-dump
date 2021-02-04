include "conf"
include "phone"
include "redis"
include "eopptb"
include "sdc"

--号码-自定义域名
local function c2domainName (phonenumber)

	logf("phonenumber = %s",phonenumber)

	if #phonenumber == 13 then
		logf("MSISDN +86")
		local phonenumber = string.sub(phonenumber,3,-1)
		logf("-86 phonenumber = %s",phonenumber)
		local locationid = phone.getLocationId(phonenumber)
	
		local location2domain = TEST_DB_CACHE.location2domain
		local domain = location2domain.pk(tonumber(locationid))
	
		return domain.domainName
	end
	
	logf("phonenumber = %s",phonenumber)
	
	local locationid = phone.getLocationId(phonenumber)
	
	local location2domain = TEST_DB_CACHE.location2domain
	local domain = location2domain.pk(tonumber(locationid))
	
	return domain.domainName
end

local function getlocationid (argt)

--[[是否是号码
	local MOisnum = phone.isMobile(argt.calling)
	local MTisnum = phone.isMobile(argt.called)
	
	logf("MOisnum = %s",MOisnum)
	logf("MTisnum = %s",MTisnum)


	local MOid = phone.getLocationId(argt.calling)
	local MTid = phone.getLocationId(argt.called)
	
	logf("MOid = %s",MOid)
	logf("MTid = %s",MTid)
	
	local MOprovinceid = phone.getProvinceId(MOid)
	local MTprovinceid = phone.getProvinceId(MTid)
	
	logf("MOprovinceid = %s",MOprovinceid)
	logf("MTprovinceid = %s",MTprovinceid)
	
	local location2domain = TEST_DB_CACHE.location2domain
	local MOdomain = location2domain.pk(tonumber(MOid))
	local MTdomain = location2domain.pk(tonumber(MTid))
	
	logf("MO domainname = %s",MOdomain.domainName)
	logf("MT domainname = %s",MTdomain.domainName)
	--]]
	local MOdomain = c2domainName(argt.calling)
	local MTdomain = c2domainName(argt.called)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.MO = MOdomain
	response.MT = MTdomain
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

lib_cmdtable["getlocationid_v1"] = getlocationid
