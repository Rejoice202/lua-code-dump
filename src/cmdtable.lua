cmdtable= {
["Alice"] = "operate alice",
["Brittney"] = "operate brittney",
["Cindy"] = "operate cindy"
}


for i,v in pairs(cmdtable) do
print(i,v)
end

print(os.time())