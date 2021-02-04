-- 研究return在函数、for循环、ifelse里的退出机制
function ret_v1()
	for i = 1, 10 do
		logf(i)
		if i == 5 then
			logf("enter if")
			return
			logf("still in if")
		end
		logf("still in loop")
	end
	logf("still in function")
end

function ret_v2()
	
	local tb1 = {}
	tb1.mem1 = "a"
	
	no = ret_v3(tb1,tb1)
	
	logf("no = %s",no)
	
	logf("type tb1 = %s",type(tb1))
	logf("tb1 = %s",table2json(tb1))
	
	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.HttpBody = HttpBody
	return sendAck({ Retn = "300", Desc = "O23K"},response)

	
end

function ret_v3(tb1,tb2)

	logf("tb1 = %s",table2json(tb1))
	logf("tb2 = %s",table2json(tb2))
	tb1.mem1 = "b"
	
	logf("after tb1 = %s",table2json(tb1))
	logf("after tb2 = %s",table2json(tb2))


end

lib_cmdtable["ret_v1"] = ret_v1
--curl -v -k -X POST http://127.0.0.1:6081/testserv/v1/ret

lib_cmdtable["ret_v2"] = ret_v2
--curl -v -k -X POST http://127.0.0.1:6081/testserv/v2/ret
