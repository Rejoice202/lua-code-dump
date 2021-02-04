
--功能：通过realip或自定义域名，读取capplat_info表中的鉴权信息
--参数：二选一realip|自定义域名>携带Authorization和content-type的消息头
--备注：目前仅发往南向能力网元使用此函数获取消息头，发往北向的消息头使用kong的gateway-callhttp.json配置
--Developed：重复性太高，可从代码层面优化,目前想到的优化方式是：只接收一个参数，函数判断出是域名还是ip，然后选择不同的方式
--Developed：需求为host实际上是ip:port，而表中只有ip，需要去除:port，不过好消息是目前ip一定是ipv4
--Updated：相比V1.0.0,此版本只接收一个参数，自动判断是包含":"的ip:port还是不含的自定义域名，然后通过不同主键获取鉴权信息
function getHttpHeader(address)
	local colon = string.find(address,":")
	logf("address  = %s",address)
	if not colon then --没有冒号表示传入的是自定义域名
	local DN2authinfo = CMCCEOP_DB_CACHE.capplat_info_DN2authinfo
		local authinfo = DN2authinfo.pk(address)
		local authname = authinfo.authname
		local authsecret = authinfo.authsecret
		local httpheader = {
			["Authorization"] = "Basic " .. base64Encode(authname .. ":" .. authsecret),
			["content-type"]="application/json"
		} 
		return httpheader
	elseif colon then	--有冒号表示传入的是ip:port
		local ip = string.sub(host,1,colon-1)
		local host2authinfo = CMCCEOP_DB_CACHE.capplat_info_host2authinfo
		local authinfo = host2authinfo.pk(ip)
		local authname = authinfo.authname
		local authsecret = authinfo.authsecret
		local httpheader = {
			["Authorization"] = "Basic " .. base64Encode(authname .. ":" .. authsecret),
			["content-type"]="application/json"
		} 
		return httpheader
	end
end
