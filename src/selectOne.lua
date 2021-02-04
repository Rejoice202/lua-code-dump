require"math"

function selectOne(array)
	local count1 = 0
	local count2 = 0
	if #array ~= 2 then
		print("len = %s",#array)
		return nil
	end
	-- math.randomseed(os.time())
	-- local random1 = math.random(1,100)
	-- print(random1)
	-- print(math.mod(random1,2))
	for i = 1,10 do
		math.randomseed(os.time())
		local random1 = math.random(1,100)
		os.execute("sleep " .. 1)
		if math.mod(random1,2) == 1 then
			count1 = count1 + 1
			-- return array[1]
		else
			count2 = count2 + 1
			-- return array[2]
		end
	end
	print("count1 = "..count1)
	print("count2 = "..count2)
end

-- local r = selectOne({"aac1","aac2"})
-- print(r)

selectOne({"aac1","aac2"})