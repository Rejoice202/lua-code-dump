-- local str = values ('1','1'),('2','2'),('3','3')
local oneProvince ={
	{'1','2','id1','num1'},
	{'2','2','id2','num2'},
	{'3','2','id3','num3'},
	{'4','2','id4','num4'},
	}
 
	for i,v in pairs (oneProvince) do
		if i == 1 then 
			datapairs = "("..oneProvince[i][3]..","..oneProvince[i][4]..")"
		else 
			datapairs = datapairs..",("..oneProvince[i][3]..","..oneProvince[i][4]..")"
		end
	end


--一个栗子
		for i, phonenumber in pairs(argt.monitorparty) do 
            if i == 1 then 
                monitorparty = "'" ..phonenumber .."'"
            else
                monitorparty = monitorparty .."," .."'"..phonenumber .."'"
            end 
            BoolMonitorParty[phonenumber] = true 
        end
		selSql = "select phonenumber from notifysubtable where phonenumber in ("..monitorparty..")"
    