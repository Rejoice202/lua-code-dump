require"printtable"

local n = 7

function sigma(n)
	local s = 0
	if n == 0 then
		return s
	end
	for i = 1,n do
		s = s+i
	end
	return s
end

local P = {}
P[1] = 1

for i = 1,n do
	P[i] = sigma(i-1)+1
end

ptb(P)