include "http"
include "redis"
include "crypto"
include "access"
include "comm"
include "wfc_conf"
include "db"

SERVICE_ID = wfc_conf.SERVICE_ID

------------��������--------------------begin--------------------

--��¼�û���־��Ϣ
local function registerUserLogInfo(appkey, usernumber, imei, imsi, deviceversion, devicename, locationinfo, authcode, stage, result, resultdesc)

	local errcode, affected_rows = db.saveUserLogInfoDB(appkey, usernumber, imei, imsi, deviceversion, devicename, locationinfo, authcode, stage, result, resultdesc)
	if affected_rows < 0 then
		logf("[ERROR]:save wfc_userinfolog table failed")
		return false, 200, "30000001", access.errcode["30000001"]
	end
	return true
end

--��¼�û���Ϣ
local function registerUserInfo(appkey, usernumber, domainname, verifnumber, sipcode, sippasswd, siprelay, siprelaypasswd)

	local errcode, affected_rows = db.saveUserInfoDB(appkey, usernumber, domainname, verifnumber, sipcode, sippasswd, siprelay, siprelaypasswd)
	if affected_rows < 0 then
		logf("[ERROR]:save wfc_userinfo table failed")
		return false, 200, "30000001", access.errcode["30000001"]
	end
	return true
end

--У����֤��
local function checkVerificationCode(appkey, phonenumber, verificationcode)
	if phonenumber == nil then
		logf("[ERROR]:Invalid parameter - verifnumber")
		return false, 200 , "20000001", access.errcode["20000001"] .. "verifnumber"
	end
	if phonenumber ~= wfc_conf.verificationcode.freecheckbindnumber then
		--������У����֤��ĺ���
		local ok, verificode = db.getVerification(appkey .. "_" .. phonenumber)
		if not ok then
			--��֤�볬����Ч��
			logf("[ERROR]:verification code outtime")
			return false, 200, "20000009", access.errcode["20000009"]
		end

		if tonumber(verificationcode) ~= tonumber(verificode) then
			--��֤�����
			logf("[ERROR]:verification code error, right verificode=%s", verificode)
			return false, 200, "20000008", access.errcode["20000008"]
		end
	end
	logf("[NOTICE]:check verification code success")
	return true, 200, "00000000", access.errcode["00000000"]
end

--[[
return : true:�û���λ�ü�Ȩ
         false���û�����λ�ü�Ȩ
]]

local function checkUsernoLocationAuth(usernumber, domainname)
	local ok, usertype, begintime, endtime = db.selectUsernoLocationAuth(usernumber, domainname)
	if ok then
	
		if tonumber(usertype) == 1 then
			--1�������û������ò鿴ʱ���
			
			return true
		elseif tonumber(usertype) == 2 then
			--2����ҵ�������û�����鿴ʱ��Σ�����Ч����
			local currenttime = comm.getCurrentTime(0)
			if tonumber(currenttime)>=tonumber(begintime) and tonumber(currenttime)<=tonumber(endtime) then
				
				return true
			end
		end
	end
	return false
end

local function judgeLocationInfo(usernumber, locationinfo, app)
	--�鿴�û����豸����
	local ok, _, _, _, _, devicetype = db.selectUserAuthInfoDB(usernumber, app["domainname"])
	
	local locationStr2 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 2)
	local locationStr4 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 4)
	logf("[NOTICE]:locationinfo=%s locationStr2=%s,location=%s",gb_utf8(locationinfo),locationStr2,app["location"])
	
	if devicetype == "iOS" then
	
		if (tonumber(app["location"])==2) and (((locationStr2 == gb_utf8("�й�")) and (gb_utf8(locationinfo) ~= gb_utf8("�й�")) and locationStr4 ~= gb_utf8("�й����") and locationStr4 ~= gb_utf8("�й�����") and locationStr4 ~= gb_utf8("�й�̨��")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") or (locationinfo == "no activate location authority") or (locationinfo == "")) then
			--ʹ��λ�������ڹ���
			
			logf("[ERROR]:not right place to login : %s", gb_utf8(locationinfo))
			return false
		end
	elseif devicetype == "android" then
	
		if (tonumber(app["location"])==2) and (((locationStr2 == gb_utf8("�й�")) and (gb_utf8(locationinfo) ~= gb_utf8("�й�")) and locationStr4 ~= gb_utf8("�й����") and locationStr4 ~= gb_utf8("�й�����") and locationStr4 ~= gb_utf8("�й�̨��")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") or (locationinfo == "no activate location authority")) then
			--ʹ��λ�������ڹ���
			
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

--�ж��ն���������λ��
local function judgeLocation(usernumber, locationinfo, client_ip, app)

	if tonumber(app["locationstate"]) == 1  then
		--λ�ð�ȫ���ؿ���
		local ok_locationauth = checkUsernoLocationAuth(usernumber, app["domainname"])
		if ok_locationauth then
			--�û�����λ�ü�Ȩ���У������жϵ�ǰ������λ��
			logf("[NOTICE]:usernumber=%s, in no need location auth, no need to judge location", usernumber)
			return true
		else
			if tonumber(app["satellitestate"]) == 0 then
				--��������ͨ��ҵ��
				if locationinfo ~= nil then
				
					local ok = judgeLocationInfo(usernumber, locationinfo, app)
					if not ok then
						return false, locationinfo
					end
				end
				return true
			elseif tonumber(app["satellitestate"]) == 1 then
				--����ͨ��ҵ�� �ж��Ƿ�Ϊ����ͨ�ŵ�ip
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

--��ѯSIM����λ��
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

--�ж��Ƿ���Ҫ�߻�������У������  true:����Ҫ    false:��Ҫ
local function judgedevSimornot(usernumber)
	logf("[NOTICE]:devsimfuncstate=%d", wfc_conf.testfunc.devsimfuncstate)
	if wfc_conf.testfunc.devsimfuncstate == 0 then
		--�������빦��У�鿪�عر�
		
		--�鿴�û������Ƿ�Ϊ���Ժ���
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

--��������У��
local function devSimAuthFunc(usernumber, domainname, devsimstate, locationinfo)
	
	--�ж��Ƿ���Ҫ�߻�������У������  true:����Ҫ    false:��Ҫ
	local ok = judgedevSimornot(usernumber)
	if ok then
		logf("[NOTICE]:usernumber=%s no need do devsimauth", usernumber)
		return true
	end
	
	--�жϺ����Ƿ�Ϊ����ͨ�û�
	logf("[NOTICE]:devsimstate=%s ", devsimstate)	

	--�жϺŶ��Ƿ�Ϊ������ˮ
	local district = db.checkPhoneNumber(usernumber)
	logf("[NOTICE]:district=%s ", district)
	
	--�жϺ����Ƿ��ڻ�������У�������
	local ok_whitelist, count = db.selectDevSimWhitelist(usernumber)
	if ok_whitelist and tonumber(count) == 0 then
		logf("[NOTICE]:usernumber=%s not in devsimwhitelist", usernumber)
	else
		logf("[NOTICE]:usernumber=%s in devsimwhitelist", usernumber)
	end
	--�жϺ����Ƿ���������������У��
	local ok_devsimauth, result = db.SisMemberRedis("DevSimAuth", usernumber .. "_" .. domainname)
	if ok_devsimauth and tonumber(result) == 0 then
		logf("[NOTICE]:usernumber=%s not yet do devsim auth", usernumber)
	else
		logf("[NOTICE]:usernumber=%s already did devsim auth", usernumber)
	end
	--�жϻ�������У���Ƿ��ڿ���or�������ʮ������
	local ok_devsimusertime = db.getVerification("Devsimusertime_" .. usernumber .. "_" .. domainname)
	if ok_devsimusertime then
		logf("[NOTICE]:usernumber=%s within times", usernumber)
	else
		logf("[NOTICE]:usernumber=%s without times", usernumber)
	end
	
	--����ͨ�û�and��������ݷ���ˮand���벻�ڰ�����andû������������У��and�������ʮ������
	if (tonumber(devsimstate) == 1) and (district == "other") and (ok_whitelist and tonumber(count) == 0) and (ok_devsimauth and tonumber(result) == 0) and (ok_devsimusertime) then
		
		logf("[NOTICE]:usernumber=%s get SDK  device location info=%s", usernumber, locationinfo)
		if (locationinfo ~= "get location authority failed") and (locationinfo ~= "no activate location authority") and (locationinfo ~= "") then
		
			--����wifias�ӿڻ�ȡ�����ڵĵ���
			local ok, r = checkSimLocationToWfcAs(wfc_conf.wfcAs.checkSimLocation, usernumber)
			if ok and (r.countrycode == "86" or r.mscaddress == "") then
				logf("[NOTICE]:usernumber=%s get wifias sim location info=%s", usernumber, r.country_en)
				
				local locationStr2 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 2)
				local locationStr4 = comm.SubStringUTF8(gb_utf8(locationinfo), 1, 4)
				
				if (locationStr2 == gb_utf8("�й�") and locationStr4 ~= gb_utf8("�й����") and locationStr4 ~= gb_utf8("�й�����") and locationStr4 ~= gb_utf8("�й�̨��")) or (string.sub(locationinfo,1,5)=="China" and string.sub(locationinfo,1,10)~="ChinaMacao" and string.sub(locationinfo,1,14)~="ChinaHong Kong" and string.sub(locationinfo,1,11)~="ChinaTaiwan") then
					
					--��¼��ʶ�ú����Ѿ�������������У��
					db.SetAddRedis("DevSimAuth", usernumber .. "_" .. domainname)
				else
					return false
				end
			end
		end
	end
	
	return true
end

--�ж�imei�Ƿ�ı�
--[[
	return: 1  ���û�δע��
			2  imei�����仯
			3  imeiδ�����仯
]]
local function judgeIMEI(original_imei, current_imei, app)
	if tonumber(app["imeistate"]) == 1 then
		--imei��ȫ���ؿ���
		if original_imei ~= current_imei then
			--imei�����仯
			return false
		end
		--imeiδ�����仯
		return true
	else
		--imei��ȫ���عر�
		logf("[NOTICE]:imei state=%s",app["imeistate"])
		return true
	end
end


--����������Ϣ
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
			["apns_production"] = true  --������������
		}
	}
	
	table.insert(httpBody.audience.registration_id, originaldevicecode)
	
	logf("[NOTICE]:***********************push notify to JIGUANG, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("JPush", url, httpHeader, httpBody)
	logf("[NOTICE]:response from JIGUANG = %s", table2json(r))
	
	--��¼�����û�����֪ͨ��־
	db.savePushofflineLogInfoDB(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, r.Retn)
	
	if r.Retn ~= "200" then
		logf("[ERROR]:push notify to JIGUANG failed, response Header status=%s", r.Retn)
		return
	end
	logf("[NOTICE]:push notify to JIGUANG success")
	return
end

--����������Ϣ
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
			["apns_production"] = true  --������������
		}
	}
	
	table.insert(httpBody.audience.registration_id, originaldevicecode)
	
	logf("[NOTICE]:***********************push notify to JIGUANG, url=%s,httpBody=%s",url,table2json(httpBody))
	
	local r = http.post("JPush", url, httpHeader, httpBody)
	logf("[NOTICE]:response from JIGUANG = %s", table2json(r))
	
	--��¼�����û�����֪ͨ��־
	db.savePushofflineLogInfoDB(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, r.Retn)
	
	if r.Retn ~= "200" then
		logf("[ERROR]:push notify to JIGUANG failed, response Header status=%s", r.Retn)
		return
	end
	logf("[NOTICE]:push notify to JIGUANG success")
	
	return
