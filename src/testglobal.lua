function QoS()
	ASYNCHRONOUS = true
	local Url = "http://"
	if ASYNCHRONOUS then 
		Url = "http://" .. "SCEFAACHost"
	end
	print("inside, Url = "..Url)
end

print(Url)

QoS()

print(Url)

function notQoS()
	print("othet function")
	print(Url)
end

notQoS()