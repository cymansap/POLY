
local ceil = math.ceil
local font = require "font"

function love.load()
    local LINE_WIDTH = 2
    love.graphics.setLineWidth(LINE_WIDTH)

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
    PAUSE = 0.1
    GRAVITY = WINDOW_H * 8
    JUMP_HEIGHT = WINDOW_H * 0.5
    JUMP_VEL = math.sqrt(2*GRAVITY*JUMP_HEIGHT)
    PILLAR_SPACE = SIZE*0.25
    PILLAR_SPEED = ( (WINDOW_W+SIZE+PILLAR_SPACE)-WINDOW_W*0.17 ) / (1-PAUSE)
    PILLAR_INTERVAL = 1 -- seconds
    FONTSIZE = WINDOW_H * 0.02
    SCORE_X = WINDOW_W - FONTSIZE*2.5*3
    SCORE_Y = WINDOW_H * 0.82
    HISCORE_X = SCORE_X - FONTSIZE*7.5
    HISCORE_Y = SCORE_Y + FONTSIZE*3.5

    sndSwitch = love.audio.newSource("res/switch.wav", "static")
    sndJump = love.audio.newSource("res/jump.wav", "static")
    sndSlide = love.audio.newSource("res/slide.wav", "static")
    sndDeath = love.audio.newSource("res/death.ogg", "static")
    sndScore = {
        love.audio.newSource("res/score1.ogg", "static"),
        love.audio.newSource("res/score2.ogg", "static")
    }

    poly = {}

    local imgParticle = love.graphics.newCanvas(LINE_WIDTH, LINE_WIDTH)
    love.graphics.setCanvas(imgParticle)
    love.graphics.clear(1,1,1)
    love.graphics.setCanvas()
    psys = love.graphics.newParticleSystem(imgParticle, 64)
    psys:setEmissionArea('uniform', SIZE*0.3,0)
    local spread = 0.5
    psys:setDirection(math.pi + spread/2)
    psys:setSpread(spread) -- 1 radian
    psys:setSpeed(PILLAR_SPEED*0.4,PILLAR_SPEED*0.6)
    psys:setEmissionRate(64)
    psys:setParticleLifetime(0.4,0.6)
    psys:setColors(1,1,1,1, 1,1,1,0)

    hi_score = 0
    local info = love.filesystem.getInfo("polydata.lua")
    if info then
        local func, err = love.filesystem.load("polydata.lua")
        if not err then func() end
    end

    start()
end

function love.update(dt)
    if dt>PAUSE then dt = 0 end
    time = time + dt
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
    if time >= timeNextPillar then
        timeNextPillar = timeNextPillar + PILLAR_INTERVAL
        newPillar()
    end
    local remove
    for i,p in ipairs(pillars) do
        p.x = p.x - PILLAR_SPEED*dt
        if not deathPillar and not p.timeScored and p.x <= poly.x then
            if p.state == poly.state and ( ( p.height==1 and poly.grounded ) or ( p.height==2 and not poly.grounded) ) then
                p.timeScored = time
                love.timer.sleep(PAUSE)
                score = score + 1
                if score > hi_score then
                    hi_score = score
                    new_hi_score = true
                end
                sndScore[p.height]:play()
            else
                gameState = 'over'
                deathPillar = p
                p.timeScored = time
                if new_hi_score then
                    love.filesystem.write("polydata.lua", "hi_score="..hi_score)
                end
                love.timer.sleep(0.2)
                sndDeath:play()
            end
        end
        if p.x < -SIZE-PILLAR_SPACE then remove = i end
    end
    if remove then table.remove(pillars, remove) end
    if deathPillar then
        poly.x = deathPillar.x
    end

    psys:update(dt)
end

function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.line(0,GROUND_H, WINDOW_W,GROUND_H)

    love.graphics.setColor(COLORS[poly.state])
    love.graphics.push()
    love.graphics.translate(poly.x+SIZE/2, poly.y-SIZE/2)
    love.graphics.rotate(poly.rot)
    love.graphics.translate(-SIZE/2, SIZE/2)
    love.graphics.polygon("line", SHAPES[poly.state])
    love.graphics.pop()

    love.graphics.draw(psys, poly.x+SIZE/2,GROUND_H)

    printFont(""..score, SCORE_X, SCORE_Y)
    love.graphics.setColor(1, 1, 1)
    printFont("hi "..hi_score, HISCORE_X, HISCORE_Y)

    for i,p in ipairs(pillars) do
        local front_end = p.x-PILLAR_SPACE
        local back_end = p.x+SIZE+PILLAR_SPACE
        love.graphics.setColor(1,1,1)
        love.graphics.line( front_end,0, front_end,GROUND_H)
        love.graphics.line( back_end,0, back_end,GROUND_H)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.polygon('line', SHAPES[p.state])
        love.graphics.pop()
    end
end

function love.keypressed(key)
    if gameState == 'main' then
        if key=='space' then jump()
        elseif key=='s' then setState(1)
        elseif key=='d' then setState(2)
        elseif key=='f' then setState(3)
        end
    end
    if key=='r' then start()
    elseif key=='escape' then love.event.quit()
    end
end

function start()
    poly.state = 1
    poly.x = WINDOW_W * 0.17
    poly.y = GROUND_H
    poly.yv = 0
    poly.grounded = true
    poly.rot = 0
    poly.rotv = 0
    psys:start()

    time = 0
    timeNextPillar = time + PILLAR_INTERVAL
    gameState = 'main'
    score = 0
    deathPillar = false

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
            local t = (p.x-poly.x)/PILLAR_SPEED
            poly.ya = (-2*(JUMP_HEIGHT-JUMP_VEL*t))/t^2
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

function printFont(text, x,y, size)
    local size = size or FONTSIZE
    love.graphics.push()
    love.graphics.translate(x,y)
    for c in text:gmatch('.') do
        if c ~= ' ' then
            for _,t in ipairs(font[c]) do
                love.graphics.line( resize(t, size) )
            end
        end
        love.graphics.translate(FONTSIZE*2.5,0)
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
