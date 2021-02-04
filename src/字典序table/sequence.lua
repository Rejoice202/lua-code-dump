-- 对key进行字典序排序
local keyTab = {}
for k, v in pairs(tab) do
table.insert(keyTab, k)
end
table.sort(keyTab)

-- 将排序后的key生成新的table
local tabStr = "{"
local sortTab = {}
for i, v in ipairs(keyTab) do
sortTab[v] = tab[v]
if tabStr ~= "{" then
  tabStr = tabStr .. ","
end
tabStr = tabStr .. "\"" .. v .. "\"" .. ":"
if type(tab[v]) == "number" then
  tabStr = tabStr .. tab[v]
else
  tabStr = tabStr .. "\"" .. tab[v] .. "\""
end
end
tabStr = tabStr .. "}"