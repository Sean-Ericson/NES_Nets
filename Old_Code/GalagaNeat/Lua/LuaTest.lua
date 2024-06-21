file1 = io.open("test.txt", 'w')
num = 3
file1:write(num..'\n')
file1:write("A"..'\n')

num = 420
file1:write(num..'\n')
file1:write("B"..'\n')

num = 69
file1:write(num..'\n')
file1:write("C"..'\n')

num =666
file1:write(num..'\n')
file1:close()

file2 = io.open("test.txt", 'r')

tablet = {}
for i = 1, tonumber(file2:read("*line")) do
	tablet[file2:read("*line")] = tonumber(file2:read("*line"))
end

for name, val in pairs(tablet) do
	print(name..": "..val)
end

file2:close()