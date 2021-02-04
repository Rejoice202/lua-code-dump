include "strex"
include "redis"
include "eopptb"
include "sdc"


local function sqlSelect (argt)
	
	if not argt.direction then
		argt.direction = "Both"
	end
	
	local DIRECTION = { ["MO"] = "0", ["MT"] = "1",["Both"] = "0,1",["both"] = "0,1"}
    local callparty = DIRECTION[argt.direction]
	
	logf("%s",_VERSION)	--Lua 5.2 2019/12/29 17:43:33.850456
	--setErrExit(false)	--出错不拦截，继续执行，仅对一次API调用生效
	local sql = "select phonenumber,callparty from notifysubtable where phonenumber = '8618811012222' and callparty in ("..callparty..")"
	logf("sql = %s",sql)
	local r, err = sdc.sqlSelect(sql)
	logf("r = %s",table2json(r))
	logf("r.RowNum = %s",r.RowNum)
	-- logf(type(err))
	-- logf("%s",err)
	logf(table2json(r.Result))
	-- logf(r.Result[1].domainName)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.author = r.Result[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

lib_cmdtable["sqlSelect_v1"] = sqlSelect	--curl -v -k http://127.0.0.1:6081/testserv/v1/sqlSelect -d '{"direction":"MO"}'
