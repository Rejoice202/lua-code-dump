
local function selectnum(argt)
--[[
判断monitorparty是否是单个号码
若不是，则拆分为单个号码
--]]
	if #argt.monitorparty == 1 then
        logf("单个号码")
    else
		logf(#argt.monitorparty.."个号码")
        for i, phonenumber in pairs(argt.monitorparty) do 
		logf("i = %s",i)
            if i == 1 then
				logf("不知道为什么还要再判断一次单个号码")
                monitorparty = "'" ..phonenumber .."'"
				logf("monitorparty = %s",monitorparty)
            else
                monitorparty = monitorparty .."," .."'"..phonenumber .."'"
				logf("monitorparty = %s",monitorparty)
            end 
        end
		logf("多号码处理完毕")
	end 
end
lib_cmdtable["monitorparty_v1"] = selectnum