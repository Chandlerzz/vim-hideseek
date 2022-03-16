-- script.lua
-- string.match(str,".swp$")
-- exclude diary$ ,MERDTree, 

-- Receives a table, returns the sum of its components.
io.write("The table the script received has:\n");
x = 0
path = foo[1]
if(string.match(path,".swp$") == nil) then
  return "" 
end
path = string.gsub(path,".swp$","")
path = path:gsub("%%","/")
if(string.match(path,".diary$") ~= nil) then 
  return ""
end
if(string.match(path,"!$") ~= nil) then 
  return ""
end
if(string.match(path,"NERD_tree") ~= nil) then 
  return ""
end
if(string.match(path,"MERGE") ~= nil) then 
  return ""
end
io.write("Returning data back to C\n");
return path
