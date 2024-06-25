-- This is mostly coppied from the "Old_Code" lua stuff

-- Galaga constants

--General Consts
local NO_SPRITE = 0x80
local OFF_SCREEN = 0xFF
local PLAYER_POS = 0x0203
local EXTRA_LIVES_BYTE = 0x0487
local MYSTERY_BYTE = 0x0471

--Attack sprite constants
local FIRST_SPRITE_BYTE = 0x0220
local LAST_SPRITE_BYTE = 0x02D0
local SPRITE_STEP = 0x10
local X_POS_OFFSET = 0x3
local Y_POS_OFFSET = 0x2

--Enemy Bullet sprite constants
local FIRST_BULLET_BYTE = 0x0090
local LAST_BULLET_BYTE = 0x00AC
local BULLET_STEP = 0x4
local BULLET_X_OFFSET = 0x2
local BULLET_Y_OFFSET = 0x1

--Player bullet sprite constants
local FIRST_PLAYER_BULLET_BYTE = 0x02E0
local LAST_PLAYER_BULLET_BYTE = 0x02E8
local PLAYER_BULLET_STEP = 0x8

--Score
local SCORE_FIRST_BYTE = 0x00E0
local SCORE_LAST_BYTE = 0x00E6

--Shots Fired
local SHOTS_FIRST_BYTE = 0x04A0
local SHOTS_LAST_BYTE = 0x04A7

--Enemies Hit
local ENEMIES_HIT_FIRST_BYTE = 0x04A8
local ENEMIES_HIT_LAST_BYTE = 0x04AF

--Position constants
local PLAYER_MIN_POS = 8 --decimal
local PLAYER_MAX_POS = 183 --decimal
local SCREEN_MIN_Y = 0 --decimal
local SCREEN_MAX_Y = 230 --decimal
local SCREEN_MIN_X = 0
local SCREEN_MAX_X = 199 -- decimal

--Enemy Formation Constants
local ROW_1_FIRST_BYTE = 0x0403
local ROW_1_LAST_BYTE = 0x0406
local ROW_2_FIRST_BYTE = 0x0411
local ROW_2_LAST_BYTE = 0x0418
local ROW_3_FIRST_BYTE = 0x0421
local ROW_3_LAST_BYTE = 0x0428
local ROW_4_FIRST_BYTE = 0x0430
local ROW_4_LAST_BYTE = 0x0439
local ROW_5_FIRST_BYTE = 0x0440
local ROW_5_LAST_BYTE = 0x0449

--Input constants
local GRID_X = 19
local GRID_y = 23

local ButtonNames = {
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

local function read_BCD(first_byte, last_byte)
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

function ga.get_pixels(xmin, xmax, ymin, ymax)
	-- default values
	xmin = xmin or 0
	xmax = xmax or SCREEN_MAX_X
	ymin = ymin or 0
	ymax = ymax or SCREEN_MAX_Y

	-- get pixel data
	data = {}
	for j=0, ymax do
		data[j] = {}
		for i=0, xmax do
			r, g, b = emu.getscreenpixel(i, j, true)
			data[j][i] = {r, g, b}
		end
	end

	return data
end

return ga