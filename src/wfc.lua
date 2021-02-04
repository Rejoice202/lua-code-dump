include "http"
include "redis"
include "crypto"
include "access"
include "comm"
include "wfc_conf"
include "db"

SERVICE_ID = wfc_conf.SERVICE_ID

------------公共函数--------------------begin--------------------

--记录用户日志信息
local function registerUserLogInfo(appkey, usernumber, imei, imsi, deviceversion, devicename, locationinfo, authcode, stage, result, resultdesc)

	local errcode, affected_rows = db.saveUserLogInfoDB(appkey, usernumber, imei, imsi, deviceversion, devicename, locationinfo, authcode, stage, result, resultdesc)
	if affected_rows < 0 then
		logf("[ERROR]:save wfc_userinfolog table failed")
		return false, 200, "30000001", access.errcode["30000001"]
	end
	return true
end

--记录用户信息
local function registerUserInfo(appkey, usernumber, domainname, verifnumber, sipcode, sippasswd, siprelay, siprelaypasswd)

	local errcode, affected_rows = db.saveUserInfoDB(appkey, usernumber, domainname, verifnumber, sipcode, sippasswd, siprelay, siprelaypasswd)
	if affected_rows < 0 then
		logf("[ERROR]:save wfc_userinfo table failed")
		return false, 200, "30000001", access.errcode["30000001"]
	end
	return true
end

--校验验证码
local function checkVerificationCode(appkey, phonenumber, verificationcode)
	if phonenumber == nil then
		logf("[ERROR]:Invalid parameter - verifnumber")
		return false, 200 , "20000001", access.errcode["20000001"] .. "verifnumber"
	end
	if phonenumber ~= wfc_conf.verificationcode.freecheckbindnumber then
		--不是免校验验证码的号码
		local ok, verificode = db.getVerification(appkey .. "_" .. phonenumber)
		if not ok then
			--验证码超过有效期
			logf("[ERROR]:verification code outtime")
			return false, 200, "20000009", access.errcode["20000009"]
		end

		if tonumber(verificationcode) ~= tonumber(verificode) then
			--验证码错误
			logf("[ERROR]:verification code error, right verificode=%s", verificode)
			return false, 200, "20000008", access.errcode["20000008"]
		end
	end
	logf("[NOTICE]:check verification code success")
	return true, 200, "00000000", access.errcode["00000000"]
end

--[[
return : true:用户免位置鉴权
         false：用户不免位置鉴权
]]

local function checkUsernoLocationAuth(usernumber, domainname)
	local ok, usertype, begintime, endtime = db.selectUsernoLocationAuth(usernumber, domainname)
	if ok then
	
		if tonumber(usertype) == 1 then
			--1：测试用户，不用查看时间段
			
			return true
		elseif tonumber(usertype) == 2 then
			--2：企业白名单用户，需查看时间段，在有效期内
			local currenttime = comm.getCurrentTime(0)
			if tonumber(currenttime)>=tonumber(begintime) and tonumber(currenttime)<=tonumber(endtime) then
				
				return true
			end
		end
	end
	return false
end

