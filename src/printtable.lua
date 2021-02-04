function ptb(atable)
	--print("------TABLE:"..atable.."------") 
	print("------"..string.upper(type(atable)).."------") 
	if 	(type(atable)) == "table" then
        for i,v in pairs (atable) do
			--print(type(v))
			if type(v) ~= "table" and type(v) ~= "function" then
				print('"'..i..'" : '..'"'..v..'"')
			else
				print("i = "..i..", v is "..type(v))
			end
        end 
	elseif (type(atable)) == "function" then
		for i in atable do 
			print(i)
		end
	elseif (type(atable)) == "string" then
		print("argt = "..atable)
	end
	
end
