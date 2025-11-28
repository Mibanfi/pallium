function love.load()
    love.window.setTitle("Pallium")
    
    Player = {}
    Player.x = 400
    Player.y = 400
    Player.prevX = 400
    Player.prevY = 400
    Player.speed = 500
    Player.jump = 1000
    Player.fall = 2000
    Player.velocity = {}
    Player.velocity.v = 0
    Player.velocity.h = 0
    Player.size = 30
    Player.coreSize = 5
    Player.hasWallJump = true
    Player.momentum = true
    Player.parryWindow = 30
    Player.aura = 0
    Player.boost = 0
    Player.invincibility = 0
    
    DeathToll = false
    
    Gravity = 2000
    Floor = love.graphics.getHeight() - 100
    
    Shake = 0
    ShakeDuration = 1
    ShakeMagnitude = 10

    Obstacles = {}
    FallSpeed = 800
    Step = 0
    SpawnPoint = {400, Floor}
    DespawnPoint = -100
    Mode = 1
    Difficulty = 0

    Finished = true
    Played = false
    Freeze = 0
    Time = 0
    Level = 0
    Start = 0

    Fullscreen = false
    love.graphics.setDefaultFilter( "nearest" )
    
	Colors = {
		{love.math.colorFromBytes(96, 130, 182)},	--1 BLUE
		{love.math.colorFromBytes(248, 200, 220)},	--2 PINK
		{love.math.colorFromBytes(147, 197, 114)},	--3 GREEN
		{love.math.colorFromBytes(233, 116, 81)},	--4 RED
		{love.math.colorFromBytes(207, 159, 255)},	--5 PURPLE
		{love.math.colorFromBytes(251, 236, 93)},	--6 YELLOW
		{love.math.colorFromBytes(221,133,215)},	--7 PURPLER
		{love.math.colorFromBytes(255, 117, 24)},	--8 ORANGE
		{love.math.colorFromBytes(225, 193, 110)},	--9 BROWN
		{1, 1, 1}	--10 WHITE
	}
	
	Afterimages = {}
	AfterimagesSize = 30
	AfterimagesDuration = 0.2
	AfterimagesWallSize = 60
	AfterimagesWallDuration = 0.2
	
	ModeNames = {
		"I: HIDDEN";
		"II: HARD",
		"III: HECTIC",
		"IV: HYPER",
		"V: HELL"
	}
	
	Roman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
end

