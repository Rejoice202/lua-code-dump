local awakeCondition = {}
--[[
awakeCondition.C1 = "body.callevent.calling==8613900000001"
awakeCondition.C3 = "C1|C2"
awakeCondition.C2 = "body.callevent.called==8613900000001"
awakeCondition.C5 = "C4&C3"
awakeCondition.C4 = "body.callevent.event==Begin"
awakeCondition.main = "C5"
--]]
--[[
awakeCondition.C1 = "a==a"
awakeCondition.C3 = "C1|C2"
awakeCondition.C2 = "a==b"
awakeCondition.C5 = "C4&C3"
awakeCondition.C4 = "c==c"
awakeCondition.main = "C5"
--]]
a='1'
b='2'
c='3'
d='4'
e='5'
f='6'
g='7'
h='8'
i='9'
j='10'

-- condition = "a=1&&(b=2||c=3)||d=4&&e=5||(f=6&&(g=7||h=8||i=9)||j=10)"
awakeCondition.C1 = "g==g"
awakeCondition.C2 = "h==h"
awakeCondition.C3 = "i==i"
awakeCondition.C4 = "C1|C2|C3"
awakeCondition.C5 = "f==a"
awakeCondition.C6 = "j==a"
awakeCondition.C7 = "C5&C4|C6"
awakeCondition.C8 = "b==a"
awakeCondition.C9 = "c==a"
awakeCondition.C10 = "C8|C9"
awakeCondition.C11 = "a==a"
awakeCondition.C12 = "d==a"
awakeCondition.C13 = "e==e"
awakeCondition.C14 = "C11&C10|C12&C13|C7"
awakeCondition.main = "C14"

function parseBoolean(expression,awakeCondition)
	
	local result
	-- 有=一定是实际表达式matchAwakeCondition
	if string.find(expression, "=") then
		result = computeBoolean(expression)
	else
		-- 取出第一个条件，第一个运算符
		local condition,operator,position = getOneCondition(expression,1)
		result = parseBoolean(awakeCondition[condition],awakeCondition)
		local op = operator
		while op do
			-- 取出下一个条件
			condition,operator,position = getOneCondition(expression,position+1)
			print("condition",condition)
			local nextResult = parseBoolean(awakeCondition[condition],awakeCondition)
			if op == "&" then
				result = result and nextResult
			elseif op == "|" then
				result = result or nextResult
			end
			op = operator
			-- TODO:真不计算或，假不计算与
			print("result,op",result,op)
		end
	end
	print(string.format("result of %s is %s",expression,tostring(result)))
	return result
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

-- 计算基本表达式
function computeBoolean(awakeCondition)
	local _,_,leftV,rightV = string.find(awakeCondition, "(%S+)==(%S+)")
	print("leftV,rightV",leftV,rightV)
	if tostring(leftV) == rightV then
		return true
	else
		return false
	end
end

-- print(getExp3Tuple("C1|C2&C3|C4&C5|C6"))
print(parseBoolean(awakeCondition.main,awakeCondition))



