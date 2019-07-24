
local ceil = math.ceil
local font_ref = require "font"
local bloom

function love.load()
    love.audio.setVolume(0)

    local LINE_WIDTH = 2
    love.graphics.setLineWidth(LINE_WIDTH)
    love.graphics.setLineJoin('bevel')

    local os = love.system.getOS()
    OS_MOBILE = os == "Android" or os == "iOS"
    bloom = require "bloom"
    WINDOW_W, WINDOW_H = love.graphics.getDimensions()
    GROUND_H = WINDOW_H * 0.8
    SIZE = WINDOW_H * 0.12
    SHAPES = {
        { 0,0, 0,-SIZE, SIZE,-SIZE, SIZE,0 },
        { 0,0, SIZE/2,-SIZE, SIZE,0 },
        { 0,-0.5*SIZE, 0.25*SIZE,0, 0.75*SIZE,0, SIZE,-0.5*SIZE, 0.75*SIZE,-SIZE, 0.25*SIZE,-SIZE }
    }
    COLORS = {
        {0,1,1, 1},
        {0,1,0, 1},
        {1,0,1, 1}
    }
    PAUSE = 0
    DIE_PAUSE = 0.2
    GRAVITY = WINDOW_H * 10
    JUMP_HEIGHT = WINDOW_H * 0.5
    JUMP_VEL = math.sqrt(2*GRAVITY*JUMP_HEIGHT)
    POLY_X = WINDOW_W * 0.2
    PILLAR_SPACE = SIZE*0.25
    PILLAR_SPEED = ( (WINDOW_W+SIZE+PILLAR_SPACE)-POLY_X )
    PILLAR_INTERVAL = 1 -- seconds
    FONTSIZE = WINDOW_H * 0.02
    SCORE_X = WINDOW_W - FONTSIZE*2.5*3
    SCORE_Y = WINDOW_H * 0.82
    HISCORE_X = SCORE_X - FONTSIZE*7.5
    HISCORE_Y = SCORE_Y + FONTSIZE*3.5
    TRI_CENTER = 2/3
    SCORE_EFFECT_VEL = 12
    SCORE_EFFECT_ACCEL = 32

    sndSwitch = love.audio.newSource("res/switch.wav", "static")
    sndJump = love.audio.newSource("res/jump.wav", "static")
    sndSlide = love.audio.newSource("res/slide.wav", "static")
    sndDeath = love.audio.newSource("res/death.ogg", "static")
    sndScore = {
        love.audio.newSource("res/score1.ogg", "static"),
        love.audio.newSource("res/score2.ogg", "static")
    }

    poly = {}
    time_multiplier = 1

    local imgParticle = love.graphics.newCanvas(LINE_WIDTH, LINE_WIDTH)
    love.graphics.setCanvas(imgParticle)
    love.graphics.clear(1,1,1)
    love.graphics.setCanvas()
    psys = love.graphics.newParticleSystem(imgParticle, 64)
    psys:setEmissionArea('uniform', SIZE*0.3,0)
    local spread = 0.5
    psys:setDirection(math.pi + spread/2)
    psys:setSpread(spread) -- 1 radian
    psys:setSpeed(PILLAR_SPEED*0.6,PILLAR_SPEED*0.8)
    psys:setEmissionRate(64)
    psys:setParticleLifetime(0.4,0.6)
    psys:setColors(1,1,1,1, 1,1,1,0)
    psys:setLinearDamping(3,6)

    s_sys = love.graphics.newParticleSystem(imgParticle, 64)
    s_sys:setSpread(math.pi*2)
    s_sys:setSpeed(PILLAR_SPEED*0.3,PILLAR_SPEED*0.8)
    s_sys:setParticleLifetime(0.4,0.8)
    s_sys:setColors(1,1,1,1, 1,1,1,0)
    s_sys:setLinearDamping(8,12)
    s_sys_y = GROUND_H - SIZE/2

    hi_score = 0
    local info = love.filesystem.getInfo("polydata.lua")
    if info then
        local func, err = love.filesystem.load("polydata.lua")
        if not err then func() end
    end

    font = {}
    font_title = {}
    for k1,c in pairs(font_ref) do
        for k2,lines in ipairs(c) do
            if not font[k1] then font[k1] = {} end
            if not font_title[k1] then font_title[k1] = {} end
            font[k1][k2] = resize(lines, FONTSIZE)
            font_title[k1][k2] = resize(lines, SIZE/2)
        end
    end

    require "intro"
end