function love.update(dt)
	if DeathToll and Player.invincibility <= 0 then
		Freeze = 1
        Finished = true
        Played = true
	end
	DeathToll = false
    if Freeze > 0 then
    		Freeze = Freeze - dt
    		return
    end
    
    if Freeze <= 0 then
    		Freeze = 0
    end
    
    if Finished then
        return
    end
    	
    	if Shake > 0 then
        Shake = Shake - dt
    end
    
    local interval = 1-0.01*math.min(Level, 50)
    if Mode > 1 then
    		interval = interval - 0.1 * (Mode - 1)
    	end
    	if interval <= 0.1 then
    		interval = 0.1
    	end
    	Difficulty = 10 - math.ceil(interval*10)
    	

    Time = love.timer.getTime() - Start

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        	Player.x = Player.x - Player.speed * dt
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        Player.y = Player.y + Player.fall * dt
        	Player.boost = 0.2
        if Player.velocity.v <= 0 then
        		Player.velocity.v = 0
        	end
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        	Player.x = Player.x + Player.speed * dt
    end
    if Player.velocity.v < 1000 then
        Player.velocity.v = Player.velocity.v + Gravity * dt
    end
    
    Player.y = Player.y + Player.velocity.v * dt
    Player.x = Player.x + Player.velocity.h * dt
    Player.aura = math.max(0, Player.aura - dt)
    Player.boost = math.max(Player.boost-dt, 0)
    Player.invincibility = math.max(Player.invincibility-dt, 0)
    
    if Player.y >= Floor - Player.size then
        Player.y = Floor - Player.size
        Player.hasWallJump = true
        Player.boost = 0
    end
    if Player.y < 0 then
        Player.y = 0
    end
    if Player.x < 0 then
        Player.x = 0
    end
    if Player.x > love.graphics.getWidth() then
        Player.x = love.graphics.getWidth()
    end

    if Time - Step > interval then
        local newObstacle = {}
        newObstacle.width = love.math.random(20, 100)
        newObstacle.height = love.math.random(80, 120)
        newObstacle.x, newObstacle.y = love.graphics.getWidth(), Floor - newObstacle.height
        newObstacle.speed = love.math.random(1, 10) * 50
        newObstacle.broken = false
        table.insert(Obstacles, newObstacle)
        Step = Time
    end
    
    if Message ~= nil and Message.timer > 0 then
    		Message.timer = Message.timer - dt
    end
    
    table.insert(Afterimages, {x = Player.x, y = Player.y, size = AfterimagesSize, timer = AfterimagesDuration, duration = AfterimagesDuration})
    for i, a in pairs(Afterimages) do
    		a.timer = a.timer - dt
    		if a.timer <= 0 then
    			table.remove(Afterimages, i)
    		end
    end

    for i, o in pairs(Obstacles) do
        o.x = o.x - o.speed * dt
        if o.broken and o.y <= Floor then
        		o.y = o.y + FallSpeed * dt
        end
        if o.x < DespawnPoint then
        		if o.broken then
        			Level = Level + 2
        		else
        			Level = Level + 1
        		end
            table.remove(Obstacles, i)
        end
        if o.broken == false and o.x < Player.x and o.x + o.width > Player.x and o.y < Player.y then
        		DeathToll = true
            return
        end
    end
end

function love.keypressed(key)
    if key == "return" and Finished then
        love.load()
        Finished = false
        Start = love.timer.getTime()
        return
    end
    if key == "space" then
        if Player.y == Floor - Player.size then
            Player.velocity.v = -Player.jump
        elseif Player.hasWallJump and (Player.x == 0 or Player.x == love.graphics.getWidth()) then
            Player.hasWallJump = false
            Player.velocity.v = -Player.jump
            table.insert(Afterimages, {x = Player.x, y = Player.y, size = AfterimagesWallSize, timer = AfterimagesWallDuration, duration = AfterimagesWallDuration})
            if Player.x == love.graphics.getWidth() and Mode < 5 then
            		Mode = Mode + 1
            		Player.speed = Player.speed + 25
            		Player.jump = Player.jump + 20
            		Player.fall = Player.fall + 100
            		Player.size = Player.size - 5
            		Message = {timer = 1, text=ModeNames[Mode] .. " MODE"}
            end
        else
        		for i, o in pairs(Obstacles) do
        			if o.x < Player.x + Player.size and o.x + o.width > Player.x - Player.size and o.y - Player.y >= 0 and o.y - (Player.y + Player.size) < Player.parryWindow  then
        				Player.invincibility = 1
        				if Player.boost <= 0 then
        					Player.velocity.v = -Player.jump
        					o.broken = true
        					Player.hasWallJump = true
        					Player.aura = 1
        				else
        					Shake = ShakeDuration
        					for i, o in pairs(Obstacles) do
        						o.broken = true
        					end
        				end
        			end
            end
        end
    end
    
    	if key == "1" then
    		love.graphics.setColor(Colors[1])
	end
	if key == "2" then
    		love.graphics.setColor(Colors[2])
	end
	if key == "3" then
    		love.graphics.setColor(Colors[3])
	end
	if key == "4" then
    		love.graphics.setColor(Colors[4])
	end
	if key == "5" then
    		love.graphics.setColor(Colors[5])
	end
	if key == "6" then
    		love.graphics.setColor(Colors[6])
	end
	if key == "7" then
    		love.graphics.setColor(Colors[7])
	end
	if key == "8" then
    		love.graphics.setColor(Colors[8])
	end
	if key == "9" then
    		love.graphics.setColor(Colors[9])
	end
	if key == "0" then
    		love.graphics.setColor(Colors[10])
    end

    if key == "f4" then
        Fullscreen = not Fullscreen
        love.window.setFullscreen(Fullscreen)
    end
