local Begin = os.time() 
SCPDOMAINS = {"hunan","beijing","nanjing","hunan","beijing","zhejiang","beijing","nanjing","zhejiang","beijing","hunan","jiangsu","jiangsu","jiangsu","jiangsu","shandong","shanghai","hunan","nanjing","beijing","zhejiang","hunan","shandong","shanghai","jiangsu"}

for i= 1,10000000 do
	table.sort(SCPDOMAINS)
end
local End = os.time() 

print(End-Begin)