
-- 解析流程图，拆分成语句块
-- 解析一个button，若是API则生成核心代码，若是选择结构则生成ifelse模板
function parser(button)
	-- for i,v in pairs(argt) do
		-- infof("i=%s, v=%s",i,v)
		-- if i == argt.start.next then
			-- nextButton = argt[i]
		-- end
	-- end
	debugf("button = %s",table2json(button))
	local luaStr
	if button.type == "API" then
		luaStr = parseSequence(button)
		-- callApi(button)
	elseif button.type == "selector" then
		luaStr = parseSelector(button.processControl)
	end
		-- button = argt[button.next]
	
	return luaStr
	
end

-- 生成原子API语句块
function callApi(api)
	debugf("name = %s, version = %s",api.name, api.version)
	return "/"..api.version.."/"..api.name
end

-- 解析顺序结构，原子API直接生成核心代码，遇到end或if返回。
function parseSequence(button)
	local automApiSourceCode = callApi(button)
	button = argt[button.next]
	if button.type == "selector" or button.next == "end" then
		return automApiSourceCode
	else
		return parseSequence(button)
	end
end

-- 解析if条件和执行的语句，生成if语句块
function parseSelector(processControl, argt)

	

	-- local ifStr = "if " .. processControl[1].condition .. " then " .. processControl[1].execution
	-- debugf("ifStr = %s",ifStr)
	local ifStr = string.format("if %s then \n %s", processControl[1].condition, processControl[1].execution)
	debugf("ifStr = %s",ifStr)
	local defflag
	for i = 2,#processControl do
		if processControl[i].condition ~= "default" then
			-- ifStr = ifStr .. " elseif " .. processControl[i].condition .. "then " .. processControl[i].execution
			-- debugf("ifStr = %s",ifStr)
			local execution = parser(argt[processControl[i].execution])
			ifStr = string.format("%s \n elseif %s then \n %s", ifStr, processControl[i].condition, processControl[i].execution)
			debugf("ifStr = %s",ifStr)
		else
			defflag = i
		end
	end
	
	-- 补充default条件执行的语句块和end
	if defflag then
		ifStr = string.format("%s \n else %s \n end", ifStr, processControl[i].execution)
	else
		ifStr = string.format("%s \n else %s \n end", ifStr, "return")
	end

	debugf("ifStr = %s",ifStr)
	return ifStr
end

function Orchestration(argt)

	debugf("argt.start = %s",type(argt.start))
	debugf("argt.start = %s",table2json(argt.start))
	local nextButton = argt[argt.start.next]

	parser(nextButton)

	local response = {}
	response.apple = "banana"
	response.cat = "dog"
	-- response.HttpBody = HttpBody
	return sendAck({ Retn = "200", Desc = "OK"},response)
end

lib_cmdtable["POST /testserv/v1/Orchestration"] = Orchestration	

-- 纯顺序执行两个原子API
-- curl -v -k -X POST -H "Authorization:Basic ZW9wX29tczoyd3N4M2VkYw==" -H "Content-Type:application/json" http://10.1.62.56:7080/testserv/v1/Orchestration -d '{"start":{"next":"API1"},"API1":{"type":"API","name":"sendUSSD","version":"v2","next":"API2"},"API2":{"type":"API","name":"queryUSSD","version":"v1","next":"end"},"end":{"next":"NULL"}}'

-- API1执行完后按条件执行API2/API3
-- curl -v -k -X POST -H "Authorization:Basic ZW9wX29tczoyd3N4M2VkYw==" -H "Content-Type:application/json" http://10.1.62.56:7080/testserv/v1/Orchestration -d '{"start":{"next":"API1"},"API1":{"type":"API","name":"domainQurey","version":"v2","next":"if1"},"if1":{"type":"selector","processControl":[{"condition":"c1","execution":"API2"},{"condition":"c2","execution":"API3"}]},"API2":{"type":"API","name":"queryUSSD","version":"v1","next":"end"},"API3":{"type":"API","name":"sendUSSD","version":"v1","next":"end"},"end":{"next":"NULL"}}'