local function judgeLocationInfo(usernumber, locationinfo, app)
	--查看用户的设备类型
	local ok, _, _, _, _, devicetype = db.selectUserAuthInfoDB(usernumber, app["domainname"])
	
	local locationStr2 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 2)
	local locationStr4 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 4)
	logf("[NOTICE]:locationinfo=%s locationStr2=%s,location=%s",gb_utf8(locationinfo),locationStr2,app["location"])
	
	if devicetype == "iOS" then
	
		if (tonumber(app["location"])==2) and (((locationStr2 == gb_utf8("中国")) and (gb_utf8(locationinfo) ~= gb_utf8("中国")) and locationStr4 ~= gb_utf8("中国香港") and locationStr4 ~= gb_utf8("中国澳门") and locationStr4 ~= gb_utf8("中国台湾")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") or (locationinfo == "no activate location authority") or (locationinfo == "")) then
			--使用位置限制在国外
			
			logf("[ERROR]:not right place to login : %s", gb_utf8(locationinfo))
			return false
		end
	elseif devicetype == "android" then
	
		if (tonumber(app["location"])==2) and (((locationStr2 == gb_utf8("中国")) and (gb_utf8(locationinfo) ~= gb_utf8("中国")) and locationStr4 ~= gb_utf8("中国香港") and locationStr4 ~= gb_utf8("中国澳门") and locationStr4 ~= gb_utf8("中国台湾")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") or (locationinfo == "no activate location authority")) then
			--使用位置限制在国外
			
			logf("[ERROR]:not right place to login : %s", gb_utf8(locationinfo))
			return false
		end
	end
	return true
end

local function judgeIpInfo(client_ip, app)
	local ok = db.selectSatelliteIp(client_ip, app["domainname"])
	if not ok then
		logf("[ERROR]:not right satellite ip to login : %s", client_ip)
		return false
	end
	return true
end

--判断终端所处地区位置
local function judgeLocation(usernumber, locationinfo, client_ip, app)

	if tonumber(app["locationstate"]) == 1  then
		--位置安全开关开启
		local ok_locationauth = checkUsernoLocationAuth(usernumber, app["domainname"])
		if ok_locationauth then
			--用户在免位置鉴权表中，无需判断当前所处的位置
			logf("[NOTICE]:usernumber=%s, in no need location auth, no need to judge location", usernumber)
			return true
		else
			if tonumber(app["satellitestate"]) == 0 then
				--不是卫星通信业务
				if locationinfo ~= nil then
				
					local ok = judgeLocationInfo(usernumber, locationinfo, app)
					if not ok then
						return false, locationinfo
					end
				end
				return true
			elseif tonumber(app["satellitestate"]) == 1 then
				--卫星通信业务 判断是否为卫星通信的ip
				local ok = judgeIpInfo(client_ip, app)
				if not ok then
					return false, client_ip
				end
				return true
			end
		end
	else
		logf("[NOTICE]:usernumber=%s, locationstate=%s, no need to judge location", usernumber, app["locationstate"])
		return true
	end
end

--查询SIM卡的位置
local function checkSimLocationToWfcAs(url, bindnumber)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["bindnumber"] = bindnumber
	}
	
	logf("[NOTICE]:***********************send check SIM location to wificallingAS, url=%s, httpBody=%s", url, table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send check SIM location to wificallingAS failed, response Header status=%s", r.Retn)
		return false, r
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send check SIM location to wificallingAS failed, response body code=%s", r.code)
		return false, r
	end
	logf("[NOTICE]:send check SIM location to wificallingAS success")
	return true, r

end

--判断是否需要走机卡分离校验流程  true:不需要    false:需要
local function judgedevSimornot(usernumber)
	logf("[NOTICE]:devsimfuncstate=%d", wfc_conf.testfunc.devsimfuncstate)
	if wfc_conf.testfunc.devsimfuncstate == 0 then
		--机卡分离功能校验开关关闭
		
		--查看用户号码是否为测试号码
		local ok, count = db.selectTestNumberCount(usernumber, "1")
		if ok and tonumber(count) == 0 then
			logf("[NOTICE]:usernumber=%s not test number", usernumber)
			return true
		else
			logf("[NOTICE]:usernumber=%s is test number", usernumber)
		end
	end
    return false
end

--机卡分离校验
local function devSimAuthFunc(usernumber, domainname, devsimstate, locationinfo)
	
	--判断是否需要走机卡分离校验流程  true:不需要    false:需要
	local ok = judgedevSimornot(usernumber)
	if ok then
		logf("[NOTICE]:usernumber=%s no need do devsimauth", usernumber)
		return true
	end
	
	--判断号码是否为华侨通用户
	logf("[NOTICE]:devsimstate=%s ", devsimstate)	

	--判断号段是否为温州丽水
	local district = db.checkPhoneNumber(usernumber)
	logf("[NOTICE]:district=%s ", district)
	
	--判断号码是否在机卡分离校验白名单
	local ok_whitelist, count = db.selectDevSimWhitelist(usernumber)
	if ok_whitelist and tonumber(count) == 0 then
		logf("[NOTICE]:usernumber=%s not in devsimwhitelist", usernumber)
	else
		logf("[NOTICE]:usernumber=%s in devsimwhitelist", usernumber)
	end
	--判断号码是否已做过机卡分离校验
	local ok_devsimauth, result = db.SisMemberRedis("DevSimAuth", usernumber .. "_" .. domainname)
	if ok_devsimauth and tonumber(result) == 0 then
		logf("[NOTICE]:usernumber=%s not yet do devsim auth", usernumber)
	else
		logf("[NOTICE]:usernumber=%s already did devsim auth", usernumber)
	end
	--判断机卡分离校验是否在开户or换卡后的十分钟内
	local ok_devsimusertime = db.getVerification("Devsimusertime_" .. usernumber .. "_" .. domainname)
	if ok_devsimusertime then
		logf("[NOTICE]:usernumber=%s within times", usernumber)
	else
		logf("[NOTICE]:usernumber=%s without times", usernumber)
	end
	
	--华侨通用户and号码非温州非丽水and号码不在白名单and没做过机卡分离校验and开户后的十分钟内
	if (tonumber(devsimstate) == 1) and (district == "other") and (ok_whitelist and tonumber(count) == 0) and (ok_devsimauth and tonumber(result) == 0) and (ok_devsimusertime) then
		
		logf("[NOTICE]:usernumber=%s get SDK  device location info=%s", usernumber, locationinfo)
		if (locationinfo ~= "get location authority failed") and (locationinfo ~= "no activate location authority") and (locationinfo ~= "") then
		
			--调用wifias接口获取卡所在的地区
			local ok, r = checkSimLocationToWfcAs(wfc_conf.wfcAs.checkSimLocation, usernumber)
			if ok and (r.countrycode == "86" or r.mscaddress == "") then
				logf("[NOTICE]:usernumber=%s get wifias sim location info=%s", usernumber, r.country_en)
				
				local locationStr2 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 2)
				local locationStr4 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 4)
				
				if (locationStr2 == gb_utf8("中国") and locationStr4 ~= gb_utf8("中国香港") and locationStr4 ~= gb_utf8("中国澳门") and locationStr4 ~= gb_utf8("中国台湾")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") then
					
					--记录标识该号码已经做过机卡分离校验
					db.SetAddRedis("DevSimAuth", usernumber .. "_" .. domainname)
				else
					return false
				end
			end
		end
	end
	
	return true
end

--判断imei是否改变
--[[
	return: 1  该用户未注册
			2  imei发生变化
			3  imei未发生变化
]]
local function judgeIMEI(original_imei, current_imei, app)
	if tonumber(app["imeistate"]) == 1 then
		--imei安全开关开启
		if original_imei ~= current_imei then
			--imei发生变化
			return false
		end
		--imei未发生变化
		return true
	else
		--imei安全开关关闭
		logf("[NOTICE]:imei state=%s",app["imeistate"])
		return true
	end
end


--极光推送消息
local function notifyPushAndroid(url, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
--[[
	{
		"platform": "all",
		"audience": {
			"registration_id" : [ "4312kjklfds2", "8914afd2", "45fdsa31" ]
		},
		"message": {
			"msg_content": "offline"
		}
	}
]]
	local str = app["jpushappkey"] .. ":" .. app["jpushsecret"]
	local httpHeader = {
		["Authorization"] = "Basic " .. base64Encode(str)
	}
	local httpBody = {
		["platform"] = "all",
		["audience"] = {
			["registration_id"] = {}
		},
		["message"] = {
			["msg_content"] = content
		},
		["options"] = {
			["apns_production"] = true  --推送生产环境
		}
	}
	
	table.insert(httpBody.audience.registration_id, originaldevicecode)
	
	logf("[NOTICE]:***********************push notify to JIGUANG, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("JPush", url, httpHeader, httpBody)
	logf("[NOTICE]:response from JIGUANG = %s", table2json(r))
	
	--记录推送用户下线通知日志
	db.savePushofflineLogInfoDB(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, r.Retn)
	
	if r.Retn ~= "200" then
		logf("[ERROR]:push notify to JIGUANG failed, response Header status=%s", r.Retn)
		return
	end
	logf("[NOTICE]:push notify to JIGUANG success")
	return
end

--极光推送消息
local function notifyPushIos(url, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
--[[
	{
		"platform": "all",
		"audience": {
			"registration_id" : [ "4312kjklfds2", "8914afd2", "45fdsa31" ]
		},
		"notification": {
			"alert": "offline",
			"ios": {
				"extras": {
					"notify_type":"5"
				}
			}
		}
	}
]]
	local str = app["jpushappkey"] .. ":" .. app["jpushsecret"]
	local httpHeader = {
		["Authorization"] = "Basic " .. base64Encode(str)
	}
	local httpBody = {
		["platform"] = "all",
		["audience"] = {
			["registration_id"] = {}
		},
		["notification"] = {
			["alert"] = content,
			["ios"] = {
				["extras"] = {
					["notify_type"] = "5"
				}
			}
		},
		["options"] = {
			["apns_production"] = true  --推送生产环境
		}
	}
	
	table.insert(httpBody.audience.registration_id, originaldevicecode)
	
	logf("[NOTICE]:***********************push notify to JIGUANG, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("JPush", url, httpHeader, httpBody)
	logf("[NOTICE]:response from JIGUANG = %s", table2json(r))
	
	--记录推送用户下线通知日志
	db.savePushofflineLogInfoDB(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, r.Retn)
	
	if r.Retn ~= "200" then
		logf("[ERROR]:push notify to JIGUANG failed, response Header status=%s", r.Retn)
		return
	end
	logf("[NOTICE]:push notify to JIGUANG success")
	
	return
end

--通知wificallingAS该用户不能通话(可批量设置)
local function setUserCallUnavailable(url, phoneinfo, barringtype, lockreason, timerlogflag, desc)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["lockflag"] = "1",   --1：闭锁
		["barringtype"] = barringtype,
		--[[1：呼出  2：呼入  3：MO短信  4: MT短信   5: 呼出、呼入、MO短信、MT短信]]
		["lockreason"] = lockreason
		--[[闭锁原因1：鉴权超时2、不在正确的位置3、换卡]]
	}
	httpBody.phoneinfo = {}
	if type(phoneinfo) == "table" then
		httpBody.phoneinfo = phoneinfo
	elseif type(phoneinfo) == "string" then
		table.insert(httpBody.phoneinfo, phoneinfo)
	end
	
	logf("[NOTICE%s]:***********************send clock calling http to wificallingAS, url=%s,httpBody=%s",timerlogflag,url,table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE%s]:response from wificallingAS = %s",timerlogflag, table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR%s]:send clock calling http to wificallingAS failed, response Header status=%s",timerlogflag, r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR%s]:send clock calling http to wificallingAS failed, response body code=%s",timerlogflag, r.code)
		return false
	end
	logf("[NOTICE%s]:send clock calling http to wificallingAS success",timerlogflag)
	
	--记录解闭锁日志
	if type(phoneinfo) == "table" then
		for i=1, #phoneinfo do
			db.saveUserCallbarringLog(phoneinfo[i], httpBody.lockflag, httpBody.barringtype, desc)
		end
	elseif type(phoneinfo) == "string" then
		db.saveUserCallbarringLog(phoneinfo, httpBody.lockflag, httpBody.barringtype, desc)
	end
	
	return true
end

--通知wificallingAS该用户可以通话
local function setUserCallAvailable(url, phoneinfo, locationinfo)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["lockflag"] = "0",  --0：解锁
		["barringtype"] = "5",
		["locationinfo"] = locationinfo
	}
	httpBody.phoneinfo = {}
	if type(phoneinfo) == "table" then
		httpBody.phoneinfo = phoneinfo
	elseif type(phoneinfo) == "string" then
		table.insert(httpBody.phoneinfo, phoneinfo)
	end
	
	logf("[NOTICE]:***********************send release clock calling http to wificallingAS, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send release clock calling http to wificallingAS failed, response Header status=%s", r.Retn)
		return false, r
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send release clock calling http to wificallingAS failed, response body code=%s", r.code)
		return false, r
	end
	logf("[NOTICE]:send release clock calling http to wificallingAS success")
	
	--记录解闭锁日志
	if type(phoneinfo) == "table" then
		for i=1, #phoneinfo do
			db.saveUserCallbarringLog(phoneinfo[i], httpBody.lockflag, httpBody.barringtype, "auth request success")
		end
	elseif type(phoneinfo) == "string" then
		db.saveUserCallbarringLog(phoneinfo, httpBody.lockflag, httpBody.barringtype, "auth request success")
	end
	
	return true, r
end

--通知wificallingas检查imsi
local function notifyWfcAsCheckImsi(url, bindnumber)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["bindnumber"] = bindnumber
	}

	logf("[NOTICE]:***********************send notify wificallingAS check imsi, url=%s, httpBody=%s", url, table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send notify wificallingAS check imsi failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send notify wificallingAS check imsi failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send notify wificallingAS check imsi success")
	return true, r.imsi

end

--向wificallingAS发送新的授权码
local function notifyAuthCodeToWfcAs(url,authcode,bindnumber,domain)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["authcode"] = authcode,
		["bindnumber"] = bindnumber,
		["domain"] = domain
	}

	logf("[NOTICE]:***********************send authcode http to wificallingAS, url=%s, httpBody=%s", url, table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send authcode http to wificallingAS failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send authcode http to wificallingAS failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send authcode http to wificallingAS success")
	return true
end

--向wificallingAS发送切换设备
local function notifySwitchEquipToWfcAs(url,switchchannel,domain)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["switchchannel"] = switchchannel,
		["domain"] = domain
	}

	logf("[NOTICE]:***********************send switch equip http to wificallingAS, url=%s, httpBody=%s", url, table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send switch equip http to wificallingAS failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send switch equip http to wificallingAS failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send switch equip http to wificallingAS success")
	return true
end


--更新用户定时器
local function updateTimer(phonenumber,domain)
	local key = phonenumber .. "_" .. domain
	--在redis中删除用户记录
	local r = redis.get("wfc", key, 1)
	if(type(r) == "number" and r == -1) then
		logf("[ERROR_TIMER]:delete data timer failed")
		return false
	else
		logf("[NOTICE_TIMER]:delete data timer success")
	end

	--在redis中保存用户记录 redis.save("wfc", "用户号码_域名", "用户号码 域名")  
	local r = redis.save("wfc", key, phonenumber.." "..domain)
	if r == -1 then
		logf("[ERROR_TIMER]:save data timer failed")
		return false
	elseif r == 0 then
		logf("[ERROR_TIMER]:data timer already exit")
		return false
	end
	logf("[NOTICE_TIMER]:save timer data=%s", phonenumber.." "..domain)
	return true
end

-- 检查虚拟号码与表中为企业分配的虚拟号码是否匹配
local function checkVirtualNum(appkey, virtualnumber)

	local ok, mysqlDataNum, virtualnumTab = db.selectVirtualNumber(appkey)
	if not ok then
		logf("[ERROR]:App no match virtualnumber")
		return false, 200, "20000019", access.errcode["20000019"]
	end

    for i=1, mysqlDataNum do
        if string.sub(virtualnumber,1,string.len(virtualnumTab[i]["virtualnumber"]))==virtualnumTab[i]["virtualnumber"] then
			logf("[NOTICE]:App match virtualnumber=%s",virtualnumTab[i]["virtualnumber"])
			return true
        end
    end
	logf("[ERROR]:App no match virtualnumber")
	return false, 200, "20000019", access.errcode["20000019"]
end

--发送开户消息给EOP
local function sendOpenAccountInfoToEop(EOP_appkey, EOP_secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname, eopaddr)
	local function getSignature()
		local timestamp = string.format("%d", os.time())
		local tempsignature = crypto.hash("md5", timestamp .. EOP_secret)
		local signature = string.sub(tempsignature, 17, 32)
		return timestamp, signature
	end
	local function accesstypeFunc(accesstype)
	--[[
		0：SIP服务器对接
		1：SDK对接
	]]
		if tonumber(accesstype) == 1 then
			return "1"
		end
		return "0"
	end
	local timestamp, signature = getSignature()
	local url = eopaddr .. wfc_conf.EBEOP.openUserUri
	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8",
		["Authorization"] = " EBDATAVOICEAUTH appkey=" .. EOP_appkey .. ",timestamp=" .. timestamp .. ",signature=" .. signature
	}
	
	local httpBody = {
		["appkey"] = appkey,
		["bindnumber"] = bindnumber,
		["domain"] = domainname,
		["oaflag"] = oaflag,
		["accesstype"] = accesstypeFunc(accesstype),
		["sippasswd"] = sipuripassword,
		["siprelay"] = siprelay,
		["siprelaykey"] = siprelaypassword
	}

	logf("[NOTICE]:***********************send open account to EOP, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("EOP", url, httpHeader, httpBody)
	logf("[NOTICE]:response from EOP = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send open account to EOP failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send open account to EOP failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send open account to EOP success")
	return true
end

--向wificallingAS发送销户通知
local function closeAccountInfoToWfcAs(url, bindnumber, domain)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["bindnumber"] = bindnumber,
		["domain"] = domain
	}

	logf("[NOTICE]:***********************send close account to wificallingAS, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send close account to wificallingAS failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send close account to wificallingAS failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send close account to wificallingAS success")
	return true
	
end

--发送销户消息给EOP
local function sendCloseAccountInfoToEop(EOP_appkey, EOP_secret, appkey, bindnumber, domain, eopaddr)

	local function getSignature()
		local timestamp = string.format("%d", os.time())
		local tempsignature = crypto.hash("md5", timestamp .. EOP_secret)
		local signature = string.sub(tempsignature, 17, 32)
		return timestamp, signature
	end

	local timestamp, signature = getSignature()
	local url = eopaddr .. wfc_conf.EBEOP.closeUserUri
	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8",
		["Authorization"] = " EBDATAVOICEAUTH appkey=" .. EOP_appkey .. ",timestamp=" .. timestamp .. ",signature=" .. signature
	}
	
	local httpBody = {
		["appkey"] = appkey,
		["bindnumber"] = bindnumber,
		["domain"] = domain
	}

	logf("[NOTICE]:***********************send close account to EOP, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("EOP", url, httpHeader, httpBody)
	logf("[NOTICE]:response from EOP = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send close account to EOP failed, response Header status=%s", r.Retn)
		return false
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send close account to EOP failed, response body code=%s", r.code)
		return false
	end
	logf("[NOTICE]:send close account to EOP success")
	return true
end

------------公共函数---------------end-------------------------


--begin------------------下发验证码----------------------------

local function getSmsHttpHeader()
	--[[
		生成消息头X-WSSE需要的参数 
		PasswordDigest：根据公式PasswordDigest = Base64 (SHA256 (Nonce + Created + Password))生成。其中，Password即App Secret的值。
		Nonce：App发送请求时生成的一个随机数。例如，66C92B11FF8A425FB8D4CCFE0ED9ED1F。
		Created：随机数生成时间。采用标准UTC格式，为YYYY-MM-DD'T'hh:mm:ss'Z'。例如，2014-01-07T01:58:21Z。
	--]]
	local nonce = comm.genuuid()
	logf("[NOTICE]:nonce=%s",nonce)
	local tempCreated = comm.getUTCTime()
	logf("[NOTICE]:tempCreated=%s",tempCreated)
	local tempString = nonce .. tempCreated .. wfc_conf.verificationcode.LocalSecret
	logf("[NOTICE]:tempString before SHA256=%s",tempString)
	
	local finalsha256 = hex2bin(crypto.hash("SHA256", tempString))
	logf("[NOTICE]:finalsha256 after SHA256=%s",finalsha256)
	
	local passwordDigest = base64Encode(finalsha256)
	logf("[NOTICE]:passwordDigest=%s",passwordDigest)
	
	local httpHeader = {
		["Authorization"] = "WSSE realm=\"SDP\",profile=\"UsernameToken\",type=\"AppKey\"",
		["X-WSSE"] = "UsernameToken Username= \"".. wfc_conf.verificationcode.LocalAppkey .. "\",PasswordDigest=\"" ..
		passwordDigest .."\",Nonce=\"" .. nonce .. "\",Created=\"" .. tempCreated .. "\"",
        ["Accept"] = "application/json;charset=UTF-8",
		["Content-Type"] = "application/json;charset=UTF-8",
		["Host"] = "aep.sdp.com"
	}
	return httpHeader
end

local function getSmsHttpBody(verificode, bindnumber, aeptemplateid, verifivalidtime)
    local templateMsg = {}

    templateMsg.from = wfc_conf.verificationcode.From
    templateMsg.to = "86" .. bindnumber 
    templateMsg.smsTemplateId  = aeptemplateid --模版id
	templateMsg.paramValue  = {}
	templateMsg.paramValue.number = verificode --验证码
	if aeptemplateid == "7091c54c-cd09-4c31-bbdf-13a79a67ef27" then  --吉利下发验证码有效期短信
	
		templateMsg.paramValue.minute = verifivalidtime --验证码有效期
	end
	templateMsg.notifyURL = wfc_conf.verificationcode.notifyURL --异步通知地址
	return templateMsg
end

--调用下发短信验证码能力
local function sendSmsVerificationCode(verificode, appkey, bindnumber, alisignname, verifichannel, aeptemplateid, verifivalidtime)
	if tonumber(verifichannel) == 1 then  --1：AEP渠道
		--构造消息头
		
		local url = wfc_conf.verificationcode.SendURL
		local httpHeader = getSmsHttpHeader()
		
		--构造消息体
		local httpBody = getSmsHttpBody(verificode, bindnumber, aeptemplateid, verifivalidtime)
		
		logf("[NOTICE]:***********************send verification sms to AEP, url=%s, httpHeader=%s, httpBody=%s", url, table2json(httpHeader), table2json(httpBody))
		
		local r = http.post("AEP", url, httpHeader, httpBody)
		logf("[NOTICE]:response from AEP = %s", table2json(r))
		
		if r.Retn ~= "201" then
			logf("[ERROR]:send verification sms to AEP failed, response Header status=%s", r.Retn)
			
			db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.code, r.result.smsMsgId, '1', verificode)
			return false, r
		end
		if r.code ~= "000000" then
			logf("[ERROR]:send verification sms to AEP failed, response body code=%s", r.code)
			
			db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.code, r.result.smsMsgId, '1', verificode)
			return false, r
		end
		
		logf("[NOTICE]:send verification sms to AEP success")
		
		db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '0', r.Retn, r.code, r.result.smsMsgId, '1', verificode)
		return true, r
	elseif tonumber(verifichannel) == 2 then  --2：阿里渠道
	
		local url = wfc_conf.verificationcode.SendURL_ali
		logf("[NOTICE]:***********************send verification sms to ALI, url=%s", url)
		
		local templateParam = {}
		templateParam.code = tostring(verificode)
		logf("[NOTICE]:templateParam=%s", table2json(templateParam))
		
		local sortedQueryString = "AccessKeyId="..wfc_conf.verificationcode.AccessKeyId_ali.."&Action="..wfc_conf.verificationcode.Action_ali.."&Format=JSON&PhoneNumbers="..bindnumber.."&RegionId="..wfc_conf.verificationcode.RegionId_ali.."&SignName="..alisignname.."&SignatureMethod=HMAC-SHA1&SignatureNonce="..uuidgen().."&SignatureVersion=1.0&TemplateCode="..wfc_conf.verificationcode.TemplateCode_ali.."&TemplateParam="..table2json(templateParam).."&Timestamp="..comm.getUTCTime().."&Version="..wfc_conf.verificationcode.Version_ali
		
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)

