function ret()
	for i = 1, 10 do
		print(i)
		if i == 5 then
			print("enter if")
			return
			print("still in if")
		end
		print("still in loop")
	end
	print("still in function")
end

ret()