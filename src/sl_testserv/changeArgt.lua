-- include "http"

local function changeArgt_v1(argt)

	logf("argt = %s",table2json(argt))
	local HttpBody = {
        actions = argt.actions,
        APIID = argt.APIID,
    }
	logf("before loop HttpBody = %s",table2json(HttpBody))
	
    for i, subActions in pairs(argt.actions) do 
        argt.actions[i].url = "abcd"
    end

	logf("after loop HttpBody = %s",table2json(HttpBody))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.HttpBody = HttpBody
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


lib_cmdtable["changeArgt_v1"] = changeArgt_v1	--curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/changeArgt -d '{"APIID":"00001","actions":"subsid1"}'