--[[
		local strtosign = "GET&"..http.urlEncode("/").."&"..http.urlEncode(str)
		logf("[NOTICE]:strtosign=%s", strtosign)
		
		local sign = crypto.hash("HMACSHA1", strtosign, wfc_conf.verificationcode.AccessSecret_ali.."&")
		local signature = http.urlEncode(sign)
		logf("[NOTICE]:sign=%s, signature=%s", sign, signature)
		
		url = url .. "?Signature=" .. signature .. "&" .. str
		logf("[NOTICE]:***********************send verification sms to ALI, url=%s", url)
]]
		sortedQueryString = http.urlEncode(gb_utf8(sortedQueryString)) -- UTF8编码字符串转百分号编码
		sortedQueryString = string.gsub(sortedQueryString, ':', '%%3A') -- http.urlEncode()没有处理:，单独处理
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)

		local stringToSign = http.urlEncode(sortedQueryString)
		stringToSign = string.gsub(stringToSign, '%%', '%%25') -- 额外处理：% & =
		stringToSign = string.gsub(stringToSign, '&', '%%26')
		stringToSign = string.gsub(stringToSign, '=', '%%3D')
		stringToSign = 'GET&%2F&' .. stringToSign
		logf("[NOTICE]:stringToSign=%s", stringToSign)
					  
		local accessSecret = wfc_conf.verificationcode.AccessSecret_ali .. '&'
		local signData = base64Encode(hex2bin(crypto.hash('HMACSHA1', stringToSign, accessSecret)))
		logf("[NOTICE]:signData=%s", signData)

		local signature = http.urlEncode(signData)
		signature = string.gsub(signature, '/', '%%2F') -- 额外处理
		signature = string.gsub(signature, '=', '%%3D')
		url = url .. "?Signature=" .. signature .. '&' .. sortedQueryString

		logf("[NOTICE]:***********************send verification sms to ALI, url=%s", url)

		local r = http.get("AEP", url)
		logf("[NOTICE]:response from ALI = %s", table2json(r))
		
		if r.Retn ~= "200" then
			logf("[ERROR]:send verification sms to ALI failed, response Header status=%s", r.Retn)
			
			db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.Code, r.BizId, '2', verificode)
			return false, r
		end
		
		if r.Code ~= "OK" then
			logf("[ERROR]:send verification sms to ALI failed, response body Code=%s", r.Code)
			
			db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.Code, r.BizId, '2', verificode)
			return false, r
		end
		
		logf("[NOTICE]:send verification sms to ALI success")
		
		db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '0', r.Retn, r.Code, r.BizId, '2', verificode)
		return true, r
	end
end

