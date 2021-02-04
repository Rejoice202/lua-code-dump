numtable={
	[1] = 'haha',
	[2] = 'haha',
	[3] = 'haha',
	[4] = 'haha',
	[5] = 'haha',
	[6] = 'haha',
	[7] = 'haha',
}
--[[
i = table.maxn(numtable)
print("i="..i)
	print("type i ="..type(i))
--]]

function printtb(tb)
	for i,v in pairs (tb) do 
	print("i="..i.." v= "..v)
	print("type i ="..type(i))
	print("type v ="..type(v))
	end
end
--printtb(numtable)


function findcmd(cmd)
	i = table.maxn(numtable)
		if cmd == i then
		--找到了就返回
			print("match")
			return cmd
		else
		--没找到就降为v1_0_2继续找
			cmd = tonumber(cmd) -1
			--cmd  = tostring(cmd)
			print("not tostring type cmd ="..type(cmd))
			print("cmd = "..cmd)
		return findcmd(cmd)
		end
	
end

local cmd = "9"
i = findcmd(cmd)
print("type cmd ="..type(i))
print("cmd = "..i)
--]]