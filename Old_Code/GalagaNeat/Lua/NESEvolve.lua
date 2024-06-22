-- Misc

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

function ReLU(x)
    if x < 0 then
        return 0
    end
    return x
end

function step(x)
	if x > 0 then
		return 1
	end
	return 0
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

--Custom len() function for tables becuause apparently #table is bad
-->Shamelessly stolen from https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Galaga Code
--This section is the code to apply the network evolution to Galaga
--These functions and defaults assume galaga is currently playing in the emulator
--when you start this script.

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
	return (getScore() * getHitMissRatio())
end
--***
--/Fitness function
--***

--***
--Initialize function
--***

function galagaInit()
    memory.writebyte(PLAYER_POS, math.random(PLAYER_MIN_POS, PLAYER_MAX_POS))
end

--***
--/Initialize function
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

function centeredInput(needed)
	local left = memory.readbyte(PLAYER_POS) - 40
	local right = left + 88
	local top = 8
	local bottom = 224
	local vals = {}
	
    local pos = 0
	for y = top, bottom, 4 do 
		for x = left, right, 4 do
            pos = pos + 1
            if needed[pos] then
                table.insert(vals, areaIntensity(x, y, x+4, y+4))
            else
                table.insert(vals, 0)
            end
		end
	end
	
	return vals --length 1265
end

--Output Function
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
		return 0
	end
	if x2 < SCREEN_MIN_X then
		return 0
	end
	if x2 > SCREEN_MAX_X then
		x2 = SCREEN_MAX_X
	end
	if y1 < SCREEN_MIN_Y then
		y1 = SCREEN_MIN_Y
	end
	if y1 > SCREEN_MAX_Y then
		return 0
	end
	if y2 < SCREEN_MIN_Y then
		return 0
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

--******************************
--End Galaga code
--******************************

--Parameter names

NETWORK_PARAMETERS = {"inputSize", "maxNodes", "outputSize"}
SPECIES_PARAMETERS = {"connectionCoeff", "weightCoeff", "speciesThreshold", "crossoverChance"}
EVOLUTION_PARAMETERS = {"mutateWeightsChance", "affectedWeigths", "perturbChance", "stepSize", "linkMutationChance",
                        "biasMutationChance", "nodeMutationChance", "disableMutationChance", "enableMutationChance"}

--Pool Class:
-->>A collection of genomes split into species
-->>R E N spells Ren but I'm raw.
--**********
Pool = {}
Pool.__index = Pool

--Constructor
function Pool:new(networkParams, poolParams, evolveParams, speciesParams)
	local pool = {}
	setmetatable(pool, Pool)
	
	if (networkParams == nil) or (poolParams == nil) or (evolveParams == nil) or (speciesParams == nil) then
		LogError("Attempt to create new pool with bad argument")
	end
	
	pool.networkParameters = networkParams
	pool.evolutionParameters = evolveParams
	pool.poolParameters = poolParams
	pool.speciesParameters = speciesParams
	
	pool.species = {}
	pool.children = {}
	pool.generation = 0
	pool.staleness = 0
	pool.averageFitness = 0
	pool.bestAverage = 0
	pool.nextSpeciesId = 0
    pool.timesNuked = 0
	pool.innovationTracker = nil
	
	return pool
end

--Fill the pool with an initial population
-->Hey! Teacher! Leave them kids alone!!!
function Pool:initialize(seedChildren)
	--Clear everyting. Fresh starts are nice, aren't they?
	self.species = {}
	self.children = {}
	self.generation = 0
	self.staleness = 0
	self.averageFitness = 0
	self.bestAverage = 0
	self.nextSpeciesId = 1
	self.innovationTracker = InnovationTracker:new()
	
	--create initial population of seed children
	for i = 1, seedChildren do
		local genome = Genome:new(self.networkParameters, self.evolutionParameters, self.innovationTracker)
		genome:mutate(false)
		table.insert(self.children, genome)
	end
	
	self:evaluateAllGenomes()
end

--Determine if two genomes are in the same species
function Pool:compatibleGenomes(genome1, genome2)
	local dc = connectionDisjointness(genome1, genome2)
	local dw = weightDisjointness(genome1, genome2)
	
	--print(string.format("dc: %.3f\tdw: %.3f", dc, dw))

	local cCoeff = self.speciesParameters["connectionCoeff"]
	local wCoeff = self.speciesParameters["weightCoeff"]
	
	local score = (cCoeff * dc) + (wCoeff * dw)
	
	--print("Score: "..score)
	--print()
	
	return score < self.speciesParameters["speciesThreshold"]
end

--Add a genome to the pool, inserting it into a species
function Pool:addGenome(genome)
	if genome == nil then
		LogError("Attempt to add nil genome to pool")
	end

	local foundSpecies = false
	
	--Randomize the order of the species
	shuffleTable(self.species)
	
	--Loop through current species until one is found that is compatiable w/ the genome
	for _, species in pairs(self.species) do
		if (not foundSpecies) and self:compatibleGenomes(genome, species:randomGenome()) then
			species:add(genome)
            foundSpecies = true
		end
	end
	
	--If a compatible species is not found, this genome must be a freak of nature and deserves
	--its own species. How special.
	if not foundSpecies then
		local newSpecies = Species:new(self.speciesParameters)
		newSpecies:add(genome)
		newSpecies.id = self.nextSpeciesId
		self.nextSpeciesId = self.nextSpeciesId + 1
		table.insert(self.species, newSpecies)
	end
end

function Pool:adoptGenome(genome)
    if genome == nil then
		LogError("Attempt to adopt nil genome")
        return
	end
    
    genome.networkParameters = self.networkParameters
    genome.evolutionParameters = self.evolutionParameters
    
    for _, gene in pairs(genome.genes) do
        gene.innovation = self.innovationTracker:add(gene)
	end
	
	genome.innovationTracker = self.innovationTracker
    genome.fitness = nil
    
	table.insert(self.children, genome)
end