-- 处理下发验证码
local function handleSmsVerification(argt)
--[[
	{
	"bindnumber": "13712345678",   用户真实号码
	"imei": "864399020227188"
	"registration_id": "170976fa8a8220f42d4" 推送设备编号
	"device_type": "android"     目前只有android/ios两个内容
	}

]]
	local accessobj = access.new()
	
	--检查下发验证码参数
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			imei = { mo = "O" },
			registration_id = { mo = "O" },
			device_type = { mo = "O" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
		if accessobj.argt.device_type ~= "wx" and accessobj.argt.imei == "" then
			return false, 200 , "20000001", access.errcode["20000001"] .. "imei"
		end
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--认证流程通过
	
	--1、检查用户号码是否为移动
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		return
	end
	
	--2、检查是否频繁下发验证码
	local ok = db.getVerification("frequencytime_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
	if ok then
		--说明是频繁下发验证码
		logf("[ERROR]:Verification code request too often")
		comm.sendResponseToThirdParty("200", "20000006", access.errcode["20000006"] .. tostring(wfc_conf.verificationcode.frequencytime) .. "s")
		return
	end
	
	--3、获取验证码, 若之前的验证码没过期则继续使用之前的验证码下发，若已过期的生成新的验证码下发
	local ok_verification, verificode = db.getVerification(accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
	if not ok_verification then
		--4、生成验证码
		verificode = comm.produceVerificationcode()

		--5、存储验证码信息
		--[[
			set  appkey_用户号码  验证码
			expire  用户号码  有效期
		]]
		local ok = db.recordVerification(accessobj.appkey .. "_" .. accessobj.argt.bindnumber, verificode, tonumber(accessobj.app["verifivalidtime"])*60)
		if not ok then
			logf("[ERROR]:record verification code %s error", tostring(verificode))
			comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return
		end
	end
	
	--
	--6、调用AEP接口下发验证码短信
	local ok, r = sendSmsVerificationCode(verificode, accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["alisignname"], accessobj.app["verifichannel"], accessobj.app["aeptemplateid"], accessobj.app["verifivalidtime"])
	if not ok then
		logf("[ERROR]:Verification code send failed")
		
		comm.sendResponseToThirdParty("200", "20000005", access.errcode["20000005"])
	else
		--7、记录发送验证码信息，有效时间wfc_conf.verificationcode.frequencytime,下次发送验证码间隔少于wfc_conf.verificationcode.frequencytime,返回失败
		--set frequencytime_CCCCCCCCCCCCCCCCCCCCCC_13522807109  123456
		--expire frequencytime_CCCCCCCCCCCCCCCCCCCCCC_13522807109 wfc_conf.verificationcode.frequencytime
		db.recordVerification("frequencytime_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, verificode, wfc_conf.verificationcode.frequencytime)
		
		--8、缓存鉴权信息，有效期wfc_conf.authinfo.outtime
		local ok, imsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr , accessobj.argt.bindnumber)
		if not ok then
			imsi = ""
		end
		db.recordauthinfo("Authinfo_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, accessobj.argt.registration_id, accessobj.argt.imei, imsi, accessobj.argt.device_type, wfc_conf.authinfo.outtime)
		
		comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	end
	return
end

--end------------------下发验证码----------------------------

--begin------------------验证码结果通知----------------------------
local function handleNotifySmsVerification(argt)
	
	local function notifySmsVerification(verifnotifybody)
		--smsMsgId=100001200101130511090326000001&status=succeed
		local smsid, status
		local sip1 = comm.strsplit(verifnotifybody, "&")
		local sip2 = comm.strsplit(sip1[1], "=")
		local sip3 = comm.strsplit(sip1[2], "=")
		if sip2[1] == "smsMsgId" then
			smsid = sip2[2]
		elseif sip2[1] == "status" then
			status = sip2[2]
		end
		
		if sip3[1] == "smsMsgId" then
			smsid = sip3[2]
		elseif sip3[1] == "status" then
			status = sip3[2]
		end
		
		return smsid, status
	end

	if argt.HttpBody == nil or argt.HttpBody == "" then
		comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
		return
	end
	local smsid, status = notifySmsVerification(argt.HttpBody)
	
	local ok, appkey, usernumber = db.selectVerifiCodeLogInfoDB(smsid)
	
	--记录用户下发验证码结果通知日志
	db.saveNotifyVerifiCodeLogInfoDB(smsid, status, appkey, usernumber)

	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end------------------验证码结果通知----------------------------

--begin------------------统计验证码成功率----------------------------
local function statisticsSmsFunc(mysqlData)
	local succeednum, failednum = 0, 0
	
	for i=1, mysqlData.RowNum do
		if mysqlData[i].status == "failed" then
		
			failednum = tonumber(mysqlData[i].count)
		elseif mysqlData[i].status == "succeed" then
			
			succeednum = tonumber(mysqlData[i].count)
		end
	end
	
	return succeednum, failednum
end



local function statisticsSmsVerification(argt)

	--每10分钟统计过去一个小时,失败验证码的条数与成功验证码的条数的比值
	
	local ok, mysqlData = db.statisticsNotifyVerifiCodeLogInfoDB(comm.getTime(), comm.getTime(os.time()-60*60))
	if not ok then
		--说明这段时间没有用户发送验证码
		return
	end

	local succeednum, failednum = statisticsSmsFunc(mysqlData)
	
	if (succeednum+failednum) > 20 and failednum > 0 and (succeednum/failednum) < 1 then
		--一个小时内验证码个数大于20 并且 失败的次数大于成功的次数
		
		--1、将AEP下发验证码失败后自动切换阿里渠道的Appkey 切换为阿里渠道
		db.updateVerifichannel_thirdparty_app("2")
		
		--2、发送告警给告警服务器
		local httpBody = {}
		httpBody.alarmmodule = "safeServer"
		httpBody.usernumber = ""
		httpBody.alarmtime = comm.getTime()
		httpBody.alarmtype = "验证码异常，验证码下发渠道切换"
		httpBody.alarmcode = "1001"
		
		local r = callSmp(wfc_conf.version, "alarminfo_v1", httpBody)
		if r.code ~= "00000000" then
			logf("[ERROR]:send alarm msg failed")
		end
	end
	return
end
--end------------------统计验证码成功率----------------------------

--begin-----------------处理生成用户校验码（作用同验证码）-----------------------------
local function handleUserCheckcode(argt)
--[[
{
"bindnumber":"13712345678"
}
]]
	local accessobj = access.new()
	
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	
	--1、检查用户号码是否为移动
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:Bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		return
	end
	
	--2、查询用户号码是否为空号imsi
	
	local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.sendImsiAddr, accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:User imsi check failed")
		comm.sendResponseToThirdParty("200", "20000023", access.errcode["20000023"])
		return
	end
	
	
	--3、生成校验码
	local verificode = comm.produceVerificationcode()

	--5、存储校验码信息
	--[[
		set  appkey_用户号码  验证码
		expire  用户号码  有效期
	]]
	local ok = db.recordVerification(accessobj.appkey .. "_" .. accessobj.argt.bindnumber, verificode, wfc_conf.verificationcode.checkcodevalidtime)
	if not ok then
		logf("[ERROR]:record check code %s error", tostring(verificode))
		comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
		return
	end
	
	comm.sendCheckCodeResponseToThirdParty("200", "00000000", access.errcode["00000000"], verificode, wfc_conf.verificationcode.checkcodevalidtime/60) 
	return
end
--end-------------------处理生成用户校验码（作用同验证码）-----------------------------

--begin-----------------用户鉴权-----------------------------

--向终端推送极光通知
local function notifyJPush(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
	logf("[NOTICE]:originaldevicecode:%s,originaldevicetype:%s", originaldevicecode,originaldevicetype)
	if originaldevicetype == "android" then
		--android的消息推送
		--生成环境推送
		notifyPushAndroid(wfc_conf.JPush.Addr, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
		
	else
		--ios的消息推送
		
		--生成环境推送
		notifyPushIos(wfc_conf.JPush.Addr, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
		
	end
	return
end

--判断imsi是否改变
local function judgeIMSI(imsi,argt,app)
	if tonumber(app["imsistate"]) == 1 then
		--imsi安全开关开启
		--通知wificallingAS查询当前IMSI
		local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, argt.bindnumber)
		
		if not ok then
			--wificallingAS响应失败, 则向AEP返回失败
			return false,currentimsi
		end
		--3、与之前的imsi比较,判断imsi是否改变
		if (currentimsi == imsi) then
			logf("[NOTICE]:usernumber=%s, imsi no change : original imsi=%s, current imsi=%s", argt.bindnumber, imsi, currentimsi)
		else
			logf("[ERROR]:usernumber=%s,imsi change : original imsi=%s, current imsi=%s", argt.bindnumber, imsi, currentimsi)

			return false,currentimsi
		end
		return true,currentimsi
	else
		--imsi安全开关关闭
		logf("[NOTICE]:usernumber=%s,imsi state=%s", argt.bindnumber, app["imsistate"])
		return true
	end
end


local function judgeAuthcodelog(phonenumber, domain, authcode, deadline)
	--记录用户授权码日志
	local errcode, affected_rows = db.saveUserAuthcodeLog(phonenumber, domain, authcode, deadline)
	if affected_rows <= 0 then
		logf("[ERROR]:save wfc_userauthcodelog failed")
		return false
	end
	return true
end

--生成新的授权码,SIP对接方式授权码发给wificallingas,并更新定时器
local function handleAuthcode(accesstype, domain, phonenumber, imei)
	--生成授权码
	local authcode = crypto.hash("md5", imei .. tostring(os.time()))
	local deadline = os.time()+wfc_conf.callingvalidtime
	
	logf("[NOTICE]:produce authcode=%s, deadline=%s", authcode, comm.getTime(deadline))
	if tonumber(accesstype) == 1 then
		--SDK对接方式
		
		local ok = judgeAuthcodelog(phonenumber, domain, nil, deadline)
		if not ok then
			return "200", "30000001", access.errcode["30000001"]
		end
		
		--更新定时器
		local ok = updateTimer(phonenumber,domain)
		if not ok then
			logf("[ERROR]:update timer failed")
			return "200", "30000001", access.errcode["30000001"]
		end

		return "200", "00000000", access.errcode["00000000"], deadline
	else
		--SIP对接方式
		
		local ok = judgeAuthcodelog(phonenumber, domain, authcode, deadline)
		if not ok then
			return "200", "30000001", access.errcode["30000001"]
		end
		
		--更新定时器
		local ok = updateTimer(phonenumber,domain)
		if not ok then
			logf("[ERROR]:update timer failed")
			return "200", "30000001", access.errcode["30000001"]
		end
		--向wificallingAS发送新的授权码
		local ok = notifyAuthCodeToWfcAs(wfc_conf.wfcAs.setAuthcodeAddr, authcode, phonenumber, domain)
		if not ok then
			logf("[ERROR]:send notifyAuthCode to wificallingAs failed")
			return "200", "30000001", access.errcode["30000001"]
		end
		return "200", "00000000", access.errcode["00000000"], deadline, authcode
	end
end

--不携带验证码登录流程
local function userLoginNoVerification(imei,imsi,devicecode,devicetype,argt,app)
	
	--1、判断imei是否改变
	local ok_imei = judgeIMEI(imei, argt.imei, app)
	if not ok_imei then
	   	--判断是否需要走机卡分离校验流程  true:不需要    false:需要
		local ok = judgedevSimornot(argt.bindnumber)
		if not ok then
			--更换终端后需要重新判断机卡分离
			db.SetSremRedis("DevSimAuth", argt.bindnumber .. "_" .. app["domainname"])
		
			--记录换终端的时间
			db.recordVerification("Devsimusertime_" .. argt.bindnumber .. "_" .. app["domainname"], 1, wfc_conf.devsimtime)
		end     

		
		logf("[ERROR]:usernumber=%s, imei change : original imei=%s, current imei=%s", argt.bindnumber, imei, argt.imei)
	else
		logf("[NOTICE]:usernumber=%s,imei no change", argt.bindnumber)
	end

	--2、判断imsi是否改变
	local ok_imsi, currentimsi = judgeIMSI(imsi,argt,app)
	if not ok_imsi then
		--imsi发生变化,通知wificallingAS用户 闭锁呼出、MO短信
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1,3", "3", "", "imsi change")
		
		--删除redis中的记录，以免5分钟有效期到达时又发送一条闭锁
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
	end
	
	if ((ok_imei == false) or (ok_imsi == false)) then
		--imei发生变化 or imsi发生变化, 需要验证码重新鉴权
		
		db.saveUserNeedVerifiAuthLogDB(argt.bindnumber, app["domainname"], ok_imei, ok_imsi, imei, argt.imei, imsi, currentimsi)
		return 200, "20000010", access.errcode["20000010"]
	end
	
	--3、判断终端所处地区位置
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--通知wificallingAS用户不能通话,闭锁呼出
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:".. locationinfo_desc)
		
		--删除redis中的记录，以免5分钟有效期到达时又发送一条闭锁
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		return 200, "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc
	end

	
	--此时三个安全鉴权已经走完
	
	--通知wificallingAS该用户可以通话
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS响应失败, 则向AEP返回失败
		if r.code == "00040032" then --用户处于停机状态,鉴权失败,SDK需提示用户充值后使用APP
			return 200, "20000027", access.errcode["20000027"]
		else
			return 200, "30000001", access.errcode["30000001"]
		end
	end
	
	--生成新的授权码,SIP对接方式授权码发给wificallingas,并更新定时器
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	return httpcode, code, desc, deadline, authcode
end

--验证码开关关闭下的鉴权流程
local function userLoginNoVerification_trust(appkey,imei,imsi,devicecode,devicetype,argt,app)
	
	--1、判断imei是否改变
	local ok_imei = judgeIMEI(imei, argt.imei, app)
	if not ok_imei then
		logf("[ERROR]:usernumber=%s,imei change : original imei=%s, current imei=%s", argt.bindnumber, imei, argt.imei)		
	else
		logf("[NOTICE]:usernumber=%s,imei no change", argt.bindnumber)
	end

	--2、判断imsi是否改变
	local ok_imsi,currentimsi = judgeIMSI(imsi,argt,app)
	if not ok_imsi then
	
		--信任的用户imsi发生变化,无需闭锁呼出
		logf("[ERROR]:imsi changed")	
	end
	
	--若imei 或imsi 有一个发生了改变 则更新该用户信息表
	if ((ok_imei == false) or ((ok_imsi == false) and (currentimsi ~= nil))) then
		--更新最新用户鉴权信息到用户信息表wfc_userauthinfo
		db.updateUserAuthInfoDB(appkey, argt.bindnumber, argt.registration_id, argt.imei, currentimsi, argt.device_type)
	end
	
	--3、判断终端所处地区位置
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--通知wificallingAS用户不能通话,闭锁呼出
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:"..locationinfo_desc)

		--删除redis中的记录，以免5分钟有效期到达时又发送一条闭锁
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		return 200, "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc
	end
	
	
	--此时三个安全鉴权已经走完
	
	--通知wificallingAS该用户可以通话
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS响应失败, 则向AEP返回失败
		if r.code == "00040032" then --用户处于停机状态,鉴权失败,SDK需提示用户充值后使用APP
			return 200, "20000027", access.errcode["20000027"]
		else
			return 200, "30000001", access.errcode["30000001"]
		end
	end
	
	--生成新的授权码,SIP对接方式授权码发给wificallingas,并更新定时器
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	return httpcode, code, desc, deadline, authcode
end


--携带验证码登录流程
local function userLoginHaveVerification(appkey, imei,imsi,devicecode,devicetype,argt,app)

	--通知wificallingAS查询当前IMSI
	_, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, argt.bindnumber)
	
	local ok = judgeIMEI(imei, argt.imei, app)
	if not ok then
		--终端更换了
		logf("[NOTICE]:usernumber=%s, changed terminal service", argt.bindnumber)	
	end
	
	--更新最新用户鉴权信息信息表wfc_userauthinfo
	db.updateUserAuthInfoDB(appkey, argt.bindnumber, argt.registration_id, argt.imei, currentimsi, argt.device_type)
	
	--判断终端所处地区位置
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--不在终端应该所处于的位置，则通知wificallingAS闭锁用户,闭锁呼出
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:"..locationinfo_desc)
		
		--删除redis中的记录，以免5分钟有效期到达时又发送一条闭锁
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		
		comm.sendAuthResponseToThirdParty("200", "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc)
		return false, access.errcode["20000011"] .. " " .. locationinfo_desc
	end
	
	--通知wificallingAS该用户可以通话
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS响应失败, 则向AEP返回失败
		if r.code == "00040032" then --用户处于停机状态,鉴权失败,SDK需提示用户充值后使用APP
			comm.sendAuthResponseToThirdParty("200", "20000027", access.errcode["20000027"])
			return false, access.errcode["20000027"]
		else
			comm.sendAuthResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return false, access.errcode["30000001"]
		end
	end
	
	--生成新的授权码,SIP对接方式授权码发给wificallingas,并更新定时器
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	--返回响应
	comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc, deadline, authcode)
	if code ~= "00000000" then
		--分配授权码失败或更新定时器失败,即不需要走以下流程
		return false, desc
	end
	
	return true, "success", authcode
end

--用户登录流程处理函数
local function userAuthMain(appkey,imei,imsi,devicecode,devicetype,verifnumber,argt,app)

	if tonumber(app.verifstate) == 1 then
		--1、验证码安全开关开启
		if argt.verificationcode == nil then
		
			--1.1不携带验证码登录流程
			logf("[NOTICE]: ####### user no verificode login")
			local httpcode, code, desc, deadline, authcode = userLoginNoVerification(imei,imsi,devicecode,devicetype,argt,app)
			comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc, deadline, authcode)
			if code == "00000000" then
				return true, desc, authcode
			else
				return false, desc
			end
		else
			--1.2携带验证码登录流程
			logf("[NOTICE]: ####### user verificode login")
			--校验验证码
			local ok, httpcode, code, desc = checkVerificationCode(appkey, verifnumber, argt.verificationcode)
			if not ok then
				comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc)
				return ok, desc
			end
			
			local ok, desc, authcode = userLoginHaveVerification(appkey,imei,imsi,devicecode,devicetype,argt,app)
			return ok, desc, authcode
		end
	else
		--2、验证码安全开关关闭		
		logf("[NOTICE]: ####### user no verificode trust login")
		local httpcode, code, desc, deadline, authcode = userLoginNoVerification_trust(appkey,imei,imsi,devicecode,devicetype,argt,app)
		
		comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc, deadline, authcode)
		if code == "00000000" then
			return true, desc, authcode
		else
			return false, desc
		end
	end
end

-- 处理用户鉴权
local function handleUserAuth(argt)
--[[
{
	"bindnumber":"13612341234" ,
	"verificationcode":"654321",  验证码（自动登陆不包含验证码参数）
	"imei": "864399020227188",
	"registration_id": "170976fa8a8220f42d4",
	"device_type": "android",
	"device_name": "iPhone7Plues",
	"device_version": "IOS10.1.1",
	"locationinfo": "中国北京市海淀区"
}
]]
	local accessobj = access.new()
	
	--检查下发验证码参数
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			verificationcode = { mo = "O" },
			imei = { mo = "M" },
			registration_id = { mo = "O" },
			device_type = { mo = "M" },
			device_version = { mo = "O" },
			device_name = { mo = "O" },
			locationinfo = { mo = "O" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
		
		--imei不能为空字符串
		if argt.imei == "" then
			return false, 200 , "20000001", access.errcode["20000001"] .. "imei"
		end
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc)
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", desc)
		return
	end
	
	--1、查看用户是否频繁调用授权
	if wfc_conf.authfrequency.flag then
		local ok = db.getAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
		if ok then
			--说明是频繁调用授权流程
			logf("[ERROR]:User auth too often")
			comm.sendAuthResponseToThirdParty("200", "20000007", access.errcode["20000007"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "User auth too often")
			return
		end
	end
	
	--2、查看鉴权号码是否合法
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:Invalid parameter - bindnumber")
	    comm.sendAuthResponseToThirdParty("200", "20000001", access.errcode["20000001"] .. "bindnumber")
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", access.errcode["20000001"] .. "bindnumber")
		return
	end
	
	--3、亿点绑定联通电信号码的鉴权,直接返回鉴权成功
	if (tonumber(accessobj.app["yidian"]) == 1) and (teltype ~= "YD") then
		logf("[NOTICE]:YIDIAN LT or DX forward auth")
		
		comm.sendAuthResponseToThirdParty("200", "00000000", access.errcode["00000000"])
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "0", access.errcode["00000000"])
		
		--记录用户调用授权频率
		if wfc_conf.authfrequency.flag then
			db.recordAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, "1", wfc_conf.authfrequency.time)
		end
		return
	end
	
	--4、查询用户是否未开户
	local ok,appkey,verifnumber = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		logf("[ERROR]:User not open account")
		comm.sendAuthResponseToThirdParty("200", "20000013", access.errcode["20000013"])
			
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "User not open account")
		return
	end
		
	--5、查询用户鉴权信息
	local ok, appkey, imei, imsi, devicecode, devicetype = db.selectUserAuthInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		--说明是用户注册后的第一次鉴权
		logf("[NOTICE]:this is user first auth process, need check imsi")
		
		--通知wificallingAS查询当前IMSI
		local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, accessobj.argt.bindnumber)
		if not ok then
			--wificallingAS响应失败, 则向AEP返回失败
			comm.sendAuthResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "wificallingAS check imsi return fail")
			return
		end
		
		--将imei、imsi、devicecode、devicetype插入到用户鉴权信息表
		local errcode, affected_rows = db.saveUserAuthInfoDB(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.argt.registration_id, accessobj.argt.imei, currentimsi, accessobj.argt.device_type)
		if affected_rows < 0 then
			logf("[ERROR]:save wfc_userauthinfo failed")
			comm.sendAuthResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "save wfc_userauthinfo failed")
			return
		end
			
		imsi = currentimsi
		imei = accessobj.argt.imei
		devicecode = accessobj.argt.registration_id
		devicetype = accessobj.argt.device_type
	end
	
	--机卡分离校验
	local ok = devSimAuthFunc(accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.app["devsimstate"], accessobj.argt.locationinfo)
	if not ok then
		
		comm.sendAuthResponseToThirdParty("200", "20000010", access.errcode["20000010"])
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "device and sim not same")
		return
	end
	
	
	--6、用户鉴权流程处理函数
	local ok, desc, authcode = userAuthMain(accessobj.appkey, imei, imsi, devicecode, devicetype, verifnumber, accessobj.argt, accessobj.app)
	if ok then
		--记录用户成功登录信息
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, imei, imsi, accessobj.argt.device_version, accessobj.argt.device_name, accessobj.argt.locationinfo, authcode, "2", "0", desc)
		
		--记录用户调用授权频率
		if wfc_conf.authfrequency.flag then
			db.recordAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, "1", wfc_conf.authfrequency.time)
		end
	else
		--记录用户失败登录信息
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, imei, imsi, accessobj.argt.device_version, accessobj.argt.device_name, accessobj.argt.locationinfo, authcode, "2", "1", desc)
	end
	return 
