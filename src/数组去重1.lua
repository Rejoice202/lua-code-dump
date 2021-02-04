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

function DeleteDuplicate()
	for i = 1,#SCPDOMAINS do 
		if SCPDOMAINS[i] == SCPDOMAINS[i+1] then
			table.remove(SCPDOMAINS,i)
			DeleteDuplicate()
		end
	end
end

DeleteDuplicate()
print("去重后")
for k,v in pairs(SCPDOMAINS) do
        print(k,v)
end