require ("printtable")
--MSISDN和PublicIPv4; PrivateIPv4和PublicIPv4；IPv6；IMSI至少选一组。
tb = {
	MSISDN = "aaa",
	PublicIPv4 = "bbb",
	--PrivateIPv4 = "ccc",
	--IPv6 = "ddd",
	--IMSI = "IMSI",
	}
--ptb(tb)

function checkTable(tab)
	local str = "tb"
	for i,v in pairs (tab) do
		str = i.." "..str
	end
	print("str = "..str)
	local r = (string.match(str,"MSISDN") and string.match(str,"PublicIPv4")) or (string.match(str,"PrivateIPv4") and string.match(str,"PublicIPv4")) or (string.match(str,"IPv6")) or (string.match(str,"IMSI"))
	ptb(r)
	if not r then
		return false
	else
		return true
	end
end

local r = checkTable(tb)
if not r then
	print("没有")
else
	print("有")
end