end

--end-----------------用户鉴权-----------------------------

--begin---------------用户注册-----------------------------

--向wificallingAS发送开户通知
local function openAccountInfoToWfcAs(url,appkey,bindnumber,domain,siprelay,secretkey,accesstype,businesstype,callauth,oaflag,imsi,msrn)
--[[
APP对接方式
1：SDK对接方式（eop）
2：SIP对接方式（eop和业务服务器）
3：卫星宽带SIP接入方式（业务服务器）

]]
	local function accesstypeFunc(accesstype)
	--[[
		0：SIP服务器对接
		1：SDK对接
	]]
		if tonumber(accesstype) == 1 then
			return "1"
		end
		return "0"
	end

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["appkey"] = appkey,
		["bindnumber"] = bindnumber,
		["domain"] = domain,
		["siprelay"] = siprelay,
		["secretkey"] = secretkey,
		["accesstype"] = accesstypeFunc(accesstype),
		["businesstype"] = businesstype,
		["callauth"] = callauth,
		["oaflag"] = oaflag,
		["imsi"] = imsi,
		["msrn"] = msrn
	}
	
	if imsi ~= nil then
		--说明是天猫精灵和无忧行
		url = url .. "imsi"
	end
	logf("[NOTICE]:***********************send open account to wificallingAS, url=%s, httpBody=%s", url, table2json(httpBody))
	
	local r = http.post("WFCAS", url, httpHeader, httpBody)

	logf("[NOTICE]:response from wificallingAS = %s", table2json(r))
	
	if r.Retn ~= "200" then
		logf("[ERROR]:send open account to wificallingAS failed, response Header status=%s", r.Retn)
		return false, r
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send open account to wificallingAS failed, response body code=%s", r.code)
		return false, r
	end
	logf("[NOTICE]:send open account to wificallingAS success")
	return true, r
	
end

