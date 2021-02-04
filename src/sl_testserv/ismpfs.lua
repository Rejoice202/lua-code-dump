include "fs"
include "strex"

PATH = "/home/tangcz/numdata/"

local function fsstat(argt)
	local path = PATH.."exist.lua"
	local r = fs.stat(path)
	logf("r = %s",table2json(r))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.stat = r
	--response.domainName = location2domain[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


local function fsls(argt)
	local path = PATH
	local r = fs.ls(path)
	logf("r = %s",table2json(r))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.stat = r
	--response.domainName = location2domain[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end


local function fileread(argt)
	-- logf("argt = %s",table2json(argt))
	local fileurl = argt.HttpHeader.Url
	local filename = strex.str2Tab(fileurl,"/")
	local filename = filename[#filename]
	logf("filename = %s",filename)
	local path = "/home/tangcz/test/"
	local filePath = path..filename or path.."data2.txt"
    local file  = io.open(filePath,"r+")
	local r = file:read("*a")
	logf("file type = %s",type(r))
	logf("file r = %s",r)
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	response.stat = r
	--response.domainName = location2domain[1].domainName
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

lib_cmdtable["fsls_v1"] = fsls
lib_cmdtable["fsstat_v1"] = fsstat
lib_cmdtable["fileread_v1"] = fileread