end

function love.draw()

	if Shake > 0 then
        local dx = love.math.random(-ShakeMagnitude, ShakeMagnitude)
        local dy = love.math.random(-ShakeMagnitude, ShakeMagnitude)
        love.graphics.translate(dx, dy)
    end

    local h = love.graphics.getHeight()
    local w = love.graphics.getWidth()

    if Finished and Freeze <= 0 then
        if Played then
            love.graphics.printf("Time: " .. Time, 0, h/2-30, w, "center")
            love.graphics.printf("Level: " ..Level, 0, h/2-60, w, "center")
            if Mode > 1 then
        			love.graphics.printf(ModeNames[Mode], 0, h/2-90, w, "center")
        		end
        		love.graphics.printf("Score: "..math.floor(Time)+Mode*Level, 0, h/2, w/2, "center", 0, 2)
        	end
        love.graphics.printf("Press Enter to play", 0, h/2+50, w, "center")
        love.graphics.printf("f4 to toggle fullscreen", 0, h/2+80, w, "center")
        love.graphics.printf("Number keys to change color", 0, h/2+100, w, "center")
        if Mode > 1 then
        		love.graphics.printf("Wall-jump against the right wall to unlock HARD MODE", 0, h/2+150, w, "center")
        end
        love.graphics.printf("WASD or arrow keys to move", 0, 10, w, "center")
    		love.graphics.printf("Hold down or S to drop quickly", 0, 30, w, "center")
    		love.graphics.printf("Space to jump", 0, 50, w, "center")
    		love.graphics.printf("You can wall jump once before landing", 0, 70, w, "center")
    		love.graphics.printf("Bounce off blocks by jumping right before impact", 0, 90, w, "center")
    		love.graphics.printf("Bounce right after dropping to clear the screen", 0, 110, w, "center")
    else

	if Player.invincibility <= 0 then
    		love.graphics.circle("fill", Player.x, Player.y, Player.size)
    	else
    		love.graphics.circle("line", Player.x, Player.y, Player.size)
    	end
    if Player.aura > 0 then
    		love.graphics.circle("line", Player.x, Player.y, (Player.size + Player.parryWindow) * Player.aura)
    end
    for i, a in pairs(Afterimages) do
    		love.graphics.circle("line", a.x, a.y, a.size * (a.timer / a.duration))
    end
    
    for i, o in pairs(Obstacles) do
    		local method
    		if o.broken then
    			method = "fill"
    		else
    			method = "line"
    		end
        love.graphics.rectangle(method, o.x, o.y, o.width, o.height)
    end
    
    love.graphics.line(0, Floor, love.graphics.getWidth(), Floor)
    love.graphics.rectangle("line", 1, 1, love.graphics.getWidth()-1, love.graphics.getHeight()-1)

    love.graphics.print("Time: " .. Time, 10, 10)
    love.graphics.print("Level: " .. Level, 10, 30)
    if Mode == 1 then
    		love.graphics.print("Difficulty: " .. Difficulty, 10, 50)
    	elseif Mode > 1 then
    		love.graphics.print("Difficulty: " .. Difficulty .. " (" .. ModeNames[Mode] .. ")", 10, 50)
    end
    love.graphics.print("WASD or arrow keys to move", 10, 70)
    love.graphics.print("Hold down or S to drop quickly", 10, 90)
    love.graphics.print("Space to jump; you can wall jump once before landing", 10, 110)
    love.graphics.print("Bounce off blocks by jumping right before impact", 10, 130)
    love.graphics.print("Bounce right after dropping to clear the screen", 10, 150)
    love.graphics.printf("PALLIUM", -10, 10, w/2, "right", 0, 2)
    
    if Message ~= nil and Message.timer > 0 then
    		love.graphics.printf(Message.text, 0, h/2, w/2, "center", 0, 2)
    end
    
	end
end