--根据数据库表字段accesstype接入方式区分 开户信息告知的服务器
local function handleOpenAccountInfo(appkey, bindnumber, oaflag, accesstype, sipuri, sipuripassword, siprelaypassword, domainname, siprelay, eopaddr)
	if tonumber(accesstype) == 1 then
		--转售：SDK对接方式（eop和业务服务器）
		
		--1 发给eop的用户注册信息

		local ok = sendOpenAccountInfoToEop(wfc_conf.EBEOP.appkey, wfc_conf.EBEOP.secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname,eopaddr)
		if not ok then
		ok=true end
		if not ok then
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return false
		end
		--2 返回响应给AEP,SIP号须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
	elseif tonumber(accesstype) == 2 then
		--转售：数据语音SIP对接方式(eop和业务服务器)
		
		--1 发给eop的用户注册信息

		local ok = sendOpenAccountInfoToEop(wfc_conf.EBEOP.appkey, wfc_conf.EBEOP.secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname,eopaddr)
		if not ok then
		ok = true 
		end 
		if not ok then
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return false
		end
		
		--2、返回响应给AEP, SIP号和登录密码须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri, sipuripassword) 
		
	elseif tonumber(accesstype) == 3 then
		--非转售：SIP接入方式(业务服务器)
		
		--1 返回响应给AEP, SIP号、SIP中继号和密钥须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri, nil, siprelay, siprelaypassword) 
		
	elseif tonumber(accesstype) == 4 then
		--非转售：SDK接入方式(业务服务器)
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
		
	elseif tonumber(accesstype) == 5 then
		--微push对接方式
		
		--1 返回响应给AEP,由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
		
	elseif tonumber(accesstype) == 6 then
		--无忧行对接方式
		
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
	end
	return true
end


local function handleUserRegister(argt)
--[[
没使用小号功能
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --转售有该字段
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", 
	"bindnumber": "13712345678",    --只能是移动号码
	"oaflag":"0",
	"verificationcode":"654321"
	}

使用小号功能
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --转售有该字段
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", 
	"bindnumber": "13712345678",  虚拟号码   --只能是移动号码
	"verifnumber": "18612345678",  真实号码
	"oaflag":"0",
	"verificationcode":"654321"
	}

非转售
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --三方的appkey,  AEP将HTTP消息头的appkey放到消息体appid中发给安全控制服务器
	"bindnumber": "13712345678", 
	"verificationcode":"654321"
	}
转售
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --ebupt的appkey,  AEP将HTTP消息头的appkey放到消息体appid中发给安全控制服务器
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", --三方的appkey
	"bindnumber": "13712345678", 
	"oaflag":"0",
	"verificationcode":"654321",
	"imsi":"460203850485409",
	"msrn":"122222"
	}

]]
	local accessobj = access.new()
	
	--生成sip密钥
	local function getSipcode(phonenumber,domainname)
		local function siprelayFunc(phonenumber)
			local siprelaypassword = crypto.hash("md5", phonenumber .. tostring(os.time()))
			return siprelaypassword
		end
		local sipuri = "sip:" .. accessobj.argt.bindnumber .."@" .. domainname
		local sipuripassword,siprelaypassword = comm.genuuid(), siprelayFunc(phonenumber)
		return sipuri,sipuripassword,siprelaypassword
	end
	--获取URL标识
	local function getBusinessType(url)
		--/datavoice/v1/user_insert
		local urltab = comm.strsplit(url, "/")
		return urltab[2]
		--return datavoice
	end
	--检查用户注册参数
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			appid = { mo = "M" },
			verificationcode = { mo = "O" }, --使用身份认证有该字段
			oaflag = { mo = "O" },     --无该字段呼叫AS默认为普通用户
			companyid = { mo = "O" },  --转售有该字段
			verifnumber = { mo = "O" }, --使用小号有该字段
			--alitoken = { mo = "O" } --阿里验证token
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
	
	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--1、转售or非转售相关操作
	if accessobj.argt.companyid == nil then
		--companyid为空说明为非转售方式  无字段companyid,将appid赋给companyid
		accessobj.argt.companyid = accessobj.argt.appid
	end

	--2、获取第三方企业的信息
	accessobj.appkey = accessobj.argt.companyid
	accessobj:read_thirdparty_app()
	
	--检查呼叫号码是否为移动号码
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000021"])
		return
	end
	
	--3、虚拟小号相关检查
	if tonumber(accessobj.app["virtualflag"]) == 0 then
		--当虚拟小号开关关闭时,呼叫号码与校验验证码号码 相同
		accessobj.argt.verifnumber = accessobj.argt.bindnumber
	else 
		--当虚拟小号开关开启时,查询是否为给该企业分配的虚拟号码
		local ok, httpcode, code, desc = checkVirtualNum(accessobj.appkey, accessobj.argt.bindnumber)
		if not ok then
			comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", desc)
			return
		end
	end
	
	-- 若为呼转号码开户 
	if tonumber(accessobj.argt.oaflag) == 1 then
		accessobj.app["verifstate"] = "0" --设置为校验验证码开关关闭
		accessobj.app["callauth"] = "1"  --呼叫权限开启，开户后用户为呼叫解锁，无需等待解闭锁通知
		
		--更新定时器 一段时间后闭锁前转号码的主叫和MO短信
		local ok = updateTimer(accessobj.argt.bindnumber,accessobj.app["domainname"])
		if not ok then
			logf("[ERROR]:update timer failed")
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return
		end
	end
	
	--4、查看用户是否已经注册
	local ok = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if ok then
		--如果可以查询到用户信息,则说明该用户已经注册
		logf("[ERROR]:User already open account")
		comm.sendResponseToThirdParty("200", "20000012", access.errcode["20000012"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000012"])
		return
	end
	
	
	--调用阿里认证
	local function openAccountInfotoAli(bindnumber)
		logf("ali!!!!!!!!!!!")
		--bindnumber是手机号
		
		local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8",
		["Format"] = "JSON",
		["Version"] = "2017-05-25",
		["AccessKeyId"] = wfc_conf.VerifyMobile.AccessKeyId,
		["SignatureMethod"] = "HMAC-SHA1",
		["Timestamp"] = comm.getUTCTime(),
		["SignatureVersion"] = "1.0",
		["SignatureNonce"] = uuidgen()
		}
	
		local httpBody = {
		["AccessCode"] = wfc_conf.VerifyMobile.AccessCode,
		["bindnumber"] = bindnumber
		}
		
		local url = wfc_conf.VerifyMobile.SendURL_ali
		logf("[NOTICE]:***********************send verification sms to ALI, url=%s", url)
		
		--certain 		local sortedQueryString = "AccessCode="..wfc_conf.VerifyMobile.AccessCode.."&AccessKeyId="..wfc_conf.VerifyMobile.AccessKeyId.."&Action=VerifyMobile".."&Format=JSON".."&OutId=135167251641556249068878".."&PhoneNumber=".."13516725164".."&RegionId=cn-hangzhou".."&ServiceCode=dypnsapi".."&SignatureMethod=HMAC-SHA1".."&SignatureNonce=".."0c9b6965-0e60-4795-b1b3-8c9db5084064155624906887919".."&SignatureVersion=1.0".."&Timestamp=".."2019-04-26T03:24:28Z".."&Version=2017-05-25"
		
		--OPENAPI 
		local deal_euqal_accesscode = string.gsub(wfc_conf.VerifyMobile.AccessCode, '=', '%%3D')
		local sortedQueryString = "AccessCode="..deal_euqal_accesscode.."&AccessKeyId="..wfc_conf.VerifyMobile.AccessKeyId.."&Action="..wfc_conf.VerifyMobile.Action_ali.."&Format=JSON&PhoneNumber="..bindnumber.."&SecureTransport=true&SignatureMethod=HMAC-SHA1&SignatureNonce="..uuidgen().."&SignatureVersion=1.0&Timestamp="..comm.getUTCTime().."&Version="..wfc_conf.VerifyMobile.Version_ali
		--"&SourceIp="..wfc_conf.VerifyMobile.SourceIp..
		
		--孟广傲版本local sortedQueryString = "&AccessCode="..wfc_conf.VerifyMobile.AccessCode.."&AccessKeyId="..wfc_conf.VerifyMobile.AccessKeyId.."&Action=VerifyMobile&".."&Format=JSON".."&PhoneNumber="..bindnumber.."&RegionId=cn-hangzhou".."&ServiceCode=dypnsapi".."&SignatureMethod=HMAC-SHA1".."&SignatureNonce="..uuidgen().."&SignatureVersion=1.0".."&Timestamp="..comm.getUTCTime().."&Version=2017-05-25"
		
		
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)


		--[[
		alidemo url 
		sortedQueryString = "AccessKeyId=testid&AccountId=100000&Action=DescribeDomains&Format=XML&RegionId=cn-hangzhou&SignatureMethod=HMAC-SHA1&SignatureNonce=1d1620f8-0b3e-464c-9967-7b54a867945b&SignatureVersion=1.0&Timestamp=2016-03-29T03%3A33%3A18Z&Version=2016-02-01"
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)
		--]]
		
		sortedQueryString = http.urlEncode(gb_utf8(sortedQueryString)) -- UTF8编码字符串转百分号编码
		sortedQueryString = string.gsub(sortedQueryString, ':', '%%3A') -- http.urlEncode()没有处理:，单独处理
		logf("[NOTICE]:urlEncode(sortedQueryString)=%s", sortedQueryString)

		local stringToSign = http.urlEncode(sortedQueryString)
		stringToSign = string.gsub(stringToSign, '%%', '%%25') -- 额外处理：% & =
		stringToSign = string.gsub(stringToSign, '&', '%%26')
		logf("[NOTICE]:not yet deal = stringToSign=%s", stringToSign)
		stringToSign = string.gsub(stringToSign, '=', '%%3D')
		logf("[NOTICE]:deal = stringToSign=%s", stringToSign)
		stringToSign = 'POST&%2F&' .. stringToSign
		logf("[NOTICE]:stringToSign=%s", stringToSign)
					  
		local accessSecret = wfc_conf.VerifyMobile.AccessKeySecret_ali .. '&'
		--[[
		logf("[NOTICE]:accessSecret=%s", accessSecret)
		cryptostring = crypto.hash('HMACSHA1', stringToSign, accessSecret)
		logf("cryptostring=%s",cryptostring)
		--base64cryptostring = base64Encode(cryptostring)
		--logf("base64cryptostring=%s",base64cryptostring)
		hex2bincryptostring = hex2bin(cryptostring)
		logf("hex2bincryptostring=%s",hex2bincryptostring)
		base64hex2bincryptostring = base64Encode(hex2bincryptostring)
		logf("base64hex2bincryptostring=%s",base64hex2bincryptostring)
		
		
		accessSecret = "testsecret&"  --alidemo
		logf("[NOTICE]:accessSecret=%s", accessSecret)
		--]]
		
		
		local signData = base64Encode(hex2bin(crypto.hash('HMACSHA1', stringToSign, accessSecret)))
		logf("[NOTICE]:signData=%s", signData)

		local signature = http.urlEncode(signData)
		logf("[NOTICE]:signature=%s", signature)
		signature = string.gsub(signature, '/', '%%2F') -- 额外处理
		--logf("[NOTICE]:deal / signature=%s", signature)
		signature = string.gsub(signature, '=', '%%3D')
		logf("[NOTICE]:final signature=%s", signature)
		--url = url ..encodeurl.."&Signature=" .. signature
		--url = url.."?Signature="..signature.."&"..sortedQueryString
		
		url = url.."?"..sortedQueryString.."&Signature="..signature
		
		--url=wfc_conf.VerifyMobile.SendURL_ali.."?Action=VerifyMobile&AccessCode="..wfc_conf.VerifyMobile.AccessCode.."&Timestamp="..comm.getUTCTime().."&SignatureVersion=1.0&ServiceCode=dypnsapi&Format=JSON&SignatureNonce="..uuidgen().."&Version=2017-05-25&AccessKeyId="..wfc_conf.VerifyMobile.AccessKeyId.."&Signature="..signature.."&PhoneNumber="..bindnumber.."&SignatureMethod=HMAC-SHA1&RegionId=cn-hangzhou"
		
		logf("latest url ="..url)
		
		logf("[NOTICE]:***********************send verification pns to ALI, url=%s", url)

		local r = http.post("Alarm", url,httpHeader,httpBody)
		--local r = http.get("AEP", url)
		logf("[NOTICE]:response from ALI = %s", table2json(r))
		
		if r.Retn ~= "200" then
			logf("[ERROR]:send verification pns to ALI failed, response Header status=%s", r.Retn)
			
			--db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.Code, r.BizId, '2', verificode)
			--return false, r
		end
		
		if r.Code ~= "OK" then
			logf("[ERROR]:send verification pns to ALI failed, response body Code=%s", r.Code)
			
			--db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '1', r.Retn, r.Code, r.BizId, '2', verificode)
			return false, r
		end
		
		logf("[NOTICE]:send verification pns to ALI success")
		
		--db.saveVerifiCodeLogInfoDB(appkey, bindnumber, '0', r.Retn, r.Code, r.BizId, '2', verificode)
		return true, r
