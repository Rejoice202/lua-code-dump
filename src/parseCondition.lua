-- expression = "api0.obj1.apple==banana&&api0.obj1.atom!=molecule"
expression = "api0.obj1.apple==banana&&api0.obj1.atom!=api1.obj1.atom"

-- 功能：翻译条件表达式
-- 参数：C-like bool expression
-- 输出：符合lua语法的表达式
function parseCondition(expression)
	
	-- 1.表达式合法性校验
	local r,e = judgeExpression(expression)
	if not r then
		local Response = {}
		Response.code = "1003"
		Response.desc = AEFCODE[Response.code]..":"..e
		sendAck({Retn = "400", Desc = HTTPCODE["400"]}, Response)
		exitCmd()
		return
	end
	
	-- 2.!=转~=
	expression = string.gsub(expression, "!=", "~=")
	
	-- 3.去掉所有空格
	expression = string.gsub(expression," ","")
	
	-- 添加结束标志位;
	expression = expression..";"

	-- 4.处理左值：ret.param转字符串
	expression = dealLeftValue(expression)
	-- 5.处理右值：value加引号/api.in.value
	expression = dealRightValue(expression)
	-- 6.关系运算符加空格并翻译成eng
	expression = dealOperator(expression)
	
	-- 删除结束标志位;
	expression = string.sub(expression,1,-2)
	
	return expression
end


-- 功能：表达式合法性校验
function judgeExpression(expression)
	
	-- 1.括号合法性校验:左右括号数量相同，且左括号先出现
	local count = 0
	for i = 1, string.len(expression) do
		-- 找到一个左括号，计数器加一
		if charAt(expression,i) == "(" then
			count = count + 1
		-- 找到一个右括号，计数器减一
		elseif charAt(expression,i) == ")" then
			count = count - 1
		end
		-- debugf("judgeExpression.count = %s",count)
		-- 遍历过程中，左括号数量不能小于右括号，即count任意时刻大于等于0
		if count < 0 then
			debugf("Invalid Expression With Wrong Num of Brackets:%s",expression)
			return false, expression
		end
	end
	if count ~= 0 then
		debugf("Invalid Expression Num of Brackets not Match:%s",expression)
		return false, expression
	end

	--[[
	-- 3.只能有+-*
	-- 找到第一个数学运算符，%D表示匹配非数字字符
	local operatorPosition = string.find(expression, "%D")
	while operatorPosition do
		-- 把每个非数字字符跟+-*做比较
		local operator = string.sub(expression, operatorPosition, operatorPosition)
		-- debugf("operator = "..operator)
		if (operator ~= "+") and (operator ~= "-") and (operator ~= "*") and (operator ~= "(") and (operator ~= ")") then
			debugf("Invalid Expression:"..expression)
			return false
		end
		operatorPosition = string.find(expression, "%D", operatorPosition+1)
	end
	-- 4.+-*的左右只能是数字和()，除非是首位负号
	-- 5.右值不能带括号，'"[]这三种字符最多带两种，目前不确定会带哪种，故都不支持
	-- 呀咧呀咧，麻烦死了
	--]]
	return true
end

