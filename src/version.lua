function strsplit(str, pattern, num)
    local sub_str_tab = {}
    local i = 0
    local j = 0
    if num == nil then
        num = -1
    end

    while true do
        if num == 0 then
            table.insert(sub_str_tab, string.sub(str, i, -1))
            break
        end

        j = string.find(str, pattern, i+1)
        if j == nil then
            table.insert(sub_str_tab, string.sub(str, i, -1))
            break
        end
        table.insert(sub_str_tab, string.sub(str, i, j-1))
        i = j + 1
        num = num - 1
    end

    return sub_str_tab
end

local function userinfo()
end
local function userinfo_v1_0_3()
end
local function userinfo_v1_0_4()
end
local function userinfo_v1_0_5()
end
local function sms_verification_code_v1_0_4()
end
local function sms_verification_code_v1_0_5()
end

lib_cmdtable = {
	["user_info_v1_0_2"] = userinfo,
	["user_info_v1_0_3"] = userinfo_v1_0_3,
	["user_info_v1_0_4"] = userinfo_v1_0_4,
	["user_info_v1_0_5"] = userinfo_v1_0_5,
	["sms_verification_code_v1_0_4"] = sms_verification_code_v1_0_4,
	["sms_verification_code_v1_0_5"] = sms_verification_code_v1_0_5,
}

httpheader = {}
httpheader.url = "/wificalling_appserver/v1_0_7/sms_verification_code"


--urltab = strsplit(httpheader.url, "/") -- ,wificalling_appserver,v1_0_3,user_infodetails
--versiontab = strsplit(urltab[3], "_") --v1,0,3
--cmd = urltab[4].."_"..urltab[3] --v1_0_3/user_infodetails
--print("cmd = "..cmd)
function printtb(tb)
	for i,v in pairs (tb) do 
	print("i="..i.." v= "..v)
	print("type i ="..type(i))
	print("type v ="..type(v))
	end
end
local function findcmd(cmd, interface)
	--print("cmd="..cmd.."    line 66")
	--print(interface)
	local version = interface.."_v1_0_"..cmd
	for i in pairs (lib_cmdtable) do 
		--print("i = "..i)
		--print(cmd)
		j = string.find(i,version)
		if j ~= nil then
			print("match success")
			--print(cmd)
			--print(version)
			break
		end	
	end
	--print("type j = "..type(j))
	--print(j)
	if j == nil then
		print("cmd = "..cmd)
		local cmd = tonumber(cmd) - 1
		local cmd = tostring(cmd)
		findcmd(cmd, interface)
	end
	return true, version
end

--printtb(versiontab)
--[[
function versionctrl()
	for i in pairs (lib_cmdtable) do 
		print("i="..i)
		
		if cmd == i then
			print("matched")
			return cmd
		else 
			print("not match")
			return findcmd(cmd)
		end
		
	end
end
versionctrl()
--]]

function getversion(url)

	local urltab = strsplit(url, "/") -- ,wificalling_appserver,v1_0_3,user_infodetails
	local versiontab = strsplit(urltab[3], "_") --v1,0,3
	--versiontab[3] = tonumber(versiontab[3])-1
	local ver = versiontab[1].."_"..versiontab[2].."_"..tostring(versiontab[3])
	print("getversion: "..ver.."  "..urltab[4].."  "..tostring(versiontab[3]))
	return ver, urltab[4], tostring(versiontab[3])
end

local version, interface, certcmd = getversion(httpheader.url)
local ok, realcmd = findcmd(certcmd, interface)
local completeCMD = "/wificalling_appserver/"..realcmd.."/"..interface
if not ok then
	print("cmd not exit")
else
	print("real cmd = "..completeCMD)
	--print(realcmd)
end
--print(realCmdAddInter)
--[[
function findcmd(cmd, url)
	for i in pairs(lib_cmdtable) do 
		--print("i="..i)
		if cmd == i then
		--找到了就返回
			return cmd
		else 
		--没找到就降为v1_0_2继续找
			local ver, interface = getversion(httpheader.url)
			cmd = ver.."/"..interface
		return findcmd(cmd)
		end
	end
end
--]]
--[[
i = findcmd(cmd, httpheader.url)
print("tpye cmd ="..type(i))
print("cmd = "..i)
--]]