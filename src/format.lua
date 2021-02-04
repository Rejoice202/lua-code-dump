	
	
	local sqlcmd = string.format([[select appid, sepid, plat, %s from notifysubtable where phonenumber ='%s' and callparty ='%s' and subscriptionId ='%s' and %s !='0']],sqlevent, phonenumber, callparty, correlator, sqlevent)
			
	local sqlcmd = "select appid, sepid, plat, "..sqlevent.." from notifysubtable where phonenumber ='"..phonenumber.."' and callparty ='"..callparty.."' and subscriptionId ='"..correlator.."' and "..sqlevent.." !='0'"
	
	
	
	
	
	
	select appid, sepid, plat, initialcall from notifysubtable where phonenumber ='8618811011111' and callparty ='1' and subscriptionId ='5e35b9223d5b4cc295686a0ad41107a1' and initialcall !='0'
	select appid, sepid, plat, initialcall from notifysubtable where phonenumber ='8618811011111' and callparty ='1' and subscriptionId ='5e35b9223d5b4cc295686a0ad41107a1' and initialcall !='0'
	select appid, sepid, plat, initialcall from notifysubtable where phonenumber ='8618811011111' and callparty ='1' and subscriptionId ='5e35b9223d5b4cc295686a0ad41107a1' and initialcall !='0'