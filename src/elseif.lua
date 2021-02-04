
print(six)
local function judgeABC(a,b,c)
	if(a==1) then
	print("a=1")
		if(b==2)then
		print("b=2")
			if(c==3)then
			print("c=3")
			t={}
			t.a=a
			t.b=b
			t.c=c
			end
		end
	end
	return true,t
end

local function judgesix()
	local ok,r=judgeABC(1,2,3)
	if ok then
	print(type(ok))
	print(type(r))
		for i,v in pairs(r) do 
		print(i..v)
		end
	end
	return "666","okay"
end


local real,ok=judgesix()
print(string.format("real=%d",tonumber(real)))
print(string.format("state="..ok))