function update(dt)
    if dt > 0.1 then dt = 0 end
    dt = dt*time_multiplier
    time = time + dt
    if gameState == 'title' then
        poly.rot = poly.rot + poly.rotv*dt
    elseif time_pause_done <= time then
        if time > musicDelay and not deathPillar then
            music:play()
        end
        if not poly.grounded then
            poly.yv = poly.yv + poly.ya*dt/2
            poly.y = poly.y + poly.yv*dt
            poly.yv = poly.yv + poly.ya*dt/2
            poly.rot = poly.rot + poly.rotv*dt
            if poly.y > GROUND_H then
                poly.y = GROUND_H
                poly.grounded = true
                poly.rot = 0
                psys:start()
                psys:emit(32)
                sndSlide:play()
            end
        end
        if time >= timeNextPillar and score ~= next_level_score then
            timeNextPillar = timeNextPillar + PILLAR_INTERVAL
            newPillar()
        end
        local remove
        for i,p in ipairs(pillars) do
            p.x = p.x - speed*dt
            if not deathPillar and not p.timeScored and ( p.x - speed*dt/2 <= poly.x ) then
                if p.state == poly.state and ( ( p.height==1 and poly.grounded ) or ( p.height==2 and not poly.grounde and poly.will_score ) ) then
                    p.timeScored = time
                    time_pause_done = time + real_pause
                    score = score + 1
                    if score > hi_score then
                        hi_score = score
                        new_hi_score = true
                    end
                    p.scaleVel = SCORE_EFFECT_VEL
                    sndScore[p.height]:play()
                    s_sys_y = p.y - SIZE/2
                    s_sys:emit(64)
                else
                    gameState = 'over'
                    deathPillar = p
                    deathTime = time
                    if new_hi_score then
                        love.filesystem.write("polydata.lua", "hi_score="..hi_score)
                    end
                    time_pause_done = time + DIE_PAUSE
                    music:stop()
                    sndDeath:play()
                end
            end
            if p.scaleVel then p.scaleVel = p.scaleVel - SCORE_EFFECT_ACCEL*dt end
            if p.x < -SIZE-PILLAR_SPACE then remove = i end
        end
        if remove then table.remove(pillars, remove) end
        if deathPillar then
            poly.x = deathPillar.x
        end
    end

    if score == next_level_score then
        nextLevel()
    end

    psys:update(dt)
    s_sys:update(dt)
end

function draw()
    bloom.preDraw()

    love.graphics.print("FPS: "..love.timer.getFPS(), 10,10)

    love.graphics.setColor(1,1,1)
    love.graphics.line(0,GROUND_H, WINDOW_W,GROUND_H)

    love.graphics.setColor(COLORS[poly.state])
    love.graphics.push()
    local tri = poly.state==2 and TRI_CENTER or 1
    love.graphics.translate(poly.x+SIZE/2, poly.y-SIZE/2*tri)
    love.graphics.rotate(poly.rot)
    love.graphics.translate(-SIZE/2, SIZE/2*tri)
    love.graphics.polygon("line", SHAPES[poly.state])
    love.graphics.pop()

    love.graphics.draw(psys, poly.x+SIZE/2,GROUND_H)

    printFont(""..score, SCORE_X, SCORE_Y)
    love.graphics.setColor(1, 1, 1)
    printFont("hi "..hi_score, HISCORE_X, HISCORE_Y)
    if deathPillar then
        printFont("game over", WINDOW_W/2-FONTSIZE*12, SCORE_Y)
    end

    if gameState == 'title' then
        printFont("p lygon", POLY_X-SIZE, poly.y-SIZE, true)
    elseif gameState == 'main' and time < time_multiplier then
        printFont("level "..current_level, WINDOW_W/2-FONTSIZE*10, SCORE_Y)
    end

    for i,p in ipairs(pillars) do
        local front_end = p.x-PILLAR_SPACE
        local back_end = p.x+SIZE+PILLAR_SPACE
        love.graphics.setColor(1,1,1)
        love.graphics.line( front_end,0, front_end,GROUND_H)
        love.graphics.line( back_end,0, back_end,GROUND_H)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        if p.timeScored then
            love.graphics.setColor(COLORS[p.state])
            love.graphics.polygon('line', SHAPES[p.state])
            local scale = (time - p.timeScored) * p.scaleVel
            local centered = SIZE*scale/2
            local tri = p.state==2 and TRI_CENTER or 1
            love.graphics.draw(s_sys, poly.x-p.x+SIZE/2,-SIZE/2*tri)
            love.graphics.translate(-centered, centered*tri)
            love.graphics.polygon('line', resize(SHAPES[p.state], scale+1))
        else
            love.graphics.polygon('line', SHAPES[p.state])
        end
        love.graphics.pop()
    end

    if OS_MOBILE then
        love.graphics.push()
        love.graphics.translate(SIZE/2,SIZE*1.5)
        for i=1,3 do
            if poly.state == i then
                love.graphics.setColor(COLORS[poly.state])
            else
                love.graphics.setColor(1,1,1)
            end
            love.graphics.polygon('line', SHAPES[i])
            love.graphics.translate(0,GROUND_H*0.333)
        end
        love.graphics.pop()
    end
    bloom.postDraw()