end

--֪ͨwificallingAS���û�����ͨ��(����������)
local function setUserCallUnavailable(url, phoneinfo, barringtype, lockreason, timerlogflag, desc)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["lockflag"] = "1",   --1������
		["barringtype"] = barringtype,
		--[[1������  2������  3��MO����  4: MT����   5: ���������롢MO���š�MT����]]
		["lockreason"] = lockreason
		--[[����ԭ��1����Ȩ��ʱ2��������ȷ��λ��3������]]
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
	
	--��¼�������־
	if type(phoneinfo) == "table" then
		for i=1, #phoneinfo do
			db.saveUserCallbarringLog(phoneinfo[i], httpBody.lockflag, httpBody.barringtype, desc)
		end
	elseif type(phoneinfo) == "string" then
		db.saveUserCallbarringLog(phoneinfo, httpBody.lockflag, httpBody.barringtype, desc)
	end
	
	return true
end

--֪ͨwificallingAS���û�����ͨ��
local function setUserCallAvailable(url, phoneinfo, locationinfo)

	local httpHeader = {
		["Content-Type"] = "application/json;charset=UTF-8"
	}
	
	local httpBody = {
		["lockflag"] = "0",  --0������
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
	
	--��¼�������־
	if type(phoneinfo) == "table" then
		for i=1, #phoneinfo do
			db.saveUserCallbarringLog(phoneinfo[i], httpBody.lockflag, httpBody.barringtype, "auth request success")
		end
	elseif type(phoneinfo) == "string" then
		db.saveUserCallbarringLog(phoneinfo, httpBody.lockflag, httpBody.barringtype, "auth request success")
	end
	
	return true, r
end

--֪ͨwificallingas���imsi
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

--��wificallingAS�����µ���Ȩ��
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

--��wificallingAS�����л��豸
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


--�����û���ʱ��
local function updateTimer(phonenumber,domain)
	local key = phonenumber .. "_" .. domain
	--��redis��ɾ���û���¼
	local r = redis.get("wfc", key, 1)
	if(type(r) == "number" and r == -1) then
		logf("[ERROR_TIMER]:delete data timer failed")
		return false
	else
		logf("[NOTICE_TIMER]:delete data timer success")
	end

	--��redis�б����û���¼ redis.save("wfc", "�û�����_����", "�û����� ����")  
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

-- ���������������Ϊ��ҵ�������������Ƿ�ƥ��
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

--���Ϳ�����Ϣ��EOP
local function sendOpenAccountInfoToEop(EOP_appkey, EOP_secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname, eopaddr)
	local function getSignature()
		local timestamp = string.format("%d", os.time())
		local tempsignature = crypto.hash("md5", timestamp .. EOP_secret)
		local signature = string.sub(tempsignature, 17, 32)
		return timestamp, signature
	end
	local function accesstypeFunc(accesstype)
	--[[
		0��SIP�������Խ�
		1��SDK�Խ�
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

--��wificallingAS��������֪ͨ
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

--����������Ϣ��EOP
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

------------��������---------------end-------------------------


--begin------------------�·���֤��----------------------------

local function getSmsHttpHeader()
	--[[
		������ϢͷX-WSSE��Ҫ�Ĳ��� 
		PasswordDigest�����ݹ�ʽPasswordDigest = Base64 (SHA256 (Nonce + Created + Password))���ɡ����У�Password��App Secret��ֵ��
		Nonce��App��������ʱ���ɵ�һ������������磬66C92B11FF8A425FB8D4CCFE0ED9ED1F��
		Created�����������ʱ�䡣���ñ�׼UTC��ʽ��ΪYYYY-MM-DD'T'hh:mm:ss'Z'�����磬2014-01-07T01:58:21Z��
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
    templateMsg.smsTemplateId  = aeptemplateid --ģ��id
	templateMsg.paramValue  = {}
	templateMsg.paramValue.number = verificode --��֤��
	if aeptemplateid == "7091c54c-cd09-4c31-bbdf-13a79a67ef27" then  --�����·���֤����Ч�ڶ���
	
		templateMsg.paramValue.minute = verifivalidtime --��֤����Ч��
	end
	templateMsg.notifyURL = wfc_conf.verificationcode.notifyURL --�첽֪ͨ��ַ
	return templateMsg
end

--�����·�������֤������
local function sendSmsVerificationCode(verificode, appkey, bindnumber, alisignname, verifichannel, aeptemplateid, verifivalidtime)
	if tonumber(verifichannel) == 1 then  --1��AEP����
		--������Ϣͷ
		
		local url = wfc_conf.verificationcode.SendURL
		local httpHeader = getSmsHttpHeader()
		
		--������Ϣ��
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
	elseif tonumber(verifichannel) == 2 then  --2����������
	
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
		sortedQueryString = http.urlEncode(gb_utf8(sortedQueryString)) -- UTF8�����ַ���ת�ٷֺű���
		sortedQueryString = string.gsub(sortedQueryString, ':', '%%3A') -- http.urlEncode()û�д���:����������
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)

		local stringToSign = http.urlEncode(sortedQueryString)
		stringToSign = string.gsub(stringToSign, '%%', '%%25') -- ���⴦��% & =
		stringToSign = string.gsub(stringToSign, '&', '%%26')
		stringToSign = string.gsub(stringToSign, '=', '%%3D')
		stringToSign = 'GET&%2F&' .. stringToSign
		logf("[NOTICE]:stringToSign=%s", stringToSign)
					  
		local accessSecret = wfc_conf.verificationcode.AccessSecret_ali .. '&'
		local signData = base64Encode(hex2bin(crypto.hash('HMACSHA1', stringToSign, accessSecret)))
		logf("[NOTICE]:signData=%s", signData)

		local signature = http.urlEncode(signData)
		signature = string.gsub(signature, '/', '%%2F') -- ���⴦��
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

-- �����·���֤��
local function handleSmsVerification(argt)
--[[
	{
	"bindnumber": "13712345678",   �û���ʵ����
	"imei": "864399020227188"
	"registration_id": "170976fa8a8220f42d4" �����豸���
	"device_type": "android"     Ŀǰֻ��android/ios��������
	}

]]
	local accessobj = access.new()
	
	--����·���֤�����
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
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--��֤����ͨ��
	
	--1������û������Ƿ�Ϊ�ƶ�
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		return
	end
	
	--2������Ƿ�Ƶ���·���֤��
	local ok = db.getVerification("frequencytime_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
	if ok then
		--˵����Ƶ���·���֤��
		logf("[ERROR]:Verification code request too often")
		comm.sendResponseToThirdParty("200", "20000006", access.errcode["20000006"] .. tostring(wfc_conf.verificationcode.frequencytime) .. "s")
		return
	end
	
	--3����ȡ��֤��, ��֮ǰ����֤��û���������ʹ��֮ǰ����֤���·������ѹ��ڵ������µ���֤���·�
	local ok_verification, verificode = db.getVerification(accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
	if not ok_verification then
		--4��������֤��
		verificode = comm.produceVerificationcode()

		--5���洢��֤����Ϣ
		--[[
			set  appkey_�û�����  ��֤��
			expire  �û�����  ��Ч��
		]]
		local ok = db.recordVerification(accessobj.appkey .. "_" .. accessobj.argt.bindnumber, verificode, tonumber(accessobj.app["verifivalidtime"])*60)
		if not ok then
			logf("[ERROR]:record verification code %s error", tostring(verificode))
			comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return
		end
	end
	
	--
	--6������AEP�ӿ��·���֤�����
	local ok, r = sendSmsVerificationCode(verificode, accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["alisignname"], accessobj.app["verifichannel"], accessobj.app["aeptemplateid"], accessobj.app["verifivalidtime"])
	if not ok then
		logf("[ERROR]:Verification code send failed")
		
		comm.sendResponseToThirdParty("200", "20000005", access.errcode["20000005"])
	else
		--7����¼������֤����Ϣ����Чʱ��wfc_conf.verificationcode.frequencytime,�´η�����֤��������wfc_conf.verificationcode.frequencytime,����ʧ��
		--set frequencytime_CCCCCCCCCCCCCCCCCCCCCC_13522807109  123456
		--expire frequencytime_CCCCCCCCCCCCCCCCCCCCCC_13522807109 wfc_conf.verificationcode.frequencytime
		db.recordVerification("frequencytime_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, verificode, wfc_conf.verificationcode.frequencytime)
		
		--8�������Ȩ��Ϣ����Ч��wfc_conf.authinfo.outtime
		local ok, imsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr , accessobj.argt.bindnumber)
		if not ok then
			imsi = ""
		end
		db.recordauthinfo("Authinfo_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, accessobj.argt.registration_id, accessobj.argt.imei, imsi, accessobj.argt.device_type, wfc_conf.authinfo.outtime)
		
		comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	end
	return
end

--end------------------�·���֤��----------------------------

--begin------------------��֤����֪ͨ----------------------------
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
	
	--��¼�û��·���֤����֪ͨ��־
	db.saveNotifyVerifiCodeLogInfoDB(smsid, status, appkey, usernumber)

	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end------------------��֤����֪ͨ----------------------------

--begin------------------ͳ����֤��ɹ���----------------------------
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

	--ÿ10����ͳ�ƹ�ȥһ��Сʱ,ʧ����֤���������ɹ���֤��������ı�ֵ
	
	local ok, mysqlData = db.statisticsNotifyVerifiCodeLogInfoDB(comm.getTime(), comm.getTime(os.time()-60*60))
	if not ok then
		--˵�����ʱ��û���û�������֤��
		return
	end

	local succeednum, failednum = statisticsSmsFunc(mysqlData)
	
	if (succeednum+failednum) > 20 and failednum > 0 and (succeednum/failednum) < 1 then
		--һ��Сʱ����֤���������20 ���� ʧ�ܵĴ������ڳɹ��Ĵ���
		
		--1����AEP�·���֤��ʧ�ܺ��Զ��л�����������Appkey �л�Ϊ��������
		db.updateVerifichannel_thirdparty_app("2")
		
		--2�����͸澯���澯������
		local httpBody = {}
		httpBody.alarmmodule = "safeServer"
		httpBody.usernumber = ""
		httpBody.alarmtime = comm.getTime()
		httpBody.alarmtype = "��֤���쳣����֤���·������л�"
		httpBody.alarmcode = "1001"
		
		local r = callSmp(wfc_conf.version, "alarminfo_v1", httpBody)
		if r.code ~= "00000000" then
			logf("[ERROR]:send alarm msg failed")
		end
	end
	return
end
--end------------------ͳ����֤��ɹ���----------------------------

--begin-----------------���������û�У���루����ͬ��֤�룩-----------------------------
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
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	
	--1������û������Ƿ�Ϊ�ƶ�
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:Bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		return
	end
	
	--2����ѯ�û������Ƿ�Ϊ�պ�imsi
	
	local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.sendImsiAddr, accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:User imsi check failed")
		comm.sendResponseToThirdParty("200", "20000023", access.errcode["20000023"])
		return
	end
	
	
	--3������У����
	local verificode = comm.produceVerificationcode()

	--5���洢У������Ϣ
	--[[
		set  appkey_�û�����  ��֤��
		expire  �û�����  ��Ч��
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
--end-------------------���������û�У���루����ͬ��֤�룩-----------------------------

--begin-----------------�û���Ȩ-----------------------------

--���ն����ͼ���֪ͨ
local function notifyJPush(originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
	logf("[NOTICE]:originaldevicecode:%s,originaldevicetype:%s", originaldevicecode,originaldevicetype)
	if originaldevicetype == "android" then
		--android����Ϣ����
		--���ɻ�������
		notifyPushAndroid(wfc_conf.JPush.Addr, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
		
	else
		--ios����Ϣ����
		
		--���ɻ�������
		notifyPushIos(wfc_conf.JPush.Addr, originaldevicecode, originaldevicetype, currentdevicecode, currentdevicetype, content, app)
		
	end
	return
end

--�ж�imsi�Ƿ�ı�
local function judgeIMSI(imsi,argt,app)
	if tonumber(app["imsistate"]) == 1 then
		--imsi��ȫ���ؿ���
		--֪ͨwificallingAS��ѯ��ǰIMSI
		local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, argt.bindnumber)
		
		if not ok then
			--wificallingAS��Ӧʧ��, ����AEP����ʧ��
			return false,currentimsi
		end
		--3����֮ǰ��imsi�Ƚ�,�ж�imsi�Ƿ�ı�
		if (currentimsi == imsi) then
			logf("[NOTICE]:usernumber=%s, imsi no change : original imsi=%s, current imsi=%s", argt.bindnumber, imsi, currentimsi)
		else
			logf("[ERROR]:usernumber=%s,imsi change : original imsi=%s, current imsi=%s", argt.bindnumber, imsi, currentimsi)

			return false,currentimsi
		end
		return true,currentimsi
	else
		--imsi��ȫ���عر�
		logf("[NOTICE]:usernumber=%s,imsi state=%s", argt.bindnumber, app["imsistate"])
		return true
	end
end


local function judgeAuthcodelog(phonenumber, domain, authcode, deadline)
	--��¼�û���Ȩ����־
	local errcode, affected_rows = db.saveUserAuthcodeLog(phonenumber, domain, authcode, deadline)
	if affected_rows <= 0 then
		logf("[ERROR]:save wfc_userauthcodelog failed")
		return false
	end
	return true
end

--�����µ���Ȩ��,SIP�Խӷ�ʽ��Ȩ�뷢��wificallingas,�����¶�ʱ��
local function handleAuthcode(accesstype, domain, phonenumber, imei)
	--������Ȩ��
	local authcode = crypto.hash("md5", imei .. tostring(os.time()))
	local deadline = os.time()+wfc_conf.callingvalidtime
	
	logf("[NOTICE]:produce authcode=%s, deadline=%s", authcode, comm.getTime(deadline))
	if tonumber(accesstype) == 1 then
		--SDK�Խӷ�ʽ
		
		local ok = judgeAuthcodelog(phonenumber, domain, nil, deadline)
		if not ok then
			return "200", "30000001", access.errcode["30000001"]
		end
		
		--���¶�ʱ��
		local ok = updateTimer(phonenumber,domain)
		if not ok then
			logf("[ERROR]:update timer failed")
			return "200", "30000001", access.errcode["30000001"]
		end

		return "200", "00000000", access.errcode["00000000"], deadline
	else
		--SIP�Խӷ�ʽ
		
		local ok = judgeAuthcodelog(phonenumber, domain, authcode, deadline)
		if not ok then
			return "200", "30000001", access.errcode["30000001"]
		end
		
		--���¶�ʱ��
		local ok = updateTimer(phonenumber,domain)
		if not ok then
			logf("[ERROR]:update timer failed")
			return "200", "30000001", access.errcode["30000001"]
		end
		--��wificallingAS�����µ���Ȩ��
		local ok = notifyAuthCodeToWfcAs(wfc_conf.wfcAs.setAuthcodeAddr, authcode, phonenumber, domain)
		if not ok then
			logf("[ERROR]:send notifyAuthCode to wificallingAs failed")
			return "200", "30000001", access.errcode["30000001"]
		end
		return "200", "00000000", access.errcode["00000000"], deadline, authcode
	end
end

--��Я����֤���¼����
local function userLoginNoVerification(imei,imsi,devicecode,devicetype,argt,app)
	
	--1���ж�imei�Ƿ�ı�
	local ok_imei = judgeIMEI(imei, argt.imei, app)
	if not ok_imei then
	   	--�ж��Ƿ���Ҫ�߻�������У������  true:����Ҫ    false:��Ҫ
		local ok = judgedevSimornot(argt.bindnumber)
		if not ok then
			--�����ն˺���Ҫ�����жϻ�������
			db.SetSremRedis("DevSimAuth", argt.bindnumber .. "_" .. app["domainname"])
		
			--��¼���ն˵�ʱ��
			db.recordVerification("Devsimusertime_" .. argt.bindnumber .. "_" .. app["domainname"], 1, wfc_conf.devsimtime)
		end     

		
		logf("[ERROR]:usernumber=%s, imei change : original imei=%s, current imei=%s", argt.bindnumber, imei, argt.imei)
	else
		logf("[NOTICE]:usernumber=%s,imei no change", argt.bindnumber)
	end

	--2���ж�imsi�Ƿ�ı�
	local ok_imsi, currentimsi = judgeIMSI(imsi,argt,app)
	if not ok_imsi then
		--imsi�����仯,֪ͨwificallingAS�û� ����������MO����
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1,3", "3", "", "imsi change")
		
		--ɾ��redis�еļ�¼������5������Ч�ڵ���ʱ�ַ���һ������
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
	end
	
	if ((ok_imei == false) or (ok_imsi == false)) then
		--imei�����仯 or imsi�����仯, ��Ҫ��֤�����¼�Ȩ
		
		db.saveUserNeedVerifiAuthLogDB(argt.bindnumber, app["domainname"], ok_imei, ok_imsi, imei, argt.imei, imsi, currentimsi)
		return 200, "20000010", access.errcode["20000010"]
	end
	
	--3���ж��ն���������λ��
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--֪ͨwificallingAS�û�����ͨ��,��������
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:".. locationinfo_desc)
		
		--ɾ��redis�еļ�¼������5������Ч�ڵ���ʱ�ַ���һ������
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		return 200, "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc
	end

	
	--��ʱ������ȫ��Ȩ�Ѿ�����
	
	--֪ͨwificallingAS���û�����ͨ��
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS��Ӧʧ��, ����AEP����ʧ��
		if r.code == "00040032" then --�û�����ͣ��״̬,��Ȩʧ��,SDK����ʾ�û���ֵ��ʹ��APP
			return 200, "20000027", access.errcode["20000027"]
		else
			return 200, "30000001", access.errcode["30000001"]
		end
	end
	
	--�����µ���Ȩ��,SIP�Խӷ�ʽ��Ȩ�뷢��wificallingas,�����¶�ʱ��
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	return httpcode, code, desc, deadline, authcode
end

--��֤�뿪�عر��µļ�Ȩ����
local function userLoginNoVerification_trust(appkey,imei,imsi,devicecode,devicetype,argt,app)
	
	--1���ж�imei�Ƿ�ı�
	local ok_imei = judgeIMEI(imei, argt.imei, app)
	if not ok_imei then
		logf("[ERROR]:usernumber=%s,imei change : original imei=%s, current imei=%s", argt.bindnumber, imei, argt.imei)		
	else
		logf("[NOTICE]:usernumber=%s,imei no change", argt.bindnumber)
	end

	--2���ж�imsi�Ƿ�ı�
	local ok_imsi,currentimsi = judgeIMSI(imsi,argt,app)
	if not ok_imsi then
	
		--���ε��û�imsi�����仯,�����������
		logf("[ERROR]:imsi changed")	
	end
	
	--��imei ��imsi ��һ�������˸ı� ����¸��û���Ϣ��
	if ((ok_imei == false) or ((ok_imsi == false) and (currentimsi ~= nil))) then
		--���������û���Ȩ��Ϣ���û���Ϣ��wfc_userauthinfo
		db.updateUserAuthInfoDB(appkey, argt.bindnumber, argt.registration_id, argt.imei, currentimsi, argt.device_type)
	end
	
	--3���ж��ն���������λ��
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--֪ͨwificallingAS�û�����ͨ��,��������
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:"..locationinfo_desc)

		--ɾ��redis�еļ�¼������5������Ч�ڵ���ʱ�ַ���һ������
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		return 200, "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc
	end
	
	
	--��ʱ������ȫ��Ȩ�Ѿ�����
	
	--֪ͨwificallingAS���û�����ͨ��
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS��Ӧʧ��, ����AEP����ʧ��
		if r.code == "00040032" then --�û�����ͣ��״̬,��Ȩʧ��,SDK����ʾ�û���ֵ��ʹ��APP
			return 200, "20000027", access.errcode["20000027"]
		else
			return 200, "30000001", access.errcode["30000001"]
		end
	end
	
	--�����µ���Ȩ��,SIP�Խӷ�ʽ��Ȩ�뷢��wificallingas,�����¶�ʱ��
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	return httpcode, code, desc, deadline, authcode
end


--Я����֤���¼����
local function userLoginHaveVerification(appkey, imei,imsi,devicecode,devicetype,argt,app)

	--֪ͨwificallingAS��ѯ��ǰIMSI
	_, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, argt.bindnumber)
	
	local ok = judgeIMEI(imei, argt.imei, app)
	if not ok then
		--�ն˸�����
		logf("[NOTICE]:usernumber=%s, changed terminal service", argt.bindnumber)	
	end
	
	--���������û���Ȩ��Ϣ��Ϣ��wfc_userauthinfo
	db.updateUserAuthInfoDB(appkey, argt.bindnumber, argt.registration_id, argt.imei, currentimsi, argt.device_type)
	
	--�ж��ն���������λ��
	local ok, locationinfo_desc = judgeLocation(argt.bindnumber, argt.locationinfo, argt.HttpHeader.realip, app)
	if not ok then
		logf("[ERROR]:usernumber=%s, no verification login: not right place", argt.bindnumber)
		--�����ն�Ӧ�������ڵ�λ�ã���֪ͨwificallingAS�����û�,��������
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], "1", "2", "", "not right place:"..locationinfo_desc)
		
		--ɾ��redis�еļ�¼������5������Ч�ڵ���ʱ�ַ���һ������
		redis.get("wfc", argt.bindnumber.."_"..app["domainname"], 1)
		
		
		comm.sendAuthResponseToThirdParty("200", "20000011", access.errcode["20000011"] .. " " .. locationinfo_desc)
		return false, access.errcode["20000011"] .. " " .. locationinfo_desc
	end
	
	--֪ͨwificallingAS���û�����ͨ��
	local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, argt.bindnumber.." "..app["domainname"], argt.locationinfo)
	if not ok then
		--wificallingAS��Ӧʧ��, ����AEP����ʧ��
		if r.code == "00040032" then --�û�����ͣ��״̬,��Ȩʧ��,SDK����ʾ�û���ֵ��ʹ��APP
			comm.sendAuthResponseToThirdParty("200", "20000027", access.errcode["20000027"])
			return false, access.errcode["20000027"]
		else
			comm.sendAuthResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return false, access.errcode["30000001"]
		end
	end
	
	--�����µ���Ȩ��,SIP�Խӷ�ʽ��Ȩ�뷢��wificallingas,�����¶�ʱ��
	local httpcode, code, desc, deadline, authcode = handleAuthcode(app["accesstype"],app["domainname"],argt.bindnumber,argt.imei)
	
	--������Ӧ
	comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc, deadline, authcode)
	if code ~= "00000000" then
		--������Ȩ��ʧ�ܻ���¶�ʱ��ʧ��,������Ҫ����������
		return false, desc
	end
	
	return true, "success", authcode
end

--�û���¼���̴�����
local function userAuthMain(appkey,imei,imsi,devicecode,devicetype,verifnumber,argt,app)

	if tonumber(app.verifstate) == 1 then
		--1����֤�밲ȫ���ؿ���
		if argt.verificationcode == nil then
		
			--1.1��Я����֤���¼����
			logf("[NOTICE]: ####### user no verificode login")
			local httpcode, code, desc, deadline, authcode = userLoginNoVerification(imei,imsi,devicecode,devicetype,argt,app)
			comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc, deadline, authcode)
			if code == "00000000" then
				return true, desc, authcode
			else
				return false, desc
			end
		else
			--1.2Я����֤���¼����
			logf("[NOTICE]: ####### user verificode login")
			--У����֤��
			local ok, httpcode, code, desc = checkVerificationCode(appkey, verifnumber, argt.verificationcode)
			if not ok then
				comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc)
				return ok, desc
			end
			
			local ok, desc, authcode = userLoginHaveVerification(appkey,imei,imsi,devicecode,devicetype,argt,app)
			return ok, desc, authcode
		end
	else
		--2����֤�밲ȫ���عر�		
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

-- �����û���Ȩ
local function handleUserAuth(argt)
--[[
{
	"bindnumber":"13612341234" ,
	"verificationcode":"654321",  ��֤�루�Զ���½��������֤�������
	"imei": "864399020227188",
	"registration_id": "170976fa8a8220f42d4",
	"device_type": "android",
	"device_name": "iPhone7Plues",
	"device_version": "IOS10.1.1",
	"locationinfo": "�й������к�����"
}
]]
	local accessobj = access.new()
	
	--����·���֤�����
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
		
		--imei����Ϊ���ַ���
		if argt.imei == "" then
			return false, 200 , "20000001", access.errcode["20000001"] .. "imei"
		end
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendAuthResponseToThirdParty(tostring(httpcode), code, desc)
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", desc)
		return
	end
	
	--1���鿴�û��Ƿ�Ƶ��������Ȩ
	if wfc_conf.authfrequency.flag then
		local ok = db.getAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
		if ok then
			--˵����Ƶ��������Ȩ����
			logf("[ERROR]:User auth too often")
			comm.sendAuthResponseToThirdParty("200", "20000007", access.errcode["20000007"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "User auth too often")
			return
		end
	end
	
	--2���鿴��Ȩ�����Ƿ�Ϸ�
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:Invalid parameter - bindnumber")
	    comm.sendAuthResponseToThirdParty("200", "20000001", access.errcode["20000001"] .. "bindnumber")
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", access.errcode["20000001"] .. "bindnumber")
		return
	end
	
	--3���ڵ����ͨ���ź���ļ�Ȩ,ֱ�ӷ��ؼ�Ȩ�ɹ�
	if (tonumber(accessobj.app["yidian"]) == 1) and (teltype ~= "YD") then
		logf("[NOTICE]:YIDIAN LT or DX forward auth")
		
		comm.sendAuthResponseToThirdParty("200", "00000000", access.errcode["00000000"])
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "0", access.errcode["00000000"])
		
		--��¼�û�������ȨƵ��
		if wfc_conf.authfrequency.flag then
			db.recordAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, "1", wfc_conf.authfrequency.time)
		end
		return
	end
	
	--4����ѯ�û��Ƿ�δ����
	local ok,appkey,verifnumber = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		logf("[ERROR]:User not open account")
		comm.sendAuthResponseToThirdParty("200", "20000013", access.errcode["20000013"])
			
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "User not open account")
		return
	end
		
	--5����ѯ�û���Ȩ��Ϣ
	local ok, appkey, imei, imsi, devicecode, devicetype = db.selectUserAuthInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		--˵�����û�ע���ĵ�һ�μ�Ȩ
		logf("[NOTICE]:this is user first auth process, need check imsi")
		
		--֪ͨwificallingAS��ѯ��ǰIMSI
		local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.checkImsiAddr, accessobj.argt.bindnumber)
		if not ok then
			--wificallingAS��Ӧʧ��, ����AEP����ʧ��
			comm.sendAuthResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "wificallingAS check imsi return fail")
			return
		end
		
		--��imei��imsi��devicecode��devicetype���뵽�û���Ȩ��Ϣ��
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
	
	--��������У��
	local ok = devSimAuthFunc(accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.app["devsimstate"], accessobj.argt.locationinfo)
	if not ok then
		
		comm.sendAuthResponseToThirdParty("200", "20000010", access.errcode["20000010"])
		
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "2", "1", "device and sim not same")
		return
	end
	
	
	--6���û���Ȩ���̴�����
	local ok, desc, authcode = userAuthMain(accessobj.appkey, imei, imsi, devicecode, devicetype, verifnumber, accessobj.argt, accessobj.app)
	if ok then
		--��¼�û��ɹ���¼��Ϣ
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, imei, imsi, accessobj.argt.device_version, accessobj.argt.device_name, accessobj.argt.locationinfo, authcode, "2", "0", desc)
		
		--��¼�û�������ȨƵ��
		if wfc_conf.authfrequency.flag then
			db.recordAuthFrequency("frequencytimeAuth_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber, "1", wfc_conf.authfrequency.time)
		end
	else
		--��¼�û�ʧ�ܵ�¼��Ϣ
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, imei, imsi, accessobj.argt.device_version, accessobj.argt.device_name, accessobj.argt.locationinfo, authcode, "2", "1", desc)
	end
	return 
