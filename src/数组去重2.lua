SCPDOMAINS = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan"}
print("排序前")
for k,v in pairs(SCPDOMAINS) do
        print(k,v)
end


table.sort(SCPDOMAINS)
print("排序后")
for k,v in pairs(SCPDOMAINS) do
        print(k,v)
end





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

print("去重后")
for k,v in pairs(SCPDOMAINS) do
        print(k,v)
end