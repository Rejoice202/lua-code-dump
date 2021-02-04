function charAt(str, i)
	return string.sub(str,i,i)
end

-- 功能：ret.param(左值)前后加上toString()
function dealLeftValue(expression)
	
	-- 添加结束标志位;
	expression = expression..";"
	
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
			-- ..( + "toString(" + ret1.param1 + ")" + ..
			-- ..&&/|| + "toString(" + ret1.param1 + ")" + ..
			-- ..! + "toString(" + ret1.param1 + ")" + ..
			expression = string.sub(expression,1,pos).."toString("..string.sub(expression,pos+1,r)..")"..string.sub(expression,r+1,-1)
			l = r + 12 + pos-l-1	-- 12 = string.len("==") + string.len("toString()")
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
		-- "toString(" + ret1.param1 + ")" + ..
		expression = "toString("..string.sub(expression,1,r)..")"..string.sub(expression,r+1,-1)
	end
	
	return expression
end

-- 功能：右值加引号
function dealRightValue(expression)
	
	-- ==/~=右边，到第一个右值终止字符 &|!); 为右值
	local l = 1	--左指针
	local r		--右指针
	local pos	--左值起始位置
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
	
	-- 删除结束标志位;
	expression = string.sub(expression,1,-2)
	
	return expression
	
end

local expression1 = "(api1.p1==666)&&api2.p2==777"
local expression2 = "api1.p1==666&&(api2.p2==777||api3.p3==888)"
local expression3 = "(api1.p1==666&&(api2.p2==777||api3.p3==888))||!api4.p4==999&&!(api5.p5==111)||api6.p6~=222"
local expression4 = "(api1.p1~=666&&(api2.p2==777||api3.p3==888))||!(api4.p4==999&&!api5.p5==111)||api6.p6~=222"

function dealValue(expression)
	expression = dealLeftValue(expression)
	print("dealLeftValue:"..expression)
	expression = dealRightValue(expression)
	print("dealRightValue:"..expression)
	expression = dealOperator(expression)
	print("dealOperator:"..expression)
	return expression
end

local expression = expression4
print(expression)
-- print(dealValue(expression))
dealValue(expression)
