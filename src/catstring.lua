local Begin = os.time()
local str = "hello world"

for i = 1,100000000 do
	--local res = string.format("%s%s",str,str)
	local res = str..str
end

local End = os.time()
print(Begin)
print(End)
print(End-Begin)