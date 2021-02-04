local mt = {}
mt.__index = {key = "it is key"}
t = {}
setmetatable(t,mt)
print(t.key)
--通过rawget直接获取t中的key索引
print(rawget(t,"key"))
t.key = "value"
print(t.key)
print(rawget(t,"key"))