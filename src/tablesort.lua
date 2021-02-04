SCPDOMAINS = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan"}



	for i = 1,#SCPDOMAINS do 
		
		if SCPDOMAINS[i] == SCPDOMAINS[i+1] then
		print("duplicate",i)
		table.remove(SCPDOMAINS,i)
		--DeleteDuplicate()
		for k,v in pairs(SCPDOMAINS) do
			print(k,v)
		end
		print("-------------------------------")
		end
	end
--end

local endpos = 0
while (endpos<10)
do 
	if SCPDOMAINS[#SCPDOMAINS-endpos] == SCPDOMAINS[#SCPDOMAINS-endpos-1] then
			print("duplicate",#SCPDOMAINS)
			table.remove(SCPDOMAINS,#SCPDOMAINS)
	else endpos = endpos+1
	end
end
--DeleteDuplicate()
--]]
duplicateindex = {}
for i = 1,#SCPDOMAINS do 
		print("now i = ",i)
		if SCPDOMAINS[i] == SCPDOMAINS[i+1] then
		print("duplicate",i)
		table.insert(duplicateindex,i)
		end
	end
	print("duplicateindex are these")
for k,v in pairs(duplicateindex) do
        print(k,v)
end
for i,v in pairs(duplicateindex) do
	print(i,v)
	table.remove(SCPDOMAINS,v-i+1)
	for k,v in pairs(SCPDOMAINS) do
		print(k,v)
	end
	print("-------------------------------")
end
	--]]
print("去重后")
for k,v in pairs(SCPDOMAINS) do
        print(k,v)
end