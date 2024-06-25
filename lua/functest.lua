-- Imports
package.path = package.path .. ";D:/Programming/Github/NES_Nets/lua/?.lua"
ga = require("galaga")
json = require("json")

SCREEN_MIN_Y = 0 --decimal
SCREEN_MAX_Y = 230 --decimal
SCREEN_MIN_X = 0
SCREEN_MAX_X = 200 -- decimal

file = io.open("test.txt", "w")

-- Load savestate
savestate.load(savestate.object(10))

-- Skip forward a bit
for i=1,100 do
    emu.frameadvance()
end

-- Capture frrame
data = {}
for j=0, SCREEN_MAX_Y do
    for i=0, SCREEN_MAX_X do
        data[j*SCREEN_MAX_X + i] = emu.getscreenpixel(i, j, true)
    end
end

file:write(json.encode(data))
file:close()