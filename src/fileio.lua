PATH = "/home/tangcz/test/"

-- 以只读方式打开文件
local file = io.open("test.txt", "r")
file:flush()
file:seek("set",10)
print(file:read("*a"))

-- 关闭打开的文件
print(file:close())