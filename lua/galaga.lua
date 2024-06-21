local galaga = {}

EXTRA_LIVES_BYTE = 0x0487
MYSTERY_BYTE = 0x0471

function galaga.get_score()
    first_adress = 224
    n = 7 --number of digits

    score = 0
    for i = n-1,0,-1 do 
        digit = memory.readbyte(first_adress+(6 - i))
        score = score + digit * math.pow(10, i)
    end
    return score
end

function galaga.game_over()
	local lifeByte = memory.readbyte(EXTRA_LIVES_BYTE)
	local shipByte = memory.readbyte(MYSTERY_BYTE)
	return (lifeByte == 0) and ((shipByte == 0) or (shipByte == 0xF0))
end

return galaga