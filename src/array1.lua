require"printtable"

SCPDOMAINS = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan","jiangsu","jiangsu","jiangsu","jiangsu","shandong","shanghai","hunan","nanjing","beijing","zhejiang","hunan","shandong","shanghai","jiangsu"}
table.sort(SCPDOMAINS)

local Begin = os.time() 

function DeleteDuplicate()
	for i = 1,#SCPDOMAINS-1 do 
		if SCPDOMAINS[i] == SCPDOMAINS[i+1] then
		table.remove(SCPDOMAINS,i)
		DeleteDuplicate()
		end
	end
end

for i = 1,100000000 do
DeleteDuplicate()
end

local End = os.time() 

print(End-Begin)

-- ptb(SCPDOMAINS)


--一千万4s
--一亿次46s
