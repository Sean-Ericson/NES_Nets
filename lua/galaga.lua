-- This is mostly coppied from the "Old_Code" lua stuff

-- Galaga constants

--General Consts
NO_SPRITE = 0x80
OFF_SCREEN = 0xFF
PLAYER_POS = 0x0203
EXTRA_LIVES_BYTE = 0x0487
MYSTERY_BYTE = 0x0471

--Attack sprite constants
FIRST_SPRITE_BYTE = 0x0220
LAST_SPRITE_BYTE = 0x02D0
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
ROW_1_LAST_BYTE = 0x0406
ROW_2_FIRST_BYTE = 0x0411
ROW_2_LAST_BYTE = 0x0418
ROW_3_FIRST_BYTE = 0x0421
ROW_3_LAST_BYTE = 0x0428
ROW_4_FIRST_BYTE = 0x0430
ROW_4_LAST_BYTE = 0x0439
ROW_5_FIRST_BYTE = 0x0440
ROW_5_LAST_BYTE = 0x0449

--Input constants
GRID_X = 19
GRID_y = 23

ButtonNames = {
	"A",
	"B",
	"up",
	"down",
	"left",
	"right",
	"start",
	"select"
}

-- Helper Functions

function read_BCD(first_byte, last_byte)
	-- Ready big-endian binary coded decimal from memory
	local sum = 0
	local placeVal = 1
	for b = last_byte, first_byte, -1 do
		sum = sum + placeVal * memory.readbyte(b)
		placeVal = placeVal * 10
	end
	return sum
end

-- Galaga Module
local ga = {}

function ga.is_game_over()
	local lifeByte = memory.readbyte(EXTRA_LIVES_BYTE)
	local shipByte = memory.readbyte(MYSTERY_BYTE)
	return (lifeByte == 0) and ((shipByte == 0) or (shipByte == 0xF0))
end

function ga.get_shots_fired()
	return read_BCD(SHOTS_FIRST_BYTE, SHOTS_LAST_BYTE)
end

function ga.get_score()
	return read_BCD(SCORE_FIRST_BYTE, SCORE_LAST_BYTE)
end

function ga.get_enemies_hit()
	return  read_BCD(ENEMIES_HIT_FIRST_BYTE, ENEMIES_HIT_LAST_BYTE)
end

function ga.get_hit_miss_ratio()
	local shots_fired = ga.get_shots_fired()
	if shots_fired == 0 then
		return 0
	end
	return ga.get_enemies_hit() / shots_fired
end

return ga