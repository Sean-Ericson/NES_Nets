--Custom error-logging function
function LogError(errorString)
	emu.pause()
	emu.print("Error: "..errorString)
end

--Function for calculating N!/D!
function factorialQuotient(n, d)
	local smaller = math.min(n, d)
	local bigger = math.max(n, d)
	
	local prod = 1
	for i = (smaller + 1), bigger do
		prod = prod * i
	end
	
	if n > d then
		return prod
	end
	
	return 1 / prod
end

--Table shuffling
-->>https://stackoverflow.com/questions/17119804/lua-array-shuffle-not-working
function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end
function shuffleTable(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        swap(array, index, counter)
        counter = counter - 1
    end
end

--Neuron activation function
function sigmoid(x)
	return 2/(1+math.exp(-4.9*x))-1 --steepened sigmoid w/ image (-1, 1)
end

--Custom table iterator (goes through by index, got this from https://www.lua.org/pil/19.3.html)
function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

--Custom len() function for tables becuause apparently #table if fucking retarded
-->Shamelessly stolen from https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--******************************
--This section is the code to apply the network evolution to Galaga
--These functions and defaults assume galaga is currently playing in the emulator
--when you start this script.
--******************************

--***
--Galaga constants
--***
--General Consts
NO_SPRITE = 0x80
OFF_SCREEN = 0xFF
PLAYER_POS = 0x0203
EXTRA_LIVES_BYTE = 0x0487
MYSTERY_BYTE = 0x0471
--Attack sprite constants
FIRST_SPRITE_BYTE = 0x0220
LAST_SPRITE_BYTE  = 0x02D0
SPRITE_STEP = 0x10
X_POS_OFFSET = 0x3
Y_POS_OFFSET = 0x2
--Enemy Bullet sprite constants
FIRST_BULLET_BYTE = 0x0090
LAST_BULLET_BYTE = 0x00AC
BULLET_STEP = 0x4
BULLET_X_OFFSET = 0x2
BULLET_Y_OFFSET = 0x1
--Player bullet sprite constants
FIRST_PLAYER_BULLET_BYTE = 0x02E0
LAST_PLAYER_BULLET_BYTE = 0x02E8
PLAYER_BULLET_STEP = 0x8
--Score
SCORE_FIRST_BYTE = 0x00E0
SCORE_LAST_BYTE = 0x00E6
--Shots Fired
SHOTS_FIRST_BYTE = 0x04A0
SHOTS_LAST_BYTE = 0x04A7
--Enemies Hit
ENEMIES_HIT_FIRST_BYTE = 0x04A8
ENEMIES_HIT_LAST_BYTE = 0x04AF
--Position constants
PLAYER_MIN_POS = 8 --decimal
PLAYER_MAX_POS = 183 --decimal
SCREEN_MIN_Y = 0 --decimal
SCREEN_MAX_Y = 230 --decimal
SCREEN_MIN_X = 0
SCREEN_MAX_X = 200 -- decimal
--Enemy Formation Constants
ROW_1_FIRST_BYTE = 0x0403
ROW_1_LAST_BYTE =  0x0406
ROW_2_FIRST_BYTE = 0x0411
ROW_2_LAST_BYTE =  0x0418
ROW_3_FIRST_BYTE = 0x0421
ROW_3_LAST_BYTE =  0x0428
ROW_4_FIRST_BYTE = 0x0430
ROW_4_LAST_BYTE =  0x0439
ROW_5_FIRST_BYTE = 0x0440
ROW_5_LAST_BYTE =  0x0449
--Input constants
GRID_X = 19
GRID_y = 23

ButtonNames = 
{
	"A",
	"B",
	"up",
	"down",
	"left",
	"right",
	"start",
	"select"
}
--***
--/Galaga constants
--***


--***
--Galaga "Game Active" function
--***
function isGameActive()
	local lifeByte = memory.readbyte(EXTRA_LIVES_BYTE)
	local shipByte = memory.readbyte(MYSTERY_BYTE)
	local gameOver = (lifeByte == 0) and ((shipByte == 0) or (shipByte == 0xF0))
	return not gameOver
end
--***
--/Active Function
--***


--***
--Galaga "Fitness" function
-->>returns score * accuracy
--***
function scoreTimesAccuracy()
	return getScore() * getHitMissRatio()
end
--***
--/Fitness function
--***


--***
--Input Function
-->>Ratio: (1)[0, 1] player pos, (2-21)[0, 1] attack sprite x-y, 
-->>       (22-37)[0, 1] enemy bullet x-y, (38-41)[0,1] player bullet x-y 
-->>	   (42-81) [-1 or 1] formation info: 1 if enemy in formation
-->>		all neurons -1 if no info
--***
function galagaInputRatio()
	local input = {}
	
	--set all to -1
	for i = 1, 81 do
		input[i] = -1
	end
	
	--get player pos ration
	local playerRange = PLAYER_MAX_POS - PLAYER_MIN_POS
	input[1] = (getPlayerPos() - PLAYER_MIN_POS) / playerRange
	
	--get attack sprite ratios
	local sprites = getAttackSprites()
	for index, sprite in pairsByKeys(sprites) do
		local neuron = 2 * index
		input[neuron] = sprite["x"] / SCREEN_MAX_X
		input[neuron + 1] = sprite["y"] / SCREEN_MAX_Y
	end
	
	--get enemy bullet ratios
	sprites = getEnemyBulletSprites()
	for index, sprite in pairsByKeys(sprites) do
		
		local neuron = (2 * index) + 20
		input[neuron] = sprite["x"] / SCREEN_MAX_X
		input[neuron + 1] = sprite["y"] / SCREEN_MAX_Y
	end
	
	--get player bullet sprites
	sprites = getPlayerBulletSprites()
	for index, sprite in pairsByKeys(sprites) do
		local neuron = (2 * index) + 36
		input[neuron] = sprite["x"] / SCREEN_MAX_X
		input[neuron + 1] = sprite["y"] / SCREEN_MAX_Y
	end
	
	--get info about formation
	local formation = getFormationTF()
	for index, enemyPresent in pairsByKeys(formation) do
		if enemyPresent then
			input[41 + index] = 1
		end
	end
	
	return input
end

function intensityInput(x, y)
	x = x or 20
	y = y or 23
	local xStep = math.floor(SCREEN_MAX_X / x)
	local yStep = math.floor(SCREEN_MAX_Y / y)
	
	local intensities = {}
	
	for i = 1, y do
		for j = 1, x do
			table.insert(intensities, areaIntensity( (j-1) * xStep, (i-1) * yStep, j * xStep, i * yStep ))
		end
	end
	
	return intensities
end

function centeredInput()
	local left = memory.readbyte(PLAYER_POS) - 40
	local right = left + 88
	local top = 8
	local bottom = 224
	local vals = {}
	
	for y = top, bottom, 8 do
		for x = left, right, 8 do
			table.insert(vals, areaIntensity(x, y, x+8, y+8))
		end
	end
	
	return vals --length 336
end
--***
--/Input Function
--***


--***
--Output Function
--***
function galagaOutputFunction(output)
	--get joypad
	local cont = joypad.getimmediate(1)
	
	--clear joypad
	for name, _ in pairs(cont) do
		cont[name] = false
	end
	
	--set joypad
	cont["A"] = (output[1] > 0)
	cont["left"] = (output[2] > 0)
	cont["right"] = (output[3] > 0)
	joypad.set(1, cont)
end
--***
--/Output Function
--***


--***
--Misc. Galaga functions
--***
function getFormationTF()
	local formation = {}
	
	--First row
	for b = ROW_1_FIRST_BYTE, ROW_1_LAST_BYTE do
		table.insert(formation, (memory.readbyte(b) > 0))
	end
	
	--Second row
	for b = ROW_2_FIRST_BYTE, ROW_2_LAST_BYTE do
		table.insert(formation, (memory.readbyte(b) > 0))
	end
	
	--Third row
	for b = ROW_3_FIRST_BYTE, ROW_3_LAST_BYTE do
		table.insert(formation, (memory.readbyte(b) > 0))
	end
	
	--Forth row
	for b = ROW_4_FIRST_BYTE, ROW_4_LAST_BYTE do
		table.insert(formation, (memory.readbyte(b) > 0))
	end
	
	--Fifth row
	for b = ROW_5_FIRST_BYTE, ROW_5_LAST_BYTE do
		table.insert(formation, (memory.readbyte(b) > 0))
	end
	
	return formation
end

function getAttackSprites()
	local sprites = {}
	for b = FIRST_SPRITE_BYTE, LAST_SPRITE_BYTE, SPRITE_STEP do
		if memory.readbyte(b) ~= NO_SPRITE then
			local x = memory.readbyte(b + X_POS_OFFSET)
			local y = memory.readbyte(b + Y_POS_OFFSET)
			sprites[#sprites+1] = {["x"] = x, ["y"] = y}
		end
	end
	return sprites
end

function getEnemyBulletSprites()
	local sprites = {}
	for b = FIRST_BULLET_BYTE, LAST_BULLET_BYTE, BULLET_STEP do
		if (memory.readbyte(b) ~= NO_SPRITE) and (memory.readbyte(b) ~= OFF_SCREEN) then
			local x = memory.readbyte(b + BULLET_X_OFFSET)
			local y = memory.readbyte(b + BULLET_Y_OFFSET)
			sprites[#sprites+1] = {["x"] = x, ["y"] = y}
		end
	end
	return sprites
end

function getPlayerBulletSprites()
	local sprites = {}
	for b = FIRST_PLAYER_BULLET_BYTE, LAST_PLAYER_BULLET_BYTE, PLAYER_BULLET_STEP do
		if (memory.readbyte(b) ~= NO_SPRITE) and (memory.readbyte(b) ~= OFF_SCREEN) then
			local x = memory.readbyte(b + BULLET_X_OFFSET)
			local y = memory.readbyte(b + BULLET_Y_OFFSET)
			sprites[#sprites+1] = {["x"] = x, ["y"] = y}
		end
	end
	return sprites
end

function getPlayerPos()
	return memory.readbyte(PLAYER_POS)
end

function getShotsFired()
	local sum = 0
	local placeVal = 1
	for b = SHOTS_LAST_BYTE, SHOTS_FIRST_BYTE, -1 do
		digit = memory.readbyte(b)
		sum = sum + placeVal * digit
		placeVal = placeVal * 10
	end
	return sum
end

function getScore()
	local sum = 0
	local placeVal = 1
	for b = SCORE_LAST_BYTE, SCORE_FIRST_BYTE, -1 do
		digit = memory.readbyte(b)
		sum = sum + placeVal * digit
		placeVal = placeVal * 10
	end
	return sum
end

function getEnemiesHit()
	local sum = 0
	local placeVal = 1
	for b = ENEMIES_HIT_LAST_BYTE, ENEMIES_HIT_FIRST_BYTE, -1 do
		digit = memory.readbyte(b)
		sum = sum + placeVal * digit
		placeVal = placeVal * 10
	end
	return sum
end

function getHitMissRatio()
	if getShotsFired() == 0 then
		return 0
	end
	return getEnemiesHit() / getShotsFired()
end

function areaIntensity(x1, y1, x2, y2)
	if x1 < SCREEN_MIN_X then
		x1 = SCREEN_MIN_X
	end
	if x1 > SCREEN_MAX_X then
		x1 = SCREEN_MAX_X
	end
	if x2 < SCREEN_MIN_X then
		x2 = SCREEN_MIN_X
	end
	if x2 > SCREEN_MAX_X then
		x2 = SCREEN_MAX_X
	end
	if y1 < SCREEN_MIN_Y then
		y1 = SCREEN_MIN_Y
	end
	if y1 > SCREEN_MAX_Y then
		y1 = SCREEN_MAX_Y
	end
	if y2 < SCREEN_MIN_Y then
		y2 = SCREEN_MIN_Y
	end
	if y2 > SCREEN_MAX_Y then
		y2 = SCREEN_MAX_Y
	end
	
	local sum = 0
	local count = 0
	for x = x1, x2 do
		for y = y1, y2 do
			sum = sum + pixelIntensity(emu.getscreenpixel(x, y, true))
			count = count + 1
		end
	end
	
	if count == 0 then
		return 0
	end
	
	return sum / count
end

function pixelIntensity(r, g, b)
	r = r / 255
	g = g / 255
	b = b / 255
	return math.sqrt((r*r)+(g*g)+(b*b))
end
--***
--/Misc. Galaga functions
--***

file = io.open("test.input", "w")

frames = 0
while (true) do
	frames = frames + 1
    
    vals = centeredInput()
    line = ""
    
    for i = 1, 336 do
        line = line..string.format("%.4f ", vals[i])
    end
    
    line = line..'\n'
    
    file:write(line)
	
	emu.frameadvance();
end

file:close()
