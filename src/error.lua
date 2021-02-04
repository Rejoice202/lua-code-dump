local function add(a,b)
   print("***********")
   -- error("111",0)
   print("---------")
   -- error("111")
   print("test")
   return print(a,b)
end

local function errorHandle()
	print(debug.traceback())
end


if xpcall(add,errorHandle,10) then
print("ok")
else
print("bad")
end



-- curl -v -k -X 'POST' -H "Authorization:Basic ZW9wX29tczoyd3N4M2VkYw==" -H "Content-Type:application/json" http://10.1.62.56:7080/test