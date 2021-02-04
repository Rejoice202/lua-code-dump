local body = {}
body.callevent = {}
body.callevent.event = "Begin"

local result = {}
result.callevent = {}
result.callevent.event = "Answer"

-- local contition = "body.callevent.event==Begin"

-- local contition = "body.callevent.event"
local contition = "response.callevent.event"

function parseJSON(expression,compositeApiRequestBody,callApiResult)
	local value
	local _,position,from,parameter = string.find(expression,"(%S-)%.(%S+)")
	print("parameter",parameter)
	local param,operator,position = getOneCondition(parameter,1)
	if from == "body" then
		value = compositeApiRequestBody[param]
	elseif from == "response" then
		value = callApiResult[param]
	end
	while operator do
		-- 取出下一个参数
		param,operator,position = getOneCondition(parameter,position+1)
		print("param",param)
		value = value[param]
	end
	return value
end


-- 功能：取出第一个表达式，第一个运算符
-- 参数：完整表达式，起始位置
-- 输出：第一个表达式，第一个运算符
function getOneCondition(expression, initial)
	print("expression, initial",expression, initial)
	if string.find(expression,"(%S-)(%p)",initial) then
		local _,position,condition,operator = string.find(expression,"(%S-)(%p)",initial)
		print("condition,operator,position",condition,operator,position)
		return condition,operator,position
	elseif string.find(expression,"(%S-)(%p)") then
		return string.reverse(getOneCondition(string.reverse(expression), 1))
	else
		return expression
	end
end

print(parseJSON(contition,body,result))
