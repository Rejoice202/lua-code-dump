VERSION = "1.0.0"
-- 自定义文件
-- include "redis_test"
-- include "global_test"
-- include "loadfromdb_v1"
-- include "sqlSelect_v1"
-- include "num2locationid"
-- include "monitorparty"
-- include "check"
-- include "return"
-- include "distance"
-- include "ismpfs"
-- include "httpdownload"
-- include "numdata"
-- include "numdata_1_2_0"
-- include "ansi_numdata_2_0_0"
-- include "ansi_numdata_2_0_1"
-- include "numdata_3_0_0"
-- include "genMonitorparty"
-- include "getRandom"
-- include "delNumtabmobInRedis"
-- include "tps"
-- include "checkPattern"

include "parser"

-- lib文件
include "eoputil"



SERVICE_ID = 0


-- AACHOST_LIST = {"zhejiang.aac.eop.ebupt","guangdong.aac.eop.ebupt"}
-- sadd AACHOST_LIST zhejiang.aac.eop.ebupt guangdong.aac.eop.ebupt
-- sadd AACHOST_LIST zhejiang.aac.eop.ebupt

-- sadd AACHOST_LIST 16.aac.eop.ebupt 18.aac.eop.ebupt
-- sadd AACHOST_LIST 16.aac.eop.ebupt

TEST_DB_CACHE={}

function _slinit()
	-- TEST_DB_CACHE.runoob_tbl = conf.loadFromDB({"runoob_id"},"select runoob_id,runoob_title,runoob_author from runoob_tbl ")
	--区号到各省SMP/SCPAS自定义域名的映射关系不大，也几乎不会改变（预置），所以可以缓存到内存中
	-- TEST_DB_CACHE.location2domain = conf.loadFromDB({"location"},"select location,domainName from location2domain ")
	
	-- setErrExit(false)
	-- logf("AACHOST_LIST address = %s",AACHOST_LIST)
	-- for i,v in pairs(AACHOST_LIST) do
		-- local r = redis.exec({"SADD", "AACHOST_LIST", AACHOST_LIST[i]})
	-- redis.exec("SADD AACHOST_LIST %s", AACHOST_LIST[1])
	-- redis.exec("SADD AACHOST_LIST %s", AACHOST_LIST[2])
		-- logf(table2json(r))
	-- end

	
end

--include "OnePartyCall_statusnotify_v1"
