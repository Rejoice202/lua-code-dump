cmdtable={
	["v1_0_1"] = "fda",
	["v1_0_2"] = "fda",
	["v1_0_3"] = "fda",
	["v1_0_4"] = "fda",
}

certcmd = "5"
local function findstr(cmd)
	for i in pairs (cmdtable) do 
		--print("i = "..i)
		--print(cmd)
		version = "v1_0_"..cmd
		j = string.find(i,version)
		if j ~= nil then
			--print("match success")
			--print(cmd)
			--print(version)
			break
		end	
	end
	--print("type j = "..type(j))
	--print(j)
	if j == nil then
		--print("cmd = "..cmd)
		cmd = tonumber(cmd) - 1
		cmd = tostring(cmd)
		findstr(cmd)
	end
	return true, version
end

local ok, realcmd = findstr(certcmd)
--print(ok)
if not ok then
	print("cmd not exit")
else
	print("real cmd = "..realcmd)
	--print(realcmd)
end


--print("global?"..version)