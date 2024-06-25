-- Imports
package.path = package.path .. ";D:/Programming/Github/NES_Nets/lua/?.lua"
ga = require("galaga")
json = require("json")

input = json.decode(io.stdin:read())
print("Input: ", input)

-- Set emulation speed and seed RNG
--emu.speedmode("turbo")
math.randomseed(os.time())

-- Load save state
savestate.load(savestate.object(10))

local pic_taken = false
local pic_data = nil

-- Run game
local i=0
while not ga.is_game_over() do

    if joypad.get(1).select then
        if not pic_taken then
            pic_data = ga.get_pixels()
            pic_taken = true
            print("Pic taken")
        end
    end

    left = (math.random() > 0.5)
    cont = {A=true, left=(left), right=(not left)}
    joypad.set(1, cont)
    i = i + 1
    emu.frameadvance()
end

-- Write data to stdout
local output = {
    score = ga.get_score(), 
    accuracy = ga.get_hit_miss_ratio(),
    frames = i,
    pic = pic_data
}
print(json.encode(output))
io.write(json.encode(output))

print("Output: ", output)
print("Script end")
--emu.exit()