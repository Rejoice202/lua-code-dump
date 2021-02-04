
function nextCondition(expression,p)
	-- 下一个&或|
	local _,p1,c1 = string.find(expression, "(%S-)&",p)
	local _,p2,c2 = string.find(expression, "(%S-)|",p)
	local condition,p = expression,string.len(expression)
	if p1 then
		condition = c1
		p = p1
	end
	if p2 then
		condition = c2
		p = p2
	end
	if p1 and p2 then
		condition = c1
		p = p1
		if p1>p2 then
			condition = c2
			p = p2
		end
	end
	return condition,p
end
expression = "a|b|c&d|e"
expression = "b|c&d|e"
expression = "c&d|e"
print(nextCondition(expression,p))