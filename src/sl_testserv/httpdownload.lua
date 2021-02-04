include "http"

local function filedownload(argt)

	local Url = "http://10.1.63.77:6080/testserv/v1/fileread/data.txt"
	local r = http.download("NEF_CLASSONE", Url, { }, {sepid=argt.sepid})
	logf("r = %s",table2json(r))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.stat = r
	--response.domainName = location2domain[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


lib_cmdtable["filedownload_v1"] = filedownload
