-- print(string.match("A126","^A%d+$"))

-- condition = "c1&&(c2||c3)"
-- condition = "apple==banana&&(bob==alice||eve==christ)"
-- () () (())
-- condition = "apple==banana&&(bob==alice||diary!=dairy)||eve==christ"
-- condition = "a=1&&b=2&&c=3"
condition = "a=1&&(b=2||c=3)||d=4&&e=5||(f=6&&(g=7||h=8||i=9)||j=10)"
--[[
condition = "C11&&C10||C12&&C13||C7"
C1 g=7
C2 h=8
C3 i=9
C4 C1|C2|C3
C5 f=6
C6 j=10
C7 C5&&C4||C6
C8 b=2
C9 c=3
C10 C8||C9
C11 a=1
C12 d=4
C13 e=5
--]]
-- condition = "a&&b||c&&d||e||f"

function saveBoolExpression(expression)
	-- 2.&&转&
	expression = string.gsub(expression, "&&", "&")
	-- 3.||转|
	expression = string.gsub(expression, "||", "|")
	-- 4.去掉所有空格
	expression = string.gsub(expression," ","")
	-- 5.前后补符号,用于匹配开头与结尾的括号
	expression = ":"..expression..";"
	
	local ctb = {}
	local entrance,count,ctb = abstractBoolExpression(expression,1,ctb)
	return entrance,ctb
end

function abstractBoolExpression(expression,count,ctb)
	-- 1.拆分到没有括号为止
	while string.find(expression,"(%S+)%((%S-)%)(%S+)") do
		local _,_,prefix,subExpression,suffix = string.find(expression,"(%S+)%((%S-)%)(%S+)")
		-- local pre,suf,subExpression = string.find(expression,"%((%S-)%)")
		-- local prefix,suffix = string.sub(expression,1,pre-1), string.sub(expression,suf+1,-1)
		expression,count,ctb = abstractBoolExpression(subExpression,count,ctb)
		expression = prefix..expression..suffix
		print("27,expression:",expression)
	end
	-- 添加结束标志位;
	expression = expression..";"
	print("31,expression:",expression)
	print(string.find(expression,"(%S+)%((%S-)%)(%S+)"))
	local abstract = ""

	-- 获取第一个条件
	local condition,index
	local p = 1	--字符位置
	abstract,count,p = fillConditionTable(expression,count,p,abstract,ctb)
	
	local c = charAt(expression,p)
	while c ~= ";" do
		if c == "&" or c == "|" then
			abstract = abstract..c
			abstract,count,p = fillConditionTable(expression,count,p+1,abstract,ctb)
		else
			p = p + 1
		end
		c = charAt(expression,p)
	end
	
	-- 子表达式写成新条件：C4 = C1&C2|C3
	index = "C"..count
	-- print("abstract,index,ctb[index]",abstract,index,ctb[index])
	ctb[index] = abstract
	count = count + 1
	
	return index,count,ctb
end

-- 获取下一个&或|前的条件，填充到解析bool表达式的table中
function fillConditionTable(expression,count,p,abstract,ctb)
	
	-- 找到最近的&或者|
	local _,p1,c1 = string.find(expression, "(%S-)&", p)
	local _,p2,c2 = string.find(expression, "(%S-)|", p)
	local condition,p = string.sub(expression,p,-1),string.len(expression)
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
	-- 去除表达式里添加的杂乱字符 :_;;
	print(condition,p)
	if charAt(condition,-1) == ";" then
		condition = string.sub(condition,1,-2)
	end
	if charAt(condition,-1) == ";" then
		condition = string.sub(condition,1,-2)
	end
	if charAt(condition,1) == ":" then
		condition = string.sub(condition,2,-1)
	end
	-- 已抽象过则直接填入，否则分配条件序号，并保存对应的条件
	if string.match(condition,"^C%d+$") then
		abstract = abstract..condition
		return abstract,count, p 
	else
		abstract = abstract.."C"..count
		local index = "C"..count
		ctb[index] = condition
		return abstract,count + 1, p 
	end
	
end

-- 模拟java charAt方法
function charAt(str, i)
	return string.sub(str,i,i)
end

local a,t = saveBoolExpression(condition)
print("-----------------------")
print(a)
for k,v in pairs(t) do
	print(k,v)
end