end

function love.keypressed(key)
    if gameState == 'main' then
        if key=='space' then jump()
        elseif key=='s' then setState(1)
        elseif key=='d' then setState(2)
        elseif key=='f' then setState(3)
        end
    elseif gameState == 'over' then
        if key == 'space' then start() end
    elseif gameState == 'title' then
        if key=='space' then start()
        elseif key=='s' then setState(1)
        elseif key=='d' then setState(2)
        elseif key=='f' then setState(3)
        end
    end
    if key=='r' then start()
    elseif key=='escape' then love.event.quit()
    elseif key=='6' then love.event.quit('restart')
    end
end

function love.touchpressed(id, x, y)
    if gameState == 'main' then
        if x > WINDOW_W/2 then jump()
        elseif y < GROUND_H*0.333 then setState(1)
        elseif y < GROUND_H*0.666 then setState(2)
        elseif y < GROUND_H then setState(3)
        end
    elseif gameState == 'over' then
        if time-deathTime > 0.2 then start() end
    elseif gameState == 'title' then
        if x > WINDOW_W/2 then start()
        elseif y < GROUND_H*0.333 then setState(1)
        elseif y < GROUND_H*0.666 then setState(2)
        elseif y < GROUND_H then setState(3)
        end
    end
end

function title()
    gameState = 'title'
    poly.y = GROUND_H - JUMP_HEIGHT
    poly.state = 1
    poly.x = POLY_X
    poly.rot = 0
    poly.rotv = 3
    poly.grounded = false
    poly.ya = GRAVITY
    pillars = {}
    psys:stop()
    score = 0
    time = 0
end

function start()
    if gameState ~= 'title' then
        poly.state = 1
        poly.x = POLY_X
        poly.y = GROUND_H
        poly.ya = GRAVITY
        poly.grounded = true
        poly.rot = 0
        poly.rotv = 0
        psys:start()
    end
    poly.yv = 0
    poly.will_score = true

    time = 0
    timeNextPillar = time + PILLAR_INTERVAL
    gameState = 'main'
    score = 0
    deathPillar = false
    real_pause = PAUSE/time_multiplier
    time_pause_done = 0
    current_level = 1
    level[1]()

    new_hi_score = false

    pillars = {}
end

function newPillar()
    local _state = ceil(love.math.random()*3)
    local _height = ceil(love.math.random()*2)
    local p = {
        state = _state,
        height = _height,
        x = WINDOW_W + SIZE+PILLAR_SPACE,
        y = _height==1 and GROUND_H or GROUND_H - JUMP_HEIGHT,
        timeScored = false
    }
    pillars[#pillars+1] = p
end

function setState(state)
    local previous = poly.state
    if state ~= previous then
        poly.state = state
        sndSwitch:stop()
        sndSwitch:play()
    end
end

function jump()
    if poly.grounded then
        if #pillars == 0 then
            poly.ya = GRAVITY
        else
            local p = pillars[1].x < poly.x and pillars[2] or pillars[1]
            local t = (p.x-poly.x)/speed
            poly.ya = (-2*(JUMP_HEIGHT-JUMP_VEL*t))/t^2
            if poly.ya < GRAVITY*0.3 then
                 poly.ya = GRAVITY*0.3
                 poly.will_score = false
            end
            poly.rotv = p.state==2 and math.pi*2/t or math.pi/t
        end
        poly.yv = -JUMP_VEL
        poly.grounded = false
        psys:emit(32)
        psys:stop()
        sndJump:stop()
        sndSlide:stop()
        sndJump:play()
    end
end

function nextLevel()
    current_level = current_level + 1
    level[current_level]()
    time_pause_done = time_pause_done - time - time_multiplier
    time = - time_multiplier
    timeNextPillar = PILLAR_INTERVAL
end

level = {
    function ()
        music = love.audio.newSource("res/holes.xm", "stream")
        musicDelay = 1.5
        time_multiplier = 1
        next_level_score = 41
        speed = PILLAR_SPEED
    end,
    function ()
        music:stop()
        music = love.audio.newSource("res/pillars.xm", "stream")
        musicDelay = 2.5
        time_multiplier = 1.5
        next_level_score = math.huge
        speed = PILLAR_SPEED / 1.5
    end
}

function printFont(text, x,y, title)
    local f = title and font_title or font
    local space = title and SIZE*1.25 or FONTSIZE*2.5
    love.graphics.push()
    love.graphics.translate(x,y)
    for c in text:gmatch('.') do
        if c ~= ' ' then
            for _,t in ipairs(f[c]) do
                love.graphics.line(t)
            end
        end
        love.graphics.translate(space,0)
    end
    love.graphics.pop()
end

function resize(t, size)
    local new = {}
    for i=1,#t do
        new[i] = t[i]*size
    end
    return new
end
