include "conf"
include "strex"
include "redis"
include "crypto"
include "eopptb"
include "sdc"


local function dbcache (argt)

	
	--logf(mytb.runoob_title)

	local runoob_tbl = TEST_DB_CACHE.runoob_tbl
	local runoob_id = 1
	local title = runoob_tbl.pk(runoob_id)
	logf(type(title))
	logf(table2json(title))
	logf("title = %s",title.runoob_title)
	--logf(runoob_tbl[1].runoob_id)
	--logf(runoob_tbl[1].runoob_title)
	--logf("author = %s",runoob_tbl[1].runoob_author)
	--logf(type(runoob_tbl))
	--ptb(runoob_tbl)
	--logf(table2json(runoob_tbl))
	--logf("****************************")
	
	--logf(title)
	
	
	--[[
	local location2domain = TEST_DB_CACHE.location2domain
	local r = location2domain.pk(25)
	if r then
		logf(type(r))
		logf(table2json(r))
		logf("读到了")
	else 
		logf("没读到!")
	end
	--logf("domainName = %s",location2domain.pk("10"))
	--]]
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	--response.author = runoob_tbl[1].runoob_author
	--response.domainName = location2domain[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

lib_cmdtable["dbcache_v1"] = dbcache