-- 功能：ret.param(左值)前后加上toString()
function dealLeftValue(expression)
	
	
	local l = 1	--左指针
	local r		--右指针
	local pos	--左值起始位置
	local c = charAt(expression,l)
	while c ~= ";" do
		-- 1.左括号"("右边，若不为!
		local condition1 = c == "(" and charAt(expression,l+1) ~= "!"
		-- 2.!右边，若不为(
		local condition2 = c == "!" and charAt(expression,l+1) ~= "("
		-- 3.&&/||右边，若不为(也不为!
		local condition3 = (c == "&" or c == "|") and charAt(expression,l+2) ~= "(" and charAt(expression,l+2) ~= "!"
		if condition1 or condition2 or condition3 then
			if c == "&" or c == "|" then
				pos = l+1
			else
				pos = l
			end
			r = string.find(expression,"=",pos)-1
			if charAt(expression,r) == "~" then
				r = r - 1
			end
			-- ..( + "tostring(" + ret1.param1 + ")" + ..
			-- ..&&/|| + "tostring(" + ret1.param1 + ")" + ..
			-- ..! + "tostring(" + ret1.param1 + ")" + ..
			expression = string.sub(expression,1,pos).."tostring(callApiResult."..string.sub(expression,pos+1,r)..")"..string.sub(expression,r+1,-1)
			l = r + 12 + pos-l-1	-- 12 = string.len("==") + string.len("tostring()")
		else
			l = l + 1
		end
		c = charAt(expression,l)
	end

	-- 4.首位字符若不为(,则第一个==/~=左边为左值
	if charAt(expression,1) ~= "(" then
		r = string.find(expression,"=",1)-1
		if charAt(expression,r) == "~" then
			r = r - 1
		end
		-- "tostring(" + ret1.param1 + ")" + ..
		expression = "tostring(callApiResult."..string.sub(expression,1,r)..")"..string.sub(expression,r+1,-1)
	end
	
	return expression
end

-- 功能：右值加引号
function dealRightValue(expression)
	
	-- ==/~=右边，到第一个右值终止字符 &|!); 为右值
	local l = 1	--左指针
	local r		--右指针
	local pos	--右值起始位置
	local c = charAt(expression,l)
	while c ~= ";" do
		-- ~=
		local condition1 = c == "~" and charAt(expression,l+1) == "="
		-- ==
		local condition2 = c == "=" and charAt(expression,l+1) == "="
		if condition1 or condition2 then
			pos = l+1
			--[[
			右值终止位置：
			1.&
			2.|
			3.!
			4.)
			5.最后一位;
			--]]
			r = nearestChar(expression, pos, {"&","|","!",")",";"})-1
			-- ..= + " + exp + " + ..
			print(string.sub(expression,pos+1,r))
			expression = string.sub(expression,1,pos)..'"'..string.sub(expression,pos+1,r)..'"'..string.sub(expression,r+1,-1)
			l = r + 3	-- 3 = string.len(右值终止字符) + string.len('""')
		else
			l = l + 1
		end
		c = charAt(expression,l)
	end

	return expression
end

-- 功能：最靠近的符号
-- 参数：表达式，起始位置，符号集合
-- 输出：位置
function nearestChar(expression, st, charArray)
	local pos
	for i = 1,#charArray do
		local temp = string.find(expression,charArray[i],st)
		if temp and not pos then
			pos = temp
		end
		if temp and pos then
			if temp < pos then
				pos = temp
			end
		end
	end
	return pos
end

-- 功能：翻译关系运算符
--[[
&& -> and
|| -> or
! -> not
--]]
function dealOperator(expression)
	
		-- ==/~=右边，到第一个右值终止字符 &|!); 为右值
	local l = 1	--左指针
	local r		--右指针
	local pos	--左值起始位置
	local c = charAt(expression,l)
	while c ~= ";" do
		-- &&
		local condition1 = c == "&" and charAt(expression,l+1) == "&"
		-- ||
		local condition2 = c == "|" and charAt(expression,l+1) == "|"
		-- !
		local condition3 = c == "!"
		if condition1 or condition2 or condition3 then
			local substitutedString
			if condition1 then
				substitutedString = " and "
				r = l + 2
			end
			if condition2 then
				substitutedString = " or "
				r = l + 2
			end
			if condition3 then
				substitutedString = " not "
				r = l + 1
			end
			pos = l - 1
			expression = string.sub(expression,1,pos)..substitutedString..string.sub(expression,r,-1)
			l = l + string.len(substitutedString)
		else
			l = l + 1
		end
		c = charAt(expression,l)
	end
	
	
	return expression
	
end
-- 模拟java charAt方法
function charAt(str, i)
	return string.sub(str,i,i)
end
print(parseCondition(expression))