--print("Start lua script")

package.path = package.path .. ";D:/Programming/Github/NES_Nets/lua/?.lua"
ga = require("galaga")

ifile = io.open("input")
io.input(ifile)
input = io.read("*all")
--print(input)
io.close(ifile)

emu.speedmode("turbo")
--math.randomseed(os.time())

-- Get through loading
for i=1,250 do 
    emu.frameadvance()
end

-- start game
joypad.set(1, {start = true})
emu.frameadvance()

i=0
while not ga.is_game_over() do
    left = (math.random() > 0.5)
    cont = {A=true, left=(left), right=(not left)}
    joypad.set(1, cont)
    i = i + 1
    emu.frameadvance()
end
print("i = " .. tostring(i))

--io.output(io.stdout)

io.write(ga.get_score())

--print("Script end")

emu.exit()