--Cull the specified amount of the weakest of each species (culling the bottom 75% of a 10 genome species will leave 3 genomes, not 2)
-->>after this function executes the total pool population might be less than maximum
function Pool:cullWeakGenomesBySpecies(proportion)
	for _, species in pairs(self.species) do
		local survivingGenomes = {}
		
		--Sort genomes in order of decreasing fitness
		table.sort(species.genomes, function (a,b) return (a.fitness > b.fitness) end) 
		
		--Figure out the number of genomes to cull in this species
		local weakGenomes = math.floor(proportion * #species.genomes)
		
		--Remove weak genomes
		for i = 1, weakGenomes do
			table.remove(species.genomes)
		end
		
		--if the species is empty now, uh, something when wrong
		if #species.genomes == 0 then
			LogError("Culling weak genomes resulted in a species with no adults!!!")
		end
	end
end

--return n random genomes from the pool
function Pool:randomGenomes(n, adultOnly)
	--Generate a table of every genome
	local allGenomes = {}
	for _, species in pairs(self.species) do
		for _, genome in pairs(species.genomes) do
			table.insert(allGenomes, genome)
		end
	end
	
	shuffleTable(allGenomes)
	
	--Ranomly select n of them (with replacement)
	local randomGenomes = {}
	for i = 1, n do
		table.insert(randomGenomes, allGenomes[i])
	end
	
	return randomGenomes
end

--For when the pool becomes stale; removes all but the 2 species with the best top/average fitness
-->>Also randomly selects a few genomes to mutate a few times
function Pool:nukePool()
	if #self.species == 0 then
		LogError("Attempt to nuke an empty pool.")
	end
    
    self.timesNuked = self.timesNuked + 1

	print("*******************")
	print("NUKING POOL!!!")
	print("*******************")
	
	--take 3 genomes to irradiate. Why 3? because the illuminati that's why.
	local victims = self:randomGenomes(3)
	
	--Sort the species by average fitness and take species w/ best average fitness
	table.sort(self.species, function (a, b) return (a.averageFitness < b.averageFitness) end)
	local bestAverageFitness = table.remove(self.species)
	
	--Make the two species grabbed the only species in the pool
	self.species = {}
	table.insert(self.species, bestAverageFitness)
	
	--screw up those genomes you pulled out and add them to the pool if there is room
	for _, genome in pairs(victims) do
		for j = 1, 25 do --Mutate 25 times. Why 25? Why u ask so many goshdern questions? 
			genome:mutate(false)
		end
		
		if self:currentPop(true, true) < self.poolParameters["population"] then
			self:addGenome(genome)
		end
	end
	
end

--Calculate the current number of genomes in the pool
function Pool:currentPop()
	local sum = 0
	for _, species in pairs(self.species) do
		sum = sum + #species.genomes
	end
	
	sum = sum + #self.children
	
	return sum 
end

--Calculate the average fitness of each species
function Pool:calculateSpeciesAverages()
	for _, species in pairs(self.species) do
		species:calculateAverageFitness()
	end
end

--Calculate the average fitness of each species and return the sum
-->>Average fitnesses must be calculated before this function is called
function Pool:calculateTotalAverageFitness()
	local sum = 0
	for _, species in pairs(self.species) do
		sum = sum + species.averageFitness
	end
	
	return sum
end

function Pool:calculateActualAverageFitness()
	local sum = 0
	for _, species in pairs(self.species) do
		for _, genome in pairs(species.genomes) do
			sum = sum + genome.fitness
		end
	end
	
	self.averageFitness = sum / self:currentPop()
	return self.averageFitness
end

--After evaluating and culling the population, need to repopulate
-->>The amount each species gets to contribute to the population depends on 
-->>how much their average fitness contributes to the total average fitness
-->>maxResultingPopPercent is the amount the population should be restored to
function Pool:proportionalRepopulate(maxResultingPopPercent)
	print("population before propRepop: "..self:currentPop())

	--default value for arg
	maxResultingPopPercent = maxResultingPopPercent or 1
	
	--Figure out how many kidos need to be made
	local childrenNeeded = math.floor(maxResultingPopPercent * self.poolParameters["population"]) - self:currentPop()
	
	--Calculate the sum of all average fitnesses
	local totalFitness = self:calculateTotalAverageFitness()
	
	--table to hold new kiddos
	local newKids = {}
	
	--Each species gets to contribute a percentage of the next generation equivilent to
	--the percentage it contributes to the totalFitness
	for i, species in pairs(self.species) do
		--Determine amount of children this species gets to make
		local percentContribution = species.averageFitness / totalFitness
		local childrenToCreate = math.floor(percentContribution * childrenNeeded)
		
		--Make the children
		for j = 1, childrenToCreate do
			table.insert(newKids, species:createChild())
		end
	end
	
	--Add children to pool
	for _, child in pairs(newKids) do
		table.insert(self.children, child)
	end
	
	--Since the floor operation is used, the current population should be <= the maximum
	if self:currentPop() > self.poolParameters["population"] then
		LogError("Too many genomes after repopulation")
	end
end

--Randomly breeds children in random species until the population is at a maximum
-->I want this to pick species at random and not genomes so that small species don't have a negligable chance of reproducing
function Pool:randomRepopulate()
	print("Population before randRepop: "..self:currentPop())
	
	local childrenNeeded = self.poolParameters["population"] - self:currentPop()
	local newKids = {}
    
    if (childrenNeeded > 0) and (#self.species > 1) and (math.random() < self.poolParameters["interspeciesChance"]) then
        shuffleTable(self.species)
        
        table.sort(self.species[1], function (a, b) return (a.fitnes > b.fitness) end)
        table.sort(self.species[2], function (a, b) return (a.fitnes > b.fitness) end)
        
        local g1 = self.species[1].genomes[1]
        local g2 = self.species[2].genomes[1]
        print("mixin species")
        table.insert(newKids, crossover(g1, g2))
    end
	
	while #newKids < childrenNeeded do
		local species = self.species[math.random(#self.species)]
		if #species.genomes > 0 then
			table.insert(newKids, species:createChild())
		end
	end
	
	--Add children to pool
	for _, child in pairs(newKids) do
		table.insert(self.children, child)
	end
end

--Evolve the pool for n generations
function Pool:evolve(n)
	for i = 1, n do
		self:nextGeneration()
	end
end

--Removes stale species (except for best species)
function Pool:cullStaleSpecies()
	if #self.species < 1 then
		LogError("Attempt to cull stale species on empty pool")
	end
	
	local survivors = {}
	
	--Save the best species
	table.sort(self.species, function (a, b) return (a.averageFitness < b.averageFitness) end)
	table.insert(survivors, table.remove(self.species))
	
	--Save non-stale species
	for _, species in pairs(self.species) do
		if (species.staleness < self.poolParameters["maxSpeciesStaleness"]) or (species.age < self.poolParameters["minSpeciesCullAge"]) then
			table.insert(survivors, species:copy())
		end
	end
	
	--Set the survivors as the pool's species
	self.species = survivors
end

function Pool:cullWeakSpecies(cullPercent)
	if #self.species < 1 then
		LogError("Attempt to cull weak species on empty pool")
	end
	
	--Determine number of species to cull
	local weakSpecies = math.floor(cullPercent * #self.species)
	
	--sort species by average fitness then cull
	table.sort(self.species, function (a, b) return (a.averageFitness > b.averageFitness) end)
	for i = 1, weakSpecies do
		if self.species[#self.species].age >= self.poolParameters["minSpeciesCullAge"] then
			table.remove(self.species)
		end
	end
end

function Pool:nextGeneration()
	if #self.species == 0 then
        LogError("Call to nextGeneration on empty pool!")
    end
	
	--Start by breeding until the pool is at capacity
	self:proportionalRepopulate(self.poolParameters["maxProportionalRepop"])
	self:randomRepopulate()
	
	--Evaluate the newly created genomes
	self:evaluateAllGenomes(true) --true to display progress
	
	--Cull the weak genomes in each species
	self:cullWeakGenomesBySpecies(self.poolParameters["genomeCullPercent"])
	
	--Calculate each species's fitness
	self:calculateSpeciesAverages()
	
	--Determine if the pool's average fitness has increased
	self:calculateActualAverageFitness()
	
	--Determine if the pool is improving
	if self.averageFitness > self.bestAverage then
		self.staleness = 0
		self.bestAverage = self.averageFitness
	else
		self.staleness = self.staleness + 1
	end
	
	--Determine if the pool is stale
	if (self.staleness - (self.timesNuked * self.poolParameters["maxPoolStaleness"])) >= self.poolParameters["maxPoolStaleness"] then
		--The pool is stale, so nuke it
		self:nukePool()
	else
		self:cullStaleSpecies()
		self:cullWeakSpecies(self.poolParameters["speciesCullPercent"])
	end
	
	--Update surviving species ages
	for _, species in pairs(self.species) do
		species.age = species.age + 1
	end
    
    --Alter speciation threshold parameter
    if (#self.species / self.poolParameters["population"]) < self.speciesParameters["targetSpeciation"] then
        self.speciesParameters["speciesThreshold"] = self.speciesParameters["speciesThreshold"] - self.speciesParameters["thresholdDelta"]
    end
    if (#self.species / self.poolParameters["population"]) > self.speciesParameters["targetSpeciation"] then
        self.speciesParameters["speciesThreshold"] = self.speciesParameters["speciesThreshold"] + self.speciesParameters["thresholdDelta"]
    end
    for _, species in pairs(self.species) do
        species.parameters = self.speciesParameters
    end
	
	--increment generation
	self.generation = self.generation + 1
end

--Evaluate the fitness of each genome in the pool
-->Also updates stalenesses
function Pool:evaluateAllGenomes(displayProgress)

	--for displaying progress
	local totalChildren = #self.children
	local genomesEvaluated  = 0
	
	--Evaluate them genomes, bruh
	for _, genome in pairsByKeys(self.children) do
		if genome.fitness ~= nil then
		print("TESTING ALREADY TESTED GENOME!!!")
		end
		genomesEvaluated = genomesEvaluated + 1
		local sum = 0
		for i = 1, self.poolParameters["evalsPerGenome"] do
			printInfo = {200, 200, string.format("(%d/%d) %d", genomesEvaluated, totalChildren, i)}
			sum = sum + self:evaluateGenome(genome, printInfo)
			genome.fitness = sum / i
		end
	end
	
	for i = 1, totalChildren do
		self:addGenome(table.remove(self.children))
	end
	
	if tablelength(self.children) ~= 0 then
		print("CHILDREN REMAIN AFTER EVAL!!!")
	end
end

--Evaluate the fitness of a single genome
-->>printInfo is for printing which genome is being run
-->>Returns determined fitness
function Pool:evaluateGenome(genome, printInfo)
	local saveSlot = self.poolParameters["saveState"]
	local activeFunction = self.poolParameters["activeFunc"]
	local inputFunction = self.poolParameters["inputFunc"]
	local outputFunction = self.poolParameters["outputFunc"]
	local fitnessFunction = self.poolParameters["fitnessFunc"]
    local timeoutValueFunction = self.poolParameters["timeoutValFunc"]
    local maxFrames = self.poolParameters["timeoutFrames"]
    local initFunction = self.poolParameters["initFunc"]
    
    --tmp hack plz
    needed = {}
    for _, gene in pairs(genome.genes) do
        if gene.out == nil then
            print("gene out nil")
        end
        if self.networkParameters["inputSize"] == nil then
            print("inputSize nil")
        end
        if gene.out <= self.networkParameters["inputSize"] then
            needed[gene.out] = true
        end
    end
	
	--Get the network
	local net = Network:new(genome)
	
	--Load the save state
	savestate.load(savestate.object(saveSlot))
    
    --Initialize the saveState
    initFunction()
	
	--While the activeFunction returns true, play a frame
    local timeoutFrames = 0
    local timeoutVal = timeoutValueFunction() --Get the value to watch for stagnation
    local active = true
	while active do
		--Get network inputs from inputFunction
		local inputs = inputFunction(needed)
		
		--Supply inputs to network to get outputs
		local outputs = net:evaluate(inputs)
		
		--Use outputFunction to apply outputs to the game
		outputFunction(outputs)
        
        --check for timeout
        local currentTimeoutVal = timeoutValueFunction()
        if currentTimeoutVal ~= timeoutVal then
            timeoutVal = currentTimeoutVal
            timeoutFrames = 0
        else
            timeoutFrames = timeoutFrames + 1
        end
        
        if timeoutFrames >= maxFrames then
            active = false
        else
            active = activeFunction()
		end


		if printInfo ~= nil then
			gui.text(printInfo[1], printInfo[2], printInfo[3])
            local fit = ""
            if genome.fitness ~= nil then
                fit = tostring(genome.fitness)
            end
            gui.text(200, 210, tostring(fitnessFunction()))
            gui.text(200, 220, fit)
		end
        
		--Advance a frame
		emu.frameadvance()
	end
	
	return fitnessFunction()
end

--Return a copy of every adult in the pool
function Pool:allGenomes()
    local all = {}
    for _, species in pairs(self.species) do
        for _, genome in pairs(species.genomes) do
            table.insert(all, genome:copy())
        end
    end
    return all
end

--Returns the best genome in the pool
function Pool:bestGenome() 
	local best = self:randomGenomes(1)[1]
	
	if best == nil then
		LogError("Ummmm, somethin went wrong. Idk wut.")
	end
	
	for _, species in pairsByKeys(self.species) do
		for _, genome in pairsByKeys(species.genomes) do
			if genome.fitness > best.fitness then
				best = genome
			end
		end
	end
	
	return best:copy()
end

--Play the best network in the pool 
function Pool:playTopNet()
	self:evaluateGenome(self:bestGenome())
end
--**********
--/Pool
--**********

--InnovationTracker Class
-->>Tracks the new genes being introduced to the pool

InnovationTracker = {}
InnovationTracker.__index = InnovationTracker

--Constructor
function InnovationTracker:new()
	local innovationTracker = {}
	setmetatable(innovationTracker, InnovationTracker)
	
	innovationTracker.innovations = {}
	
	return innovationTracker
end

--Try to add a gene to the pool; returns the innovation # of the gene
function InnovationTracker:add(newGene)
	--figure out if gene already in pool
	local innovation = 0
	for index, gene in pairsByKeys(self.innovations) do
		if (newGene.out == gene.out) and (newGene.into == gene.into) then
			innovation = index
		end
	end
	
	--if the gene isn't in the pool, add it
	if innovation == 0 then
		table.insert(self.innovations, newGene)
		innovation = tablelength(self.innovations)
	end
	
	return innovation
end

--Return the last innovation (0 if none)
function InnovationTracker:newest()
	return tablelength(self.innovations)
end
--**********
--/InnovationTracker
--**********

--Species Class:
-->>A collection of similar genomes
-->>If you wanna find out what's behind these cold eyes,
-->>you'll just have to claw your way through this disguise!
Species = {}
Species.__index = Species

--Constructor
function Species:new(param)
	local species = {}
	setmetatable(species, Species)
	
	species.averageFitness = 0
	species.bestAverage = 0
	species.age = 0
	species.staleness = 0
	species.id = 0
    species.parameters = param
	species.genomes = {}
	
	return species
end

--Copy Constructor
function Species:copy()
	local species = Species:new(self.parameters)
	
	species.averageFitness = self.averageFitness
	species.bestAverage = self.bestAverage
	species.age = self.age
	species.staleness = self.staleness
	species.id = self.id
	
	species.genomes = {}
	for _, genome in pairs(self.genomes) do
		table.insert(species.genomes, genome:copy())
	end
	
	return species
end

--Add a genome to da species, yo
function Species:add(genome)
	table.insert(self.genomes, genome)
end

--Make a baby! Chance of either sexual reproduction (bowchickawowow) or 
-->>asexual reproduction(something you're probably more familiar with)
-->>the genomes used are random.
-->after the miracle of birth, the child is mutated. You know, normal health class shit
function Species:createChild()
	if #self.genomes == 0 then
		LogError("attemt to createChild in species with no adults")
		return
	end
	
	--Make the new genome
	-->>crossoverChance of breeding between two genomes (if there are more than two to breed)
	-->>else just a clone
	local child = nil
	if (math.random() < self.parameters["crossoverChance"]) and (tablelength(self.genomes) > 1) then
		shuffleTable(self.genomes)
		local g1 = self.genomes[1]:copy()
		local g2 = self.genomes[2]:copy()
		child = crossover(g1, g2)
	else
		child = self.genomes[math.random(#self.genomes)]:copy()
	end
	
	--Mix up dat genepool
	child:mutate(false)
	
	--Make sure the child has nil fitness since it hasnt been tested
	child.fitness = nil
	
	return child
end

--Sum the fitness of each genome and divide by the number of genomes
-->>Only call once per generation!
function Species:calculateAverageFitness()
	if #self.genomes == 0 then
		LogError("Attempt to calc. average fitness of species with no adults")
	end
	
	sum = 0
	count = 0
	for _, genome in pairsByKeys(self.genomes) do
		count = count + 1
		sum = sum + genome.fitness
	end
	
	self.averageFitness = sum / count
	
	--Update staleness
	if self.averageFitness > self.bestAverage then
		self.staleness = 0
		self.bestAverage = self.averageFitness
	else
		self.staleness = self.staleness + 1
	end
	
	return self.averageFitness
end

--Return a random member of the species
function Species:randomGenome()
	if #self.genomes == 0 then
		LogError("Attempt to pick random genome from a species with no genomes")
	end
	
	return self.genomes[math.random(#self.genomes)]
end
--**********
--/Species
--**********

--Genome Class
-->>A collection of genes describing a network

Genome = {}
Genome.__index = Genome

--Constructor
function Genome:new(netParam, evolveParam, tracker)
	local genome = {}
	setmetatable(genome, Genome)
	
	if (netParam == nil) or (evolveParam == nil) or (tracker == nil) then
		LogError("Bad argument to new genome")
		return {}
	end
	
	genome.networkParameters = netParam
	genome.evolutionParameters = evolveParam
	genome.innovationTracker = tracker
	genome.genes = {}
	genome.fitness = nil
	genome.maxHiddenNeuron = 0
	genome.firstHiddenNeuron = netParam["inputSize"] + 2
	genome.lastHiddenNeuron = netParam["maxNodes"] - netParam["outputSize"] --Lol, gotta switch names w/ maxHiddenNeuron
	
	return genome
end

--Copy Constructor
function Genome:copy()
	local genome = Genome:new(self.networkParameters, self.evolutionParameters, self.innovationTracker)
	
	genome.genes = {}
	for _, gene in pairs(self.genes) do
		table.insert(genome.genes, gene:copy())
	end
	genome.fitness = self.fitness
	genome.maxHiddenNeuron = self.maxHiddenNeuron
	genome.firstHiddenNeuron = self.firstHiddenNeuron
	genome.lastHiddenNeuron = self.lastHiddenNeuron
	
	return genome
end

--Return a random neuron described by the genes
-->>nonInput true means input and bias neurons not candidates
function Genome:randomNeuron(nonInput, nonOutput)
	local candidates = {}
	
	if not nonInput then
		for i = 1, self.firstHiddenNeuron - 1 do
			table.insert(candidates, i)
		end
	end
	
	if self.maxHiddenNeuron > 0 then
		for i = self.firstHiddenNeuron, self.maxHiddenNeuron do
			table.insert(candidates, i)
		end
	end
	
	if not nonOutput then
		for i = self.lastHiddenNeuron + 1, self.networkParameters["maxNodes"] do
			table.insert(candidates, i)
		end
	end
	
	return candidates[math.random(#candidates)]
end

--Mutate the weights of the genes
function Genome:mutateWeights()
	local step = self.evolutionParameters["stepSize"]
	local perturbChance = self.evolutionParameters["perturbChance"]
    local affected = math.floor(self.evolutionParameters["affectedWeights"] * #self.genes)
    
    if affected < 1 then --not enough genes to affect
        return
    end
    
    shuffleTable(self.genes)
	
	--For each gene, either perturb it's weight slightly or give it a complete new one
	for i = 1, affected do
        gene = self.genes[i]
		if math.random() < perturbChance then --perturb
			if math.random(2) == 1 then
				gene.weight = gene.weight + step --perturb up
			else
				gene.weight = gene.weight - step --perturb down
			end
		else --Give it a completely new weight
			gene.weight = (math.random() * 2) - 1 --changed from [-2, 2] to [-1, 1]
		end
	end
end

--Check if a link already exists in the genome
function Genome:containsLink(newGene)
	for _, gene in pairs(self.genes) do
		if (newGene.out == gene.out) and (newGene.into == gene.into) then
			return true
		end
	end
	return false
end

--Mutate by adding a (previously non-existant) connection between neurons
function Genome:linkMutate(forceBias)
	local inputs = self.networkParameters["inputSize"]
	local neuron1 = nil
	local neuron2 = nil
	
	if forceBias then
		neuron1 = inputs + 1 --make the source neuron the bias
	else
		neuron1 = self:randomNeuron(false, false) --make the source neuron any node (possibly bias)
	end
	
	neuron2 = self:randomNeuron(true, false) --make the dest. neuron any neuron besides input/bias
	
	if (neuron1 == 0) or (neuron2 == 0) then
		LogError("Unable to find 2 neurons for linkMutate")
		return
	end
	--Both neurons could be the same...but that's okay! What a neuron does with itself is its own business!
	
	local newLink = Gene:new()
	newLink.out = neuron1
	newLink.into = neuron2
	
	--At first I had a while-loop continually assigning random neurons until it found a link
	--that didn't already exist but I realized that if the network becomes fully connected the
	--loop will run forever so I decided to stick with SethBling's strategy of just returning
	--from the function  without making a new link if the link it tries to make alread exists.
	--I could just try to determine if the network is fully connected or not, but that seems 
	--like a rather labourious calculation to do everytime ya wanna mutate a link.
	if self:containsLink(newLink) then
		return
	end
	
	--To do: make an initializeWeight function so weight initializion doesn't use magic numbers
	newLink.weight = (math.random() * 2) - 1
	newLink.innovation = self.innovationTracker:add(newLink)
	
	table.insert(self.genes, newLink)
end

--Mutate by inserting a neuron where a link previously was
function Genome:nodeMutate()
	if tablelength(self.genes) == 0 then --Can't turn a link into a node if ya got no links!
		return --GTFO! It's a trap!!
	end
	
	--Check if the genome already has maximum neurons
	if self.maxHiddenNeuron >= (self.networkParameters["maxNodes"] - self.networkParameters["outputSize"]) then
		return
	end
	
	local link = self.genes[math.random(1, tablelength(self.genes))]
	if not link.enabled then --You got unlucky. You picked a disabled gene. Give up.
		return
	end
	
	--update maxHiddenNeuron
	if self.maxHiddenNeuron == 0 then
		self.maxHiddenNeuron = self.networkParameters["inputSize"] + 2
	else
		self.maxHiddenNeuron = self.maxHiddenNeuron + 1
	end
	
	--Disable old link
	link.enabled = false
	
	--make link from old source to new neuron (weight 1)
	local gene1 = Gene:new()
	gene1.out = link.out
	gene1.into = self.maxHiddenNeuron
	gene1.weight = 1
	gene1.innovation = self.innovationTracker:add(gene1)
	table.insert(self.genes, gene1)
	
	--make link from new neuron to old destination (same weight as initial link)
	local gene2 = Gene:new()
	gene2.out = self.maxHiddenNeuron
	gene2.into = link.into
	gene2.weight = link.weight
	gene2.innovation = self.innovationTracker:add(gene2)
	table.insert(self.genes, gene2)
end

--Mutate by enabling/disabling a random gene
function Genome:enableDisableMutate(enable)
	local candidates = {}
	--find all genes that could be enabled/disabled
	for _, gene in pairsByKeys(self.genes) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end
	
	--If none were found, BTFO
	if tablelength(candidates) == 0 then
		return
	end
	
	local gene = candidates[math.random(1,tablelength(candidates))]
	gene.enabled = not gene.enabled
end

--Mutate the genome based on the values in evolutionParameters
-->if alterParameters is set, the evolutionParameters are randomly increased/decreased
function Genome:mutate(alterParameters)

	local preLen = #self.genes
	--Mix up them rates to keep it fresh, yo
	-->>these are the original number's SethBling used
	if alterParameters then
		for mutation, rate in pairs(self.evolutionParameters) do
			if math.random(1,2) == 1 then
				self.evolutionParameters[mutation] = 0.95*rate
			else
				self.evolutionParameters[mutation] = 1.05263*rate
			end
		end
	end
	
	--Try to mutate weights. But don't ASK what the weights are; that's rude.
	if math.random() < self.evolutionParameters["mutateWeightsChance"] then
		self:mutateWeights()
	end
	
	--Try to mutate non-bias connections
	local p = self.evolutionParameters["linkMutationChance"]
	while p > 0 do
		if math.random() < p then
			self:linkMutate(false)
		end
		p = p - 1
	end
	
	--Try to mutate bias connections
	p = self.evolutionParameters["biasMutationChance"]
	while p > 0 do
		if math.random() < p then
			self:linkMutate(true)
		end
		p = p - 1
	end
	
	--Try to mutate by adding a node/neuron WHATEVER YOU WANT TO CALL IT I DON'T CARE ANYMORE
	p = self.evolutionParameters["nodeMutationChance"]
	while p > 0 do
		if math.random() < p then
			self:nodeMutate()
		end
		p = p - 1
	end
	
	--Enable some shit
	p = self.evolutionParameters["enableMutationChance"]
	while p > 0 do
		if math.random() < p then
			self:enableDisableMutate(true)
		end
		p = p - 1
	end
	
	--Disable some shit
	p = self.evolutionParameters["disableMutationChance"]
	while p > 0 do
		if math.random() < p then
			self:enableDisableMutate(false)
		end
		p = p - 1
	end
end

function Genome:writeToFile(filename)
	table.sort(self.genes, function (a, b) return (a.innovation < b.innovation) end)
	
	local file = io.open(filename, 'w')
    
    file:write(string.format("%.5f\n", self.fitness))
    file:write(string.format("%d\n", self.maxHiddenNeuron))
    
    for name, val in pairsByKeys(self.networkParameters) do
        file:write(string.format("%d\n", val))
    end
        
    for name, val in pairsByKeys(self.evolutionParameters) do
        file:write(string.format("%.3f\n", val))
    end
    
	for _, g in pairsByKeys(self.genes) do
		local state = ""
		if g.enabled then
			state = 1
		else
			state = 0
		end
		file:write(string.format("%d\t\t%d\t\t%.4f\t\t%d\t\t%d\n", g.out, g.into, g.weight, g.innovation, state))
	end
	file:close()
end

function Genome:readFromFile(filename)
    local file = io.open(filename, 'r')
    
    local fitness = tonumber(file:read("*line"))
    local maxHiddenNeuron = tonumber(file:read("*line"))
    
    local netParam = {}
    for _, name in pairsByKeys(NETWORK_PARAMETERS) do
        netParam[name] = tonumber(file:read("*line"))
    end
    
    local evoParam = {}
    for _, name in pairsByKeys(EVOLUTION_PARAMETERS) do
        evoParam[name] = tonumber(file:read("*liine"))
    end
    
    local genes = {}
    local readGenes = true
    while readGenes do
        local g = Gene:new()
        local enabled = nil
        g.out, g.into, g.weight, g.innovation, enabled = file:read("*number", "*number", "*number", "*number", "*number")
        
        if (g.out ~= nil) and (g.into ~= nil) and (g.weight ~= nil) and (g.innovation ~= nil) and (enabled ~= nil) then
            if enabled == 1 then
                g.enabled = true
            else
                g.enabled = false
            end
            table.insert(genes, g)
        else
            readGenes = false
        end
    end
    
    local genome = Genome:new(netParam, evoParam, InnovationTracker:new())
    genome.fitness = fitness
    genome.maxHiddenNeuron = maxHiddenNeuron
    genome.genes = genes
    
    file:close()
    
    return genome
end

--Functions which act on genome objects but aren't methods of the genome class

--Takes two genomes and returns a measurement of their connection disjointness
-->>if N and M are the respective sets of genes, this returns 1 - ((N intersect M) / (N union M))
function connectionDisjointness(genome1, genome2)
	--sort genes by innovation number
	local g1 = genome1.genes
	local g2 = genome2.genes
	local maxInnovation = 0
	
	local i1 = {}
	for _, gene in pairs(g1) do
		i1[gene.innovation] = true
		if gene.innovation > maxInnovation then
			maxInnovation = gene.innovation
		end
	end
	
	local i2 = {}
	for _, gene in pairs(g2) do
		i2[gene.innovation] = true
		if gene.innovation > maxInnovation then
			maxInnovation = gene.innovation
		end
	end
	
	local total = 0
	local shared = 0
	
	for i = 1, maxInnovation do
		if i1[i] or i2[i] then
			total = total + 1
			if i1[i] and i2[i] then 
				shared = shared + 1
			end
		end
	end
	
	--print("Total: "..total.."  Shared: "..shared)
	
	if total == 0 then
		return 0
	end
	
	return 1 - (shared / total)
end

--Return the average difference between the weights of matching genes in to genomes
function weightDisjointness(genome1, genome2)
	local g1 = genome1.genes
	local g2 = genome2.genes
	local maxInnovation = 0
	
	local i1 = {}
	for _, gene in pairs(g1) do
		i1[gene.innovation] = gene:copy()
		if gene.innovation > maxInnovation then
			maxInnovation = gene.innovation
		end
	end
	
	local i2 = {}
	for _, gene in pairs(g2) do
		i2[gene.innovation] = gene:copy()
		if gene.innovation > maxInnovation then
			maxInnovation = gene.innovation
		end
	end
	
	local sum = 0
	local coincident = 0
	
	for i = 1, maxInnovation do
		if (i1[i] ~= nil) and (i2[i] ~= nil) then
			coincident = coincident + 1
			sum = sum + math.abs(i1[i].weight - i2[i].weight)
		end
	end
	
	--print("Coincident: "..coincident.."   Sum: "..sum)
	
	if coincident == 0 then
		return 0
	end
	
	return sum / coincident
end

--"Mate" two genomes and return a child genome
-->> idk if I like how this crossover algorithim works. Might need tweeking. #YoloSwag420
function crossover(genome1, genome2)
	--Make sure genome1 is the more fit genome
	if genome2.fitness > genome1.fitness then
		tmp = genome1
		genome1 = genome2
		genome2 = tmp
	end
	
	--Call upon the storks to bring forth a baby genome
	-->>specifically one with the more fit parent's parameters
	local child = Genome:new(genome1.networkParameters, genome1.evolutionParameters, genome1.innovationTracker)
	
	--put the genes of genome2 into a table indexed by innovation#
	local innovations2 = {}
	for _, gene in pairs(genome2.genes) do
		innovations2[gene.innovation] = gene
	end
	
	--Randomly (50% chance) keep matching genes, and keep all disjoint genes of the more fit genome
	for _, gene1 in pairs(genome1.genes) do
		gene2 = innovations2[gene1.innovation]
		if (gene2 ~= nil) and (math.random(2) == 1) then -- the genes match
			local childGene = gene1:copy()
			if gene1.enabled and gene2.enabled then --both enabled, make child gene enabled
				childGene.enabled = true
			elseif gene1.enabled or gene2.enabled then--only 1 enabled, child has 50/50 chance
				childGene.enabled = (math.random(2) == 1)
			else --disabled in both parents, so disabled in child
				childGene.enabled = false
			end
			
			table.insert(child.genes, childGene)
		else --gene1 doesn't exist in genome2, so child inhereits gene1
			table.insert(child.genes, gene1:copy())
		end
	end
	
	--Gotta figure out the maxHiddenNeuron for dis kiddie
	local maxNeuron = 0
	local neurons = {}
	for _, gene in pairs(child.genes) do
		neurons[gene.into] = true
		neurons[gene.out] = true
	end

	for i = genome1.firstHiddenNeuron, genome1.lastHiddenNeuron do
		if neurons[i] then
			maxNeuron = i
		end
	end
	
	child.maxHiddenNeuron = maxNeuron
	
	return child
end
--**********
--/Genome
--**********

--Gene Class
-->>Represents a connection between two neurons (i.e. out of A into B)
Gene = {}
Gene.__index = Gene

--Constructor
function Gene:new()
	local gene = {}
	setmetatable(gene, Gene)
	
	gene.into = 0
	gene.out = 0
	gene.weight = 0.0
	gene.enabled = true
	gene.innovation = 0
	
	return gene
end

--Copy Constructor
function Gene:copy()
	local gene = {}
	setmetatable(gene, Gene)
	
	--print("copying inno: "..self.innovation.." out: "..self.out.." in: "..self.into)
	
	gene.into = self.into
	gene.out = self.out
	gene.weight = self.weight
	gene.enabled = self.enabled
	gene.innovation = self.innovation
	
	return gene
end

--String representation of gene
function Gene:toString()
    local state = 0
    if self.enabled then
        state = 1
    end
    return string.format("%d\t\t%d\t\t%.4f\t\t%d\t\t%d\n", g.out, g.into, g.weight, g.innovation, state)
end
--**********
--/Gene
--**********

--Network Class
Network = {}
Network.__index = Network

--Constructor
function Network:new(genome)
	local network = {}
	setmetatable(network, Network)
	
	local netParams = genome.networkParameters
	network.inputs = netParams["inputSize"]
	network.outputs = netParams["outputSize"]
	network.maxNodes = netParams["maxNodes"]
	
	network.neurons = {}
	
	--Make input neurons (numbered(id) 1 to inputs)
	for i = 1, network.inputs do
		network.neurons[i] = Neuron:new()
	end
	
	--Add the bias neuron (constant value of 1)
	network.neurons[network.inputs+1] = Neuron:new()
	
	--Make output neurons (maxnodes-outputs+1 to maxnodes)
	for i = network.maxNodes-network.outputs+1, network.maxNodes do
		network.neurons[i] = Neuron:new()
	end
	
	--sort the genes in the genome by increasing output neuron (the neuron recieving the connection)
	--Is this necessary?
	--table.sort(genome.genes, function(g1, g2) return (g1.out < g2.out) end)
	
	--create all other neurons and the connections between them
	for i = 1, tablelength(genome.genes) do
		local gene = genome.genes[i]
		if gene.enabled then
			if network.neurons[gene.out] == nil then --The source neuron hasn't been created yet
				network.neurons[gene.out] = Neuron:new()
			end
			if network.neurons[gene.into] == nil then --The destination neuron hasn't been created yet
				network.neurons[gene.into] = Neuron:new()
			end
			network.neurons[gene.into].incoming[gene.out] = gene.weight --Set the weight of the connection
		end
	end
    
	return network
end

--Get value of the output neurons given the specified input
function Network:evaluate(input)
	--Check for proper input size
	if tablelength(input) ~= self.inputs then
		LogError("Invalid input length")
		return {}
	end
	
	--table to hold the new value of each neuron
	newValues = {}
	
	--Set input neuron vals
	for i = 1, self.inputs do
		self.neurons[i].value = input[i]
	end
	
	--Set bias val
	self.neurons[self.inputs + 1].value = 1
	
	--Go through the neurons in order (1, 2, 3...max) and set their values
	for index, neuron in pairsByKeys(self.neurons) do
		local sum = 0
		for sourceNeuron, weight in pairsByKeys(neuron.incoming) do --iterate over the neurons connected to the current
			sum = sum + (weight * self.neurons[sourceNeuron].value)
		end
		
		--If the current neuron actually has connections to it, determine what its new value will be
		if tablelength(neuron.incoming) > 0 then
			newValues[index] = ReLU(sum)
		end
	end
	
	--Set the new values in each neuron
	for index, value in pairsByKeys(newValues) do
		self.neurons[index].value = value
	end
	
	--Now return the final values of the output neurons
	output = {}
	for i = self.maxNodes-self.outputs+1, self.maxNodes do
		table.insert(output, self.neurons[i].value)
	end
	
	return output
end	
--**********
--/Network
--**********

--Neuron Class
Neuron = {}
Neuron.__index = Neuron

--Constructor
function Neuron:new(id)
	local neuron = {}
	setmetatable(neuron, Neuron)
	
	neuron.incoming = {}
	neuron.value = 0.0
	neuron.id = id
	return neuron
end
--**********
--/Neuron
--**********

--tmp functions for testing
function printGenome(genome)
	print("Printing Genome")
    print("\tFitness: "..genome.fitness)
	print("\tMax Hidden Neuron: "..genome.maxHiddenNeuron)
    
    for name, val in pairsByKeys(genome.networkParameters) do
        print("\t"..name.."\t"..val)
    end
    
    for name, val in pairsByKeys(genome.evolutionParameters) do
        print("\t"..name.."\t"..val)
    end
    
	if tablelength(genome.genes) == 0 then
		print("No Genes!")
		return
	end
	
	for i, gene in pairsByKeys(genome.genes) do
		print(i)
		printGene(gene)
	end
	print()
end

function printGene(gene)
	print("\tOut from: "..gene.out)
	print("\tIn to:    "..gene.into)
	print("\tWeight:   "..gene.weight)
	print("\tInnov.:   "..gene.innovation)
	print("\tEnabled:   "..tostring(gene.enabled))
end

function printOutput(output)
	line = ""
	for _, val in pairsByKeys(output) do
		line = line .. val .. " "
	end
	print(line)
end

function poolSpeciationStats(pool)
	local genomes = {}
	for _, species in pairs(pool.species) do
		for _, genome in pairs(species.genomes) do
			table.insert(genomes, genome)
		end
	end
	
	local dMeasures = {}
	local wMeasures = {}
	for i = 1, (#genomes - 1) do
		for j = (i + 1), #genomes do
			table.insert(dMeasures, disjointMeasure(genomes[i], genomes[j]))
			table.insert(wMeasures, weightMeasure(genomes[i], genomes[j]))
		end
	end
	
	local dmin = dMeasures[1]
	local dmax = dMeasures[1]
	local dmean = 0
	for _, val in pairs(dMeasures) do
		if val < dmin then
			dmin = val
		end
		if val > dmax then
			dmax = val
		end
		dmean = dmean + val
	end
	dmean = dmean / #dMeasures
	
	local wmin = wMeasures[1]
	local wmax = wMeasures[1]
	local wmean = 0
	for _, val in pairs(wMeasures) do
		if val < wmin then
			wmin = val
		end
		if val > wmax then
			wmax = val
		end
		wmean = wmean + val
	end
	wmean = wmean / #wMeasures
	
	print("Disjoint Stats:")
	print("\tMin: "..dmin)
	print("\tMax: "..dmax)
	print("\tAve: "..dmean)
	print("Weight Stats:")
	print("\tMin: "..wmin)
	print("\tMax: "..wmax)
	print("\tAve: "..wmean)
end

function averageGenomeLength(pool)
	local allGenomes = {}
	for _, species in pairs(pool.species) do
		for _, genome in pairs(species.genomes) do
			table.insert(allGenomes, genome)
		end
	end
	
	local sum = 0
	maxG = 0
	for _, genome in pairs(allGenomes) do
		sum = sum + #genome.genes
		if #genome.genes > maxG then
			maxG = #genome.genes
		end
	end
	
	print("Counted "..#allGenomes.." genomes, ave len: "..(sum/#allGenomes).."    max: "..maxG)
end

function poolGenomeStats(pool)
	local genomes = {}
	for _, species in pairs(pool.species) do
		for _, genome in pairs(species.genomes) do
			table.insert(genomes, genome)
		end
	end
	
	local minLen = genomes[1]
	local maxLen = genomes[1]
	local sumLen = 0
	
	
	local minEnabled
	local maxEnabled
	local sumEnabled
	print("Pool Genome Stats:")
end
		

function printPool(pool)
    print("Printing pool:")
    print("\tGeneration: "..pool.generation)
    print("\tPopulation: "..pool:currentPop())
    print("\tAverage Fitness: "..pool.averageFitness)
	print("\tBest Average: "..pool.bestAverage)
	print("\tStaleness: "..pool.staleness)
	print("\tTimes Nuked: "..pool.timesNuked)
	table.sort(pool.species, function (a, b) return (a.id < b.id) end)
    for index, species in pairsByKeys(pool.species) do
        print("\t\tSpecies "..index.." ("..species.id.."):")
		print("\t\t\tAge: "..species.age)
        print("\t\t\tPopulation: "..#species.genomes)
        print("\t\t\tAverageFitness: "..species.averageFitness)
		print("\t\t\tBest Average: "..species.bestAverage)
		print("\t\t\tStaleness: "..species.staleness)
    end
   print("")
end

--Defaults
GALAGA_NET_DEFAULTS = {
	["inputSize"] = 1265,
	["outputSize"] = 3,
	["maxNodes"] = 5000
	}

GALAGA_POOL_DEFAULTS = {
	["population"] = 250,
	["evalsPerGenome"] = 15,
	["maxSpeciesStaleness"] = 15,
	["maxPoolStaleness"] = 30,
    ["genomeCullPercent"] = 0.60,
    ["speciesCullPercent"] = 0.05,
    ["minSpeciesCullAge"] = 5,
    ["maxProportionalRepop"] = 0.95,
    ["interspeciesChance"] = 0.005,
	["saveState"] = 1,
	["activeFunc"] = isGameActive,
	["fitnessFunc"] = scoreTimesAccuracy,
    ["timeoutValFunc"] = getScore,
    ["timeoutFrames"] = 1200,
	["inputFunc"] = centeredInput,
	["outputFunc"] = galagaOutputFunction,
    ["initFunc"] = galagaInit
	}
	
GALAGA_SPECIES_DEFAULTS = {
	["connectionCoeff"] = 1.0,
	["weightCoeff"] = .15,
	["speciesThreshold"] = .65,
	["crossoverChance"] = 0.75,			--Chance of mating rather than cloning
    ["targetSpeciation"] = 0.10,
    ["thresholdDelta"] = 0.01
	}
	
GALAGA_EVOLVE_DEFAULTS = {
	["mutateWeightsChance"] = 0.65,		--Chance of mutating weights
    ["affectedWeights"] = 0.05,         --Percent of weights affected
	["perturbChance"] = 0.75,          	--When mutating weights, chance of perturbing instead of assigning new value
	["stepSize"] = 0.05,			    --The amount the weights are perturbed
	["linkMutationChance"] = 0.90,		--Chance of mutating a new link (not from the bias neuron)
	["biasMutationChance"] = 0.33,		--Chance of mutating a new link (from bias neuron)
	["nodeMutationChance"] = 0.25,		--Chance of mutatign a new neuron		
	["disableMutationChance"] = 0.3,	--Chance of randomly disabling an enabled neuron	
	["enableMutationChance"] = 0.25		--Chance of randomly enabling an enabled neuron
	}
--**********
--/Defaults
--**********

-- Script
print("Setting speed")
emu.speedmode("maximum")

print("Creating pool...")
testPool = Pool:new(GALAGA_NET_DEFAULTS, GALAGA_POOL_DEFAULTS, GALAGA_EVOLVE_DEFAULTS, GALAGA_SPECIES_DEFAULTS)

print("Initializing pool")
testPool:initialize(0)
filenames = {}
for i = 1, 5 do table.insert(filenames, "genomes/16/(21)"..i..".genome") end
for _, name in pairs(filenames) do testPool:adoptGenome(Genome:readFromFile(name)) end

testPool:evaluateAllGenomes()

for i = 1, 500 do
	averageGenomeLength(testPool)
	
	print("Printing pool before call"..i.." to nextGen")
    print("Threshold: "..testPool.speciesParameters["speciesThreshold"])
	printPool(testPool)
    testPool:nextGeneration()
	
	if testPool.staleness == 0 then
		local genomes = testPool:allGenomes()
		table.sort(genomes, function (a, b) return (a.fitness > b.fitness) end)
		for j = 1, 5 do
			genomes[j]:writeToFile(string.format("genomes/16/(%d)%d.genome", i, j))
		end
	end
	
end

print("pausing")
emu.pause()

print("Setting normal speedmode")
emu.speedmode("normal")

print("Trying to play best")
testPool:playTopNet()