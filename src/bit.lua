luabit = require"math"
--require"base"
print(luabit.huge)
print("----------------------------------")
local function printtable(res)
        for k,v in pairs(res) do
                if type(v) == "table" then
						print("A Table")
                        print(k..": ")
                        for x, y in pairs(v) do
                                print(x..": "..y)
                        end
                else
						print("not table "..type(v))
                        print(k..": "..tostring(v))
                end
        end
end

printtable(luabit)