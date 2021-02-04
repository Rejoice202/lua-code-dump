local Begin = os.time() 
SCPDOMAINS = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan","jiangsu","jiangsu","jiangsu","jiangsu","shandong","shanghai","hunan","nanjing","beijing","zhejiang","hunan","shandong","shanghai","jiangsu"}


for i=1,10000000 do
	duplicateindex = {}
	for i,v in pairs (SCPDOMAINS) do 
			 duplicateindex[v] = 1
	end
end

local End = os.time() 

print(End-Begin)