end

--end-----------------�û���Ȩ-----------------------------

--begin---------------�û�ע��-----------------------------

--��wificallingAS���Ϳ���֪ͨ
local function openAccountInfoToWfcAs(url,appkey,bindnumber,domain,siprelay,secretkey,accesstype,businesstype,callauth,oaflag,imsi,msrn)
--[[
APP�Խӷ�ʽ
1��SDK�Խӷ�ʽ��eop��
2��SIP�Խӷ�ʽ��eop��ҵ���������
3�����ǿ��SIP���뷽ʽ��ҵ���������

]]
	local function accesstypeFunc(accesstype)
	--[[
		0��SIP�������Խ�
		1��SDK�Խ�
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
		--˵������è�����������
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

--�������ݿ���ֶ�accesstype���뷽ʽ���� ������Ϣ��֪�ķ�����
local function handleOpenAccountInfo(appkey, bindnumber, oaflag, accesstype, sipuri, sipuripassword, siprelaypassword, domainname, siprelay, eopaddr)
	if tonumber(accesstype) == 1 then
		--ת�ۣ�SDK�Խӷ�ʽ��eop��ҵ���������
		
		--1 ����eop���û�ע����Ϣ

		local ok = sendOpenAccountInfoToEop(wfc_conf.EBEOP.appkey, wfc_conf.EBEOP.secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname,eopaddr)
		if not ok then
		ok=true end
		if not ok then
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return false
		end
		--2 ������Ӧ��AEP,SIP������AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
	elseif tonumber(accesstype) == 2 then
		--ת�ۣ���������SIP�Խӷ�ʽ(eop��ҵ�������)
		
		--1 ����eop���û�ע����Ϣ

		local ok = sendOpenAccountInfoToEop(wfc_conf.EBEOP.appkey, wfc_conf.EBEOP.secret, accesstype, appkey, bindnumber, oaflag, sipuripassword, siprelay, siprelaypassword, domainname,eopaddr)
		if not ok then
		ok = true 
		end 
		if not ok then
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return false
		end
		
		--2��������Ӧ��AEP, SIP�ź͵�¼��������AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri, sipuripassword) 
		
	elseif tonumber(accesstype) == 3 then
		--��ת�ۣ�SIP���뷽ʽ(ҵ�������)
		
		--1 ������Ӧ��AEP, SIP�š�SIP�м̺ź���Կ����AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri, nil, siprelay, siprelaypassword) 
		
	elseif tonumber(accesstype) == 4 then
		--��ת�ۣ�SDK���뷽ʽ(ҵ�������)
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
		
	elseif tonumber(accesstype) == 5 then
		--΢push�Խӷ�ʽ
		
		--1 ������Ӧ��AEP,��AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
		
	elseif tonumber(accesstype) == 6 then
		--�����жԽӷ�ʽ
		
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipuri)
	end
	return true
