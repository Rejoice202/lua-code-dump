require"printtable"

function clone(object)
	local lookup_table = {}
	print("clone")
	-- print(lookup_table)
	-- ptb(lookup_table)
	local function _copy(object)
		print("_copy")
		-- print(lookup_table)
		-- ptb(lookup_table)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local newObject = {}
		lookup_table[object] = newObject
		for key, value in pairs(object) do
			newObject[_copy(key)] = _copy(value)
		end
		local mytb = setmetatable(newObject, getmetatable(object))
		print("mytb")
		ptb(mytb)
		return mytb
	end
	return _copy(object)
end





local t1 = {1}
local t2 = t1
local t3 = clone(t1)
print("*-*-*-*/-*/-/*-/*-/--*+*+-*+-*+")
print(t1)
ptb(t1)
print(t2)
ptb(t2)
print(t3)
ptb(t3)

