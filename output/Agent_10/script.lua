print("Start lua script")

ifile = io.open("input")
io.input(ifile)
input = io.read("*all")
print(input)
io.close(ifile)

EXTRA_LIVES_BYTE = 0x0487
MYSTERY_BYTE = 0x0471

function read_score()
    first_adress = 224
    n = 7 --number of digits

    score = 0
    for i = n-1,0,-1 do 
        digit = memory.readbyte(first_adress+(6 - i))
        score = score + digit * math.pow(10, i)
    end
    return score
end

function game_over()
	local lifeByte = memory.readbyte(EXTRA_LIVES_BYTE)
	local shipByte = memory.readbyte(MYSTERY_BYTE)
	return (lifeByte == 0) and ((shipByte == 0) or (shipByte == 0xF0))
end

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
while not game_over() do
    left = (math.random() > 0.5)
    cont = {A=true, left=(left), right=(not left)}
    joypad.set(1, cont)
    i = i + 1
    emu.frameadvance()
end
print("i = " .. tostring(i))

io.output(io.stdout)
io.write(read_score())

print("Script end")

emu.exit()