end


local function handleUserRegister(argt)
--[[
ûʹ��С�Ź���
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --ת���и��ֶ�
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", 
	"bindnumber": "13712345678",    --ֻ�����ƶ�����
	"oaflag":"0",
	"verificationcode":"654321"
	}

ʹ��С�Ź���
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --ת���и��ֶ�
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", 
	"bindnumber": "13712345678",  �������   --ֻ�����ƶ�����
	"verifnumber": "18612345678",  ��ʵ����
	"oaflag":"0",
	"verificationcode":"654321"
	}

��ת��
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --������appkey,  AEP��HTTP��Ϣͷ��appkey�ŵ���Ϣ��appid�з�����ȫ���Ʒ�����
	"bindnumber": "13712345678", 
	"verificationcode":"654321"
	}
ת��
	{
	"appid":"fghj6jk3453gey783rggfbkul98o",      --ebupt��appkey,  AEP��HTTP��Ϣͷ��appkey�ŵ���Ϣ��appid�з�����ȫ���Ʒ�����
	"companyid":"wefsfsdfsdgthtfgergbtrbtrbrtb", --������appkey
	"bindnumber": "13712345678", 
	"oaflag":"0",
	"verificationcode":"654321",
	"imsi":"460203850485409",
	"msrn":"122222"
	}

]]
	local accessobj = access.new()
	
	--����sip��Կ
	local function getSipcode(phonenumber,domainname)
		local function siprelayFunc(phonenumber)
			local siprelaypassword = crypto.hash("md5", phonenumber .. tostring(os.time()))
			return siprelaypassword
		end
		local sipuri = "sip:" .. accessobj.argt.bindnumber .."@" .. domainname
		local sipuripassword,siprelaypassword = comm.genuuid(), siprelayFunc(phonenumber)
		return sipuri,sipuripassword,siprelaypassword
	end
	--��ȡURL��ʶ
	local function getBusinessType(url)
		--/datavoice/v1/user_insert
		local urltab = comm.strsplit(url, "/")
		return urltab[2]
		--return datavoice
	end
	--����û�ע�����
	local function isvalidVerificationcode()

		local rule = {
			bindnumber = { mo = "M", ck = "^1[0-9]{10}$" },
			appid = { mo = "M" },
			verificationcode = { mo = "O" }, --ʹ�������֤�и��ֶ�
			oaflag = { mo = "O" },     --�޸��ֶκ���ASĬ��Ϊ��ͨ�û�
			companyid = { mo = "O" },  --ת���и��ֶ�
			verifnumber = { mo = "O" }, --ʹ��С���и��ֶ�
			--alitoken = { mo = "O" } --������֤token
		}
		local r, e = check(accessobj.argt, rule)
		if not r then
			logf("[ERROR]:Invalid parameter %s", e)
			return false, 200 , "20000001", access.errcode["20000001"] .. e
		end
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --������Ϣ��table
	
	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--1��ת��or��ת����ز���
	if accessobj.argt.companyid == nil then
		--companyidΪ��˵��Ϊ��ת�۷�ʽ  ���ֶ�companyid,��appid����companyid
		accessobj.argt.companyid = accessobj.argt.appid
	end

	--2����ȡ��������ҵ����Ϣ
	accessobj.appkey = accessobj.argt.companyid
	accessobj:read_thirdparty_app()
	
	--�����к����Ƿ�Ϊ�ƶ�����
	local ok, teltype = comm.getTypeByNumber(accessobj.argt.bindnumber)
	if (ok == false) or (teltype ~= "YD") then
		logf("[ERROR]:bindnumber is not YD number")
		comm.sendResponseToThirdParty("200", "20000021", access.errcode["20000021"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000021"])
		return
	end
	
	--3������С����ؼ��
	if tonumber(accessobj.app["virtualflag"]) == 0 then
		--������С�ſ��عر�ʱ,���к�����У����֤����� ��ͬ
		accessobj.argt.verifnumber = accessobj.argt.bindnumber
	else 
		--������С�ſ��ؿ���ʱ,��ѯ�Ƿ�Ϊ������ҵ������������
		local ok, httpcode, code, desc = checkVirtualNum(accessobj.appkey, accessobj.argt.bindnumber)
		if not ok then
			comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", desc)
			return
		end
	end
	
	-- ��Ϊ��ת���뿪�� 
	if tonumber(accessobj.argt.oaflag) == 1 then
		accessobj.app["verifstate"] = "0" --����ΪУ����֤�뿪�عر�
		accessobj.app["callauth"] = "1"  --����Ȩ�޿������������û�Ϊ���н���������ȴ������֪ͨ
		
		--���¶�ʱ�� һ��ʱ������ǰת��������к�MO����
		local ok = updateTimer(accessobj.argt.bindnumber,accessobj.app["domainname"])
		if not ok then
			logf("[ERROR]:update timer failed")
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			return
		end
	end
	
	--4���鿴�û��Ƿ��Ѿ�ע��
	local ok = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if ok then
		--������Բ�ѯ���û���Ϣ,��˵�����û��Ѿ�ע��
		logf("[ERROR]:User already open account")
		comm.sendResponseToThirdParty("200", "20000012", access.errcode["20000012"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000012"])
		return
	end
	
	
	--���ð�����֤
	local function openAccountInfotoAli(bindnumber)
		logf("ali!!!!!!!!!!!")
		--bindnumber���ֻ���
		
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
		
		--�Ϲ���汾local sortedQueryString = "&AccessCode="..wfc_conf.VerifyMobile.AccessCode.."&AccessKeyId="..wfc_conf.VerifyMobile.AccessKeyId.."&Action=VerifyMobile&".."&Format=JSON".."&PhoneNumber="..bindnumber.."&RegionId=cn-hangzhou".."&ServiceCode=dypnsapi".."&SignatureMethod=HMAC-SHA1".."&SignatureNonce="..uuidgen().."&SignatureVersion=1.0".."&Timestamp="..comm.getUTCTime().."&Version=2017-05-25"
		
		
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)


		--[[
		alidemo url 
		sortedQueryString = "AccessKeyId=testid&AccountId=100000&Action=DescribeDomains&Format=XML&RegionId=cn-hangzhou&SignatureMethod=HMAC-SHA1&SignatureNonce=1d1620f8-0b3e-464c-9967-7b54a867945b&SignatureVersion=1.0&Timestamp=2016-03-29T03%3A33%3A18Z&Version=2016-02-01"
		logf("[NOTICE]:sortedQueryString=%s", sortedQueryString)
		--]]
		
		sortedQueryString = http.urlEncode(gb_utf8(sortedQueryString)) -- UTF8�����ַ���ת�ٷֺű���
		sortedQueryString = string.gsub(sortedQueryString, ':', '%%3A') -- http.urlEncode()û�д���:����������
		logf("[NOTICE]:urlEncode(sortedQueryString)=%s", sortedQueryString)

		local stringToSign = http.urlEncode(sortedQueryString)
		stringToSign = string.gsub(stringToSign, '%%', '%%25') -- ���⴦��% & =
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
		signature = string.gsub(signature, '/', '%%2F') -- ���⴦��
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
	
	
	--5������֤�밲ȫ���ؿ�������У����֤��
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
	
	
	
	--6�������¼�û�����ע����Ϣ ��ֹ�û�������������ע��
	local errcode, affected_rows = db.saveUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
	if affected_rows < 0 then
		logf("[ERROR]:User are opening account")
		comm.sendResponseToThirdParty("200", "20000020", access.errcode["20000020"])
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", access.errcode["20000020"])
		return
	end
	
	--7������sip��, sipע������, sip�м̵���Կ
	local sipuri,sipuripassword,siprelaypassword = getSipcode(accessobj.argt.bindnumber,accessobj.app["domainname"])
	
	--8����wificallingAS�����û�ע��֪ͨ,������Կ�ͶԽ�����
	local ok, r = openAccountInfoToWfcAs(wfc_conf.wfcAs.openUserAddr, accessobj.argt.appid,accessobj.argt.bindnumber,accessobj.app["domainname"],accessobj.app["siprelay"],siprelaypassword,accessobj.app["accesstype"], getBusinessType(accessobj.argt.HttpHeader.Url), accessobj.app["callauth"],accessobj.argt.oaflag, accessobj.argt.imsi, accessobj.argt.msrn)
	if not ok then
		--wificallingAS��Ӧʧ��, ����AEP����ʧ��
		if r.code == "00040010" then
			--�ƶ��Ŷ�ת��������Ӫ�̣�����ʧ��
			comm.sendResponseToThirdParty("200", "20000022", access.errcode["20000022"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "YD number transfer to LTDX")
		elseif r.code == "00040011" then
			--����ʧ�ܣ�imsi��һ�£�δ�й�
			comm.sendResponseToThirdParty("200", "20000028", access.errcode["20000028"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "User register fail, imsi not same")
		elseif r.code == "00040012" then
			--����ʧ�ܣ�imsi��һ�£����й�
			comm.sendResponseToThirdParty("200", "20000029", access.errcode["20000029"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "User register fail, imsi not same, already updateloc")
		else
			--����ʧ��
			comm.sendResponseToThirdParty("200", "20000018", access.errcode["20000018"])
			
			registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "user register to wificallingAS return fail")
		end
		--ɾ���û�����ע����Ϣ
		db.deleteUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
		return
	end
	
	--9�����ݶԽ�������EOP����
	local ok = handleOpenAccountInfo(accessobj.appkey, accessobj.argt.bindnumber, accessobj.argt.oaflag, accessobj.app["accesstype"], sipuri, sipuripassword, siprelaypassword, accessobj.app["domainname"], accessobj.app["siprelay"], accessobj.app["eopaddr"])
	if not ok then ok = true end
	if ok then

		--�û������ɹ�
		
		--9.1����¼�û���Ϣ�����ݿ��wfc_userinfo
		registerUserInfo(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.argt.verifnumber, sipuri, sipuripassword, accessobj.app["siprelay"], siprelaypassword)
		
		--9.2����¼�û���Ȩ��Ϣ���� wfc_userauthinfo
		local ok, registration_id, imei, imsi, device_type = db.getauthinfo("Authinfo_" .. accessobj.appkey .. "_" .. accessobj.argt.bindnumber)
		
		if ok and registration_id ~= nil and imei ~= nil and imsi ~= nil and device_type ~= nil then
			db.saveUserAuthInfoDB(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], registration_id, imei, imsi, device_type)
		end


		--9.3����¼�ɹ�ע����Ϣ����wfc_userinfolog
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "0", "success")
		
		--9.4����¼imsi��msrn����Ϣ
		db.saveUserMsrnInfoDB(accessobj.appkey, accessobj.argt.bindnumber, accessobj.app["domainname"], accessobj.argt.imsi, accessobj.argt.msrn)
		
		--�ж��Ƿ���Ҫ�߻�������У������  true:����Ҫ    false:��Ҫ
		local ok = judgedevSimornot(accessobj.argt.bindnumber)
		if not ok then
			--9.5����¼����״̬��������ʹ��
			db.recordVerification("Devsimusertime_" .. accessobj.argt.bindnumber .. "_" .. accessobj.app["domainname"], 1, wfc_conf.devsimtime)
		end
	else
		--�û�����ʧ��
		
		--11����¼ʧ��ע����Ϣ����wfc_userinfolog
		registerUserLogInfo(accessobj.appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "1", "1", "EOP return fail")
	end
	
	--ɾ���û�����ע����Ϣ
	db.deleteUserOpenAccountingDB(accessobj.appkey, accessobj.argt.bindnumber)
	return
end


--end-----------------�û�ע��-----------------------------




--begin-------------ͨ����ʱ��-----------------------------

local function callingTimeout(argt)
	--ȡ����ʱͨ����Чʱ��(��)�����ǰ100����¼����ɾ����Щ��¼
	local r = redis.get_timeout("wfc", wfc_conf.callingvalidtime, 100, 1)
	if(type(r) == "number" and r == -1) then
		logf("[ERROR_TIMER]:get redis timer failed")
	elseif(type(r) == "table" and #r == 0) then
		logf("[NOTICE_TIMER]:no redis outtime, phonenumber=%s",table2json(r))
	else
		--r={"�ֻ��� ����","�ֻ��� ����"}
		--֪ͨwificallingAS�û�����ͨ��(����������)
		logf("[NOTICE_TIMER]:get redis outtime, phonenumber=%s",table2json(r))
		
		--ֻ��������
		setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, r, "1", "1", "_TIMER", "auth request outtime")
	end
	return 
end

--end---------------ͨ����ʱ��-----------------------------

--begin-------------�û�����-------------------------------

local function handleUserLogout(argt)
--[[
{
"bindnumber": "sip:13812345679@ebupt.com"
}
]]

	local accessobj = access.new()
	
	--����û���������
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
	accessobj.argt = argt   --������Ϣ��table

	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	--1���鿴�û��Ƿ��Ѿ�����
	local ok, appkey = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	if not ok then
		--��ѯ�����û���Ϣ,��˵�����û��Ѿ�����
		logf("[ERROR]:User already close account")
		comm.sendResponseToThirdParty("200", "20000016", access.errcode["20000016"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", access.errcode["20000016"])
		return
	end		
	
	--2����ȡ��ҵ��Ϣ
	accessobj.appkey = appkey
	accessobj:read_thirdparty_app()
	
	--2������������Ϣ��wificallingas
	local ok = closeAccountInfoToWfcAs(wfc_conf.wfcAs.closeUserAddr, accessobj.argt.bindnumber, accessobj.argt.domain)
	if not ok then
		comm.sendResponseToThirdParty("200", "20000017", access.errcode["20000017"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", "send close account info to wificallingAS fail")
		return
	end
	
	--3������������Ϣ��EOP
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

	--4��ɾ���û���Ϣ
	local errcode, affected_rows = db.deleteUserInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	if affected_rows < 0 then
		logf("[ERROR]:delete wfc_userinfo failed")
		comm.sendResponseToThirdParty("200", "20000017", access.errcode["20000017"])
		registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "1", "delete wfc_userinfo failed")
		return
	end
	
	--5��ɾ���û���Ȩ��Ϣ
	db.deleteUserAuthInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	
	--6��ɾ��imsi��msrn��Ϣ
	db.deleteUserMsrnInfoDB(accessobj.argt.bindnumber, accessobj.argt.domain)
	
	--7����¼�����û���־
	registerUserLogInfo(appkey, accessobj.argt.bindnumber, "", "", "", "", "", "", "3", "0", "success")
	
	--8����������Ҫ�����жϻ�������
	--�ж��Ƿ���Ҫ�߻�������У������  true:����Ҫ    false:��Ҫ
	local ok = judgedevSimornot(accessobj.argt.bindnumber)
	if not ok then
		db.SetSremRedis("DevSimAuth", accessobj.argt.bindnumber .. "_" .. accessobj.argt.domain)
	end
	
	--9��������Ӧ
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end


--end----------------�û�����-------------------------------

--begin----------------�û�����״̬��ѯ-------------------------------

local function handleUserSelect(argt)
--[[
��ת��
{
"bindnumber": "13712345678",
"appid":"aaaaaaaaaaaaa"
}
ת��
{
"bindnumber": "13712345678",
"appid":"aaaaaaaaaaaaa"         ebupt��appkey
"companyid":"bbbbbbbbbbbbb"     ������appkey
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
	accessobj.argt = argt   --������Ϣ��table

	local ok, httpcode, code, desc = isvalidVerificationcode()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s", httpcode, code)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	--1��ת��or��ת����ز���
	if accessobj.argt.companyid == nil then
		--companyidΪ��˵��Ϊ��ת�۷�ʽ  ���ֶ�companyid,��appid����companyid
		accessobj.argt.companyid = accessobj.argt.appid
	end
	
	--1����ȡ��������ҵ����Ϣ
	accessobj.appkey = accessobj.argt.companyid
	accessobj:read_thirdparty_app()
	
	--2����ѯ�û�������Ϣ
	local ok,appkey,verifnumber,sipcode,sippasswd,siprelay,siprelaypasswd = db.selectUserInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
	if not ok then
		logf("[NOTICE]:User not open account")
		
		comm.sendResponseToThirdParty("200", "20000013", access.errcode["20000013"])
		return 
	end
	
	--3�����ݶԽӷ�ʽ�����û�������Ϣ
	if tonumber(accessobj.app["accesstype"]) == 1 then
		--ת�ۣ�SDK�Խӷ�ʽ
		
		--������Ӧ��AEP,SIP������AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode)
	elseif tonumber(accessobj.app["accesstype"]) == 2 then
		--ת�ۣ���������SIP�Խӷ�ʽ
		
		--������Ӧ��AEP, SIP�ź͵�¼��������AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, sippasswd) 
		
	elseif tonumber(accessobj.app["accesstype"]) == 3 then
		--��ת�ۣ�SIP���뷽ʽ(ҵ�������)
		
		--������Ӧ��AEP, SIP�š�SIP�м̺ź���Կ����AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, nil, siprelay, siprelaypasswd) 
	elseif tonumber(accessobj.app["accesstype"]) == 4 then
		--��ת�ۣ�SDK���뷽ʽ(ҵ�������)
		
		--������Ӧ��AEP,��AEP���ظ�ҵ�������
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode)
	elseif tonumber(accessobj.app["accesstype"]) == 5 then
		--΢push�Խӷ�ʽ
		
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	elseif tonumber(accessobj.app["accesstype"]) == 6 then
		--�����жԽӷ�ʽ
		
		local ok, imsi, msrn = db.selectUserMsrnInfoDB(accessobj.argt.bindnumber, accessobj.app["domainname"])
		if not ok then
			comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"])
                        return
		end
		comm.sendSipInfoResponseToThirdParty("200", "00000000", access.errcode["00000000"], sipcode, nil, nil, nil, msrn, imsi)
	end
	return 
end

--end----------------�û�����״̬��ѯ-------------------------------

--begin------------У���û�������IMSI��Ӧ��ϵ----------------

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
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	--�鿴��ǰ�û���imsi
	local ok, currentimsi = notifyWfcAsCheckImsi(wfc_conf.wfcAs.sendImsiAddr, accessobj.argt.bindnumber)
	if not ok then
		logf("[ERROR]:User imsi check failed")
		comm.sendResponseToThirdParty("200", "20000023", access.errcode["20000023"])
		return
	end
	
	if accessobj.argt.imsi == nil then
		--����û��Ƿ��ڴ���ע��
		if currentimsi == "" then
			logf("[ERROR]:User not register in network")
			comm.sendResponseToThirdParty("200", "20000025", access.errcode["20000025"])
			return
		end
	else
		--�Ƚ�imsi
		if currentimsi ~= accessobj.argt.imsi then
			logf("[ERROR]:Usernumber=%s imsi not same, imsi1=%s, imsi2=%s", accessobj.argt.bindnumber, currentimsi, accessobj.argt.imsi)
			comm.sendResponseToThirdParty("200", "20000024", access.errcode["20000024"])
			return
		end
	end
	
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end--------------У���û�������IMSI��Ӧ��ϵ----------------

--begin--------------ISMP��Ȩ----------------
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

		--��¼��ǰ����ĺ���
		accessobj.phonenumber = accessobj.argt.USERID
	
		return true
	end
	logf("[NOTICE]:********************reqbody = %s",table2json(argt)) 
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:(%s),httpcode:%d, code:%s, desc:%s",tostring(accessobj.phonenumber), httpcode, code, desc)
		comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end

	
	--��������Ƿ�һ��
	if accessobj.argt.SIGN_REG ~= crypto.hash("MD5", accessobj.argt.USERID..accessobj.argt.TIMESTAMP..accessobj.app["appsecret"]) then
		logf("[ERROR]:User password error")
		comm.sendResponseToThirdParty("200", "20000026", access.errcode["20000026"])
		return
	end

	comm.sendIsmpAuthResponseToThirdParty("200", "00000000", access.errcode["00000000"], crypto.hash("MD5", accessobj.argt.SESSIONID..accessobj.argt.TIMESTAMP..accessobj.app["appsecret"]))
	
	return

end
--end--------------ISMP��Ȩ----------------

--begin--------------��������ҵ�Ľ��������----------------
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
	accessobj.argt = argt   --������Ϣ��table
    accessobj.check_requestarg = isvalidVerificationcode
	local ok, httpcode, code, desc = accessobj:access_authentication()
	if not ok then
		logf("[ERROR]:httpcode:%d, code:%s, desc:%s", httpcode, code, desc)
	    comm.sendResponseToThirdParty(tostring(httpcode), code, desc)
		return
	end
	
	if accessobj.argt.lockflag == "0" then
		--����
		local ok, r = setUserCallAvailable(wfc_conf.wfcAs.userCallbarringAddr, accessobj.argt.bindnumber.." "..accessobj.app["domainname"], "")
		if not ok then
			--wificallingAS��Ӧʧ��, ����AEP����ʧ��
			if r.code == "00040032" then --�û�����ͣ��״̬,��Ȩʧ��,SDK����ʾ�û���ֵ��ʹ��APP
				comm.sendResponseToThirdParty("200", "20000027", access.errcode["20000027"])
			else
				comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			end
			return
		end
	elseif accessobj.argt.lockflag == "1" then
		--����
		local ok = setUserCallUnavailable(wfc_conf.wfcAs.userCallbarringAddr, accessobj.argt.bindnumber.." "..accessobj.app["domainname"], accessobj.argt.barringtype, nil, "", "EOP set callbarring state")
		if not ok then
			--wificallingAS��Ӧʧ��, ����AEP����ʧ��
			comm.sendResponseToThirdParty("200", "30000001", access.errcode["30000001"])
			return
		end
	end
	comm.sendResponseToThirdParty("200", "00000000", access.errcode["00000000"])
	return
end

--end----------------��������ҵ�Ľ��������----------------

--begin----------------���͸澯��Ϣ----------------

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
--end------------------���͸澯��Ϣ----------------

--begin---------------�������л��豸----------------

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
	accessobj.argt = argt   --������Ϣ��table
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

--end-----------------�������л��豸----------------

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
	--�����·���֤��
	["sms_verification_code_v1"] = handleSmsVerification, --�·���֤�� https://host:port/wfc/sdk/v1/sms_verification_code
	
	--������֤����֪ͨ
	["notifyTemplateSms_v1"] = handleNotifySmsVerification, -- https://host:port/wfc/v1/notifyTemplateSms
	
	--ͳ����֤��ɹ���
	["statistics_sms_verification_code_v1"] = statisticsSmsVerification, 
	
	--���������û�У���루����ͬ��֤�룩
	["user_checkcode_v1"] = handleUserCheckcode, -- https://host:port/wfc/appserver/v1/user_checkcode
	
	--У���û�������IMSI��Ӧ��ϵ
	["user_checkimsi_v1"] = checkUserImsi, -- https://host:port/wfc/appserver/v1/user_checkimsi
	
--[[
vi conf.slrun.json  CronDrive����Ϊ1

sqlite conf.crontab.db
select * from crontab;
insert into crontab(no, runtime, runflag, cmd, arg) values('1','0 */10 * * * *','1','WFC:statistics_sms_verification_code_v1',''); 

]]
	-- �����û���Ȩ
	["user_auth_v1"] = handleUserAuth,  --�û���Ȩ https://host:port/wfc/sdk/v1/user_auth
	
	-- �����û���Ȩ --����1��ismp��Ȩ 2�����ŶԳ���Կ
	["user_auth_v2"] = handleUserAuth,  --�û���Ȩ https://host:port/wfc/sdk/v2/user_auth
	
	["register"] = ismp_register,
	-- ISMP��Ȩ
	["ismp_auth"] = handleUserIsmpAuth,
	
	-- �����û�ע��
	["datavoice_user_insert_v1"] = handleUserRegister, -- ���������û�ע�� http://host:port/datavoice/v1/user_insert
	["satcomm_user_insert_v1"] = handleUserRegister,   -- ���ǿ���û�ע��  http://host:port/satcomm/v1/user_insert
	
	-- �����û�����
	["datavoice_user_delete_v1"] = handleUserLogout, -- ���������û�����  http://host:port/datavoice/v1/user_delete
	["satcomm_user_delete_v1"] = handleUserLogout,   -- ���ǿ���û����� http://host:port/satcomm/v1/user_delete
	
	-- �����û�����״̬��ѯ
	["datavoice_user_select_v1"] = handleUserSelect,  -- ���������û�����״̬��ѯ  http://host:port/datavoice/v1/user_select
	["satcomm_user_select_v1"] = handleUserSelect,  -- ���ǿ���û�����״̬��ѯ  http://host:port/satcomm/v1/user_select
	
	--���͸澯��Ϣ
	["alarminfo_v1"] = handleAlarmInfo, --���͸澯��Ϣ http://host:port/wifias/v1/alarminfo
	
	-- ��������ҵ�Ľ��������
	["user_callbarring_v1"] = handleUserCallBarring, --http://host:port/wfc/eopserver/v1/user_callbarring
	
	-- �������л��豸
	["user_switchequipment_v1"] = userSwitchEquipment, --https://host:port/wfc/eopserver/v1/user_switchequipment
	
	-- ͨ����Чʱ�䵽���ֹ����
	["calling_timeout_v1"] = callingTimeout,
	
	-- �����û�imsi
	["user_updateimsi_v1"] = userUpdateimsi,  --https://host:port/wfc/eopserver/v1/user_updateimsi
	
	--������֤��ѯ
	["check_aliauth_v1"] = checkaliauth    --https://host:port/datavoice/v1/check_aliauth
}
 