end
	local ok,r = openAccountInfotoAli(accessobj.argt.bindnumber)
	if ok then
	logf("send to ali ok,r=%s",table2json(r))
	else 
	logf("send to ali fail.r=%s",table2json(r))
	comm.sendResponseToThirdParty("200", r.Retn, r.Code)
	return 
	end
	
	
	--5、若验证码安全开关开启则需校验验证码
	if tonumber(accessobj.app["verifstate"]) == 1 then
		if accessobj.argt.verificationcode == nil then
			logf("[ERROR]:Invalid parameter - verificationcode")
			comm.sendResponseToThirdParty("200", "20000001", access.errcode["20000001"].."verificationcode")
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000001"].."verificationcode")
			return
		end
		ok, httpcode, code, desc = checkVerificationCode(accessobj.appkey, accessobj.argt.verifnumber, accessobj.argt.verificationcode)
		if not ok then
			comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", desc)
			return
		end
	end
	
	
	
	--6、插入记录用户正在注册信息 防止用户连续发送两次注册
	local errcode, affected_rows = db.saveUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
	if affected_rows < 0 then
		logf("[ERROR]:User are opening account")
		comm.sendResponseToThirdParty("200", "20000020", access.errcode["20000020"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000020"])
		return
	end
	
	--7、生成sip号, sip注册密码, sip中继的密钥
	local sipuri,sipuripassword,siprelaypassword = getSipcode(accessobj.argt.bindnumber,accessobj.app["domainname"])
	
	--8、向wificallingAS发送用户注册通知,发送密钥和对接类型
	local ok, r = openAccountInfoToWfcAs(wfc_conf.wfcAs.openUserAddr, accessobj.argt.appid,accessobj.argt.bindnumber,accessobj.app["domainname"],accessobj.app["siprelay"],siprelaypassword,accessobj.app["accesstype"], getBusinessType(accessobj.argt.HttpHeader.Url), accessobj.app["callauth"],accessobj.argt.oaflag, accessobj.argt.imsi, accessobj.argt.msrn)
	if not ok then
		--wificallingAS响应失败, 则向AEP返回失败
		if r.code == "00040010" then
			--移动号段转到其他运营商，开户失败
			comm.sendResponseToThirdParty("200", "20000022", access.errcode["20000022"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "YD number transfer to LTDX")
		elseif r.code == "00040011" then
			--开户失败，imsi不一致，未托管
			comm.sendResponseToThirdParty("200", "20000028", access.errcode["20000028"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "User register fail, imsi not same")
		elseif r.code == "00040012" then
			--开户失败，imsi不一致，已托管
			comm.sendResponseToThirdParty("200", "20000029", access.errcode["20000029"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "User register fail, imsi not same, already updateloc")
		else
			--开户失败
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "user register to wificallingAS return fail")
		end
		--删除用户正在注册信息
		db.deleteUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
		return
	end
	
	--9、根据对接类型向EOP开户
	local ok = handleOpenAccountInfo(accessobj.appkey, accessobj.argt.bindnumber, accessobj.argt.oaflag, accessobj.app["accesstype"], sipuri, sipuripassword, siprelaypassword, accessobj.app["domainname"], accessobj.app["siprelay"], accessobj.app["eopaddr"])
	if not ok then ok = true end
	if ok then

		--用户开户成功
		
		--9.1、记录用户信息到数据库表单wfc_userinfo
		registerUserInfo(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.argt.verifnumber, sipuri, sipuripassword, accessobj.app["siprelay"], siprelaypassword)
		
		--9.2、记录用户鉴权信息到表单 wfc_userauthinfo
		local ok, registration_id, imei, imsi, device_type = db.getauthinfo("Authinfo_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
		
		if ok and registration_id ~= nil and imei ~= nil and imsi ~= nil and device_type ~= nil then
			db.saveUserAuthInfoDB(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], registration_id, imei, imsi, device_type)
		end


		--9.3、记录成功注册信息到表单wfc_userinfolog
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "0", "success")
		
		--9.4、记录imsi和msrn的信息
		db.saveUserMsrnInfoDB(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.argt.imsi, accessobj.argt.msrn)
		
		--判断是否需要走机卡分离校验流程  true:不需要    false:需要
		local ok = judgedevSimornot(accessobj.argt.bindnumber)
		if not ok then
			--9.5、记录开户状态机卡分离使用
			db.recordVerification("Devsimusertime_" .. accessobj.argt.bindnumber .. "_" .. accessobj.app["domainname"], 1, wfc_conf.devsimtime)
		end
	else
		--用户开户失败
		
		--11、记录失败注册信息到表单wfc_userinfolog
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "EOP return fail")
	end
	
	--删除用户正在注册信息
	db.deleteUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
	return
end


--end-----------------用户注册-----------------------------




--begin-------------通话定时器-----------------------------

local function callingTimeout(argt)
	--取出超时通话有效时间(秒)的最多前100条记录，且删除这些记录
	local r = redis.get_timeout("wfc", wfc_conf.callingvalidtime, 100, 1)
	if(type(r) == "number" and r == -1) then
		logf("[ERROR_TIMER]:get redis timer failed")
	elseif(type(r) == "table" and #r == 0) then
		logf("[NOTICE_TIMER]:no redis outtime, phonenumber=%s",table2json(r))
	else
		--r={"手机号 域名","手机号 域名"}
		--通知wificallingAS用户不能通话(可批量设置)
		logf("[NOTICE_TIMER]:get redis outtime, phonenumber=%s",table2json(r))
		
		--只闭锁呼出
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, r, "1", "1", "_TIMER", "auth request outtime")
	end
	return 
end

--end---------------通话定时器-----------------------------

--begin-------------用户销户-------------------------------

local function handleUserLogout(argt)
--[[
{
"bindnumber": "sip:13812345679@ebupt.com"
}
]]

	local accessobj = access.new()
	
	--检查用户销户参数
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end

		accessobj.argt.bindnumber, accessobj.argt.domain = comm.getNumberDomain(accessobj.argt.bindnumber)
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table

	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--1、查看用户是否已经销户
	local ok, appkey = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	if not ok then
		--查询不到用户信息,则说明该用户已经销户
		logf("[ERROR]:User already close account")
		comm.sendResponseToThirdParty("200", "20000016", access.errcode["20000016"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", access.errcode["20000016"])
		return
	end		
	
	--2、读取企业信息
	accessobj.appkey = appkey
	accessobj:read_thirdparty_app()
	
	--2、发送销户信息给wificallingas
	local ok = closeAccountInfoToWfcAs(wfc_conf.wfcAs.closeUserAddr, accessobj.argt.bindnumber, accessobj.argt.domain)
	if not ok then
		comm.sendResponseToThirdParty("200", "20000017", access.errcode["20000017"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", "send close account info to wificallingAS fail")
		return
	end
	
	--3、发送销户信息给EOP
	if tonumber(accessobj.app["accesstype"]) == 1 or tonumber(accessobj.app["accesstype"]) == 2 then
	    local ok = sendCloseAccountInfoToEop(wfc_conf.EBEOP.appkey, wfc_conf.EBEOP.secret, appkey, accessobj.argt.bindnumber, accessobj.argt.domain, accessobj.app["eopaddr"])
	    if not ok then
		ok = true
		end
		if not ok then
		    comm.sendResponseToThirdParty("200", "20000017", access.errcode["20000017"])
		    registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", "send close account info to EOP fail")
		    return
	    end
	end

	--4、删除用户信息
	local errcode, affected_rows = db.deleteUserInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	if affected_rows < 0 then
		logf("[ERROR]:delete wfc_userinfo failed")
		comm.sendResponseToThirdParty("200", "20000017", access.errcode["20000017"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", "delete wfc_userinfo failed")
		return
	end
	
	--5、删除用户鉴权信息
	db.deleteUserAuthInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	
	--6、删除imsi和msrn信息
	db.deleteUserMsrnInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	
	--7、记录销户用户日志
	registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "0", "success")
	
	--8、销户后需要重新判断机卡分离
	--判断是否需要走机卡分离校验流程  true:不需要    false:需要
	local ok = judgedevSimornot(accessobj.argt.bindnumber)
	if not ok then
		db.SetSremRedis("DevSimAuth", accessobj.argt.bindnumber .. "_" .. accessobj.argt.domain)
	end
	
	--9、返回响应
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end


--end----------------用户销户-------------------------------

--begin----------------用户开户状态查询-------------------------------

local function handleUserSelect(argt)
--[[
非转售
{
"bindnumber": "13712345678",
"appid":"aaaaaaaaaaaaa"
}
转售
{
"bindnumber": "13712345678",
"appid":"aaaaaaaaaaaaa"         ebupt的appkey
"companyid":"bbbbbbbbbbbbb"     三方的appkey
}
]]
	local accessobj = access.new()
	
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			appid = { mo = "M" },
			companyid = { mo = "O" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table

	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	--1、转售or非转售相关操作
	if accessobj.argt.companyid == nil then
		--companyid为空说明为非转售方式  无字段companyid,将appid赋给companyid
		accessobj.argt.companyid = accessobj.argt.appid
	end
	
	--1、获取第三方企业的信息
	accessobj.appkey = accessobj.argt.companyid
	accessobj:read_thirdparty_app()
	
	--2、查询用户开户信息
	local ok,appkey,verifnumber,sipcode,sippasswd,siprelay,siprelaypasswd = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		logf("[NOTICE]:User not open account")
		
		comm.sendResponseToThirdParty("200", "20000013", access.errcode["20000013"])
		return 
	end
	
	--3、根据对接方式返回用户开户信息
	if tonumber(accessobj.app["accesstype"]) == 1 then
		--转售：SDK对接方式
		
		--返回响应给AEP,SIP号须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode)
	elseif tonumber(accessobj.app["accesstype"]) == 2 then
		--转售：数据语音SIP对接方式
		
		--返回响应给AEP, SIP号和登录密码须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, sippasswd) 
		
	elseif tonumber(accessobj.app["accesstype"]) == 3 then
		--非转售：SIP接入方式(业务服务器)
		
		--返回响应给AEP, SIP号、SIP中继号和密钥须由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, nil, siprelay, siprelaypasswd) 
	elseif tonumber(accessobj.app["accesstype"]) == 4 then
		--非转售：SDK接入方式(业务服务器)
		
		--返回响应给AEP,由AEP返回给业务服务器
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode)
	elseif tonumber(accessobj.app["accesstype"]) == 5 then
		--微push对接方式
		
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	elseif tonumber(accessobj.app["accesstype"]) == 6 then
		--无忧行对接方式
		
		local ok, imsi, msrn = db.selectUserMsrnInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
		if not ok then
			comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
                        return
		end
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, nil, nil, nil, msrn, imsi)
	end
	return 
end

--end----------------用户开户状态查询-------------------------------

--begin------------校验用户号码与IMSI对应关系----------------

local function checkUserImsi(argt)
--[[
{
 "bindnumber": "13712345678",
 "imsi":"111111111111111"
}
]]
	local accessobj = access.new()
	
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			imsi = { mo = "O" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	--查看当前用户的imsi
	local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.sendImsiAddr, accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:User imsi check failed")
		comm.sendResponseToThirdParty("200", "20000023", access.errcode["20000023"])
		return
	end
	
	if accessobj.argt.imsi == nil then
		--检查用户是否在大网注册
		if currentimsi == "" then
			logf("[ERROR]:User not register in network")
			comm.sendResponseToThirdParty("200", "20000025", access.errcode["20000025"])
			return
		end
	else
		--比较imsi
		if currentimsi ~= accessobj.argt.imsi then
			logf("[ERROR]:Usernumber=%s imsi not same, imsi1=%s, imsi2=%s", accessobj.argt.bindnumber, currentimsi, accessobj.argt.imsi)
			comm.sendResponseToThirdParty("200", "20000024", access.errcode["20000024"])
			return
		end
	end
	
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end--------------校验用户号码与IMSI对应关系----------------

--begin--------------ISMP鉴权----------------
local function handleUserIsmpAuth(argt)
--[[
{
	"USERID":"xxx",
	"TIMESTAMP":"xxx",
	"SIGN_REG":"xxx",
	"SESSIONID":"xxx"
}
]]
	local accessobj = access.new()

	local function isvalidVerificationcode()

		local rule = {
			USERID = { mo = "M", ck = "^1[0-9]{10}$" },
			TIMESTAMP = { mo = "M" },
			SIGN_REG = { mo = "M" },
			SESSIONID = { mo = "M" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end

		--记录当前请求的号码
		accessobj.phonenumber = accessobj.argt.USERID
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:(%s),httpcode:%d, code:%s, desc:%s",tostring(accessobj.phonenumber), httpcode, code, desc)
		comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	
	--检查密码是否一致
	if accessobj.argt.SIGN_REG ~= crypto.hash("MD5", accessobj.argt.USERID..accessobj.argt.TIMESTAMP..accessobj.app["appsecret"]) then
		logf("[ERROR]:User password error")
		comm.sendResponseToThirdParty("200", "20000026", access.errcode["20000026"])
		return
	end

	comm.sendIsmpAuthResponseToThirdParty("200", "00000000", access.errcode["00000000"], crypto.hash("MD5", accessobj.argt.SESSIONID..accessobj.argt.TIMESTAMP..accessobj.app["appsecret"]))
	
	return

end
--end--------------ISMP鉴权----------------

--begin--------------处理阿里企业的解闭锁请求----------------
local function handleUserCallBarring(argt)
--[[
{
 "bindnumber": "13712345678",
 "lockflag": "1",
 "barringtype": "5"
}
]]
	local accessobj = access.new()
	
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			lockflag = { mo = "M" },
			barringtype = { mo = "M" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	if accessobj.argt.lockflag == "0" then
		--解锁
		local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, accessobj.argt.bindnumber.." "..accessobj.app["domainname"], "")
		if not ok then
			--wificallingAS响应失败, 则向AEP返回失败
			if r.code == "00040032" then --用户处于停机状态,鉴权失败,SDK需提示用户充值后使用APP
				comm.sendResponseToThirdParty("200", "20000027", access.errcode["20000027"])
			else
				comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			end
			return
		end
	elseif accessobj.argt.lockflag == "1" then
		--闭锁
		local ok = setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, accessobj.argt.bindnumber.." "..accessobj.app["domainname"], accessobj.argt.barringtype, nil, "", "EOP set callbarring state")
		if not ok then
			--wificallingAS响应失败, 则向AEP返回失败
			comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return
		end
	end
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end----------------处理阿里企业的解闭锁请求----------------

--begin----------------发送告警信息----------------

local function httpInfoToAlarm(url, httpBody)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}

	logf("[NOTICE]:http to Alarm server url=%s, httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("Alarm", url, httpHeader, httpBody)
	if r.Retn ~= "200" then
		logf("[ERROR]:send http to Alarm server failed")
		return false, r
	end
	if r.code ~= "00000000" then
		logf("[ERROR]:send http to Alarm server failed, response=%s",table2json(r))
		return false, r
	end
	
	logf("[NOTICE]:send http to Alarm server success, response=%s",table2json(r))
	return true, r
end

local function handleAlarmInfo(argt)

	local httpBody = {}
	httpBody.alarmmodule = argt.alarmmodule
	httpBody.usernumber = argt.usernumber
	httpBody.alarmtime = argt.alarmtime
	httpBody.alarmtype = argt.alarmtype
	httpBody.alarmcode = argt.alarmcode
	
	local ok, r = httpInfoToAlarm(wfc_conf.AlarmServer.alarmURL, httpBody)
	if ok then
		comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	else
		comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
	end
	return
end
--end------------------发送告警信息----------------

--begin---------------处理阿里切换设备----------------

local function userSwitchEquipment(argt)
--[[
{
 "switchchannel": "11"
}
]]

	local accessobj = access.new()
	
	local function isvalidVerificationcode()

		local rule = {
			switchchannel = { mo = "O" }
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --请求消息的table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	local ok = notifySwitchEquipToWfcAs(wfc_conf.wfcAs.sendSwitchEquipAddr, accessobj.argt.switchchannel, accessobj.app["domainname"])
	if not ok then
		comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
		return
	end
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end-----------------处理阿里切换设备----------------

local function ismp_register(argt)

	sendAck({Retn = "200", Desc = comm.httpCode["200"]})
	return
end

local function userUpdateimsi(argt)
	
	local ok, mysqlData = db.selectAllUserAuthInfoDB()
	if ok then
		for i=1, mysqlData.RowNum do
			
			local ok, imsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, mysqlData[i].usernumber)
			if ok then
				db.updateUserImsiAuthInfoDB(mysqlData[i].appkey, mysqlData[i].usernumber, imsi)
			end
			
		end
	end
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end


lib_cmdtable = {
	--处理下发验证码
	["sms_verification_code_v1"] = handleSmsVerification, --下发验证码 https://host:port/wfc/sdk/v1/sms_verification_code
	
	--处理验证码结果通知
	["notifyTemplateSms_v1"] = handleNotifySmsVerification, -- https://host:port/wfc/v1/notifyTemplateSms
	
	--统计验证码成功率
	["statistics_sms_verification_code_v1"] = statisticsSmsVerification, 
	
	--处理生成用户校验码（作用同验证码）
	["user_checkcode_v1"] = handleUserCheckcode, -- https://host:port/wfc/appserver/v1/user_checkcode
	
	--校验用户号码与IMSI对应关系
	["user_checkimsi_v1"] = checkUserImsi, -- https://host:port/wfc/appserver/v1/user_checkimsi
	
--[[
vi conf.slrun.json  CronDrive设置为1

sqlite conf.crontab.db
select * from crontab;
insert into crontab(no, runtime, runflag, cmd, arg) values('1','0 */10 * * * *','1','WFC:statistics_sms_verification_code_v1',''); 

]]
	-- 处理用户鉴权
	["user_auth_v1"] = handleUserAuth,  --用户鉴权 https://host:port/wfc/sdk/v1/user_auth
	
	-- 处理用户鉴权 --增加1、ismp鉴权 2、短信对称密钥
	["user_auth_v2"] = handleUserAuth,  --用户鉴权 https://host:port/wfc/sdk/v2/user_auth
	
	["register"] = ismp_register,
	-- ISMP鉴权
	["ismp_auth"] = handleUserIsmpAuth,
	
	-- 处理用户注册
	["datavoice_user_insert_v1"] = handleUserRegister, -- 数据语音用户注册 http://host:port/datavoice/v1/user_insert
	["satcomm_user_insert_v1"] = handleUserRegister,   -- 卫星宽带用户注册  http://host:port/satcomm/v1/user_insert
	
	-- 处理用户销户
	["datavoice_user_delete_v1"] = handleUserLogout, -- 数据语音用户销户  http://host:port/datavoice/v1/user_delete
	["satcomm_user_delete_v1"] = handleUserLogout,   -- 卫星宽带用户销户 http://host:port/satcomm/v1/user_delete
	
	-- 处理用户开户状态查询
	["datavoice_user_select_v1"] = handleUserSelect,  -- 数据语音用户开户状态查询  http://host:port/datavoice/v1/user_select
	["satcomm_user_select_v1"] = handleUserSelect,  -- 卫星宽带用户开户状态查询  http://host:port/satcomm/v1/user_select
	
	--发送告警信息
	["alarminfo_v1"] = handleAlarmInfo, --发送告警信息 http://host:port/wifias/v1/alarminfo
	
	-- 处理阿里企业的解闭锁请求
	["user_callbarring_v1"] = handleUserCallBarring, --http://host:port/wfc/eopserver/v1/user_callbarring
	
	-- 处理阿里切换设备
	["user_switchequipment_v1"] = userSwitchEquipment, --https://host:port/wfc/eopserver/v1/user_switchequipment
	
	-- 通话有效时间到达截止期限
	["calling_timeout_v1"] = callingTimeout,
	
	-- 更新用户imsi
	["user_updateimsi_v1"] = userUpdateimsi,  --https://host:port/wfc/eopserver/v1/user_updateimsi
	
	--阿里认证查询
	["check_aliauth_v1"] = checkaliauth    --https://host:port/datavoice/v1/check_aliauth
}
 
