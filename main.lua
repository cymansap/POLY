
local ceil = math.ceil

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
    GRAVITY = WINDOW_H * 8
    JUMP_HEIGHT = WINDOW_H * 0.5
    JUMP_VEL = math.sqrt(2*GRAVITY*JUMP_HEIGHT)
    PILLAR_SPACE = SIZE*0.25
    PILLAR_SPEED = (WINDOW_W+SIZE)-WINDOW_W*0.17
    PILLAR_INTERVAL = 1 -- seconds

    sndSwitch = love.audio.newSource("res/switch.wav", "static")
    sndJump = love.audio.newSource("res/jump.wav", "static")
    sndSlide = love.audio.newSource("res/slide.wav", "static")

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

    start()
end

function love.update(dt)
    time = time + dt
    if not poly.grounded then
        poly.yv = poly.yv + GRAVITY*dt/2
        poly.y = poly.y + poly.yv*dt
        poly.yv = poly.yv + GRAVITY*dt/2
        if poly.y > GROUND_H then
            poly.y = GROUND_H
            poly.grounded = true
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
        if p.x < -SIZE-PILLAR_SPACE then remove = i end
    end
    if remove then table.remove(pillars, remove) end

    psys:update(dt)
end

function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.line(0,GROUND_H, WINDOW_W,GROUND_H)

    love.graphics.setColor(COLORS[poly.state])
    love.graphics.push()
    love.graphics.translate(poly.x, poly.y)
    love.graphics.polygon("line", SHAPES[poly.state])
    love.graphics.pop()

    love.graphics.draw(psys, poly.x+SIZE/2,GROUND_H)

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
    if key=='space' then jump()
    elseif key=='s' then setState(1)
    elseif key=='d' then setState(2)
    elseif key=='f' then setState(3)
    end
end

function start()
    poly.state = 1
    poly.x = WINDOW_W * 0.17
    poly.y = GROUND_H
    poly.yv = 0
    poly.grounded = true

    time = 0
    timeNextPillar = time + PILLAR_INTERVAL
    gameState = 'main'

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
        poly.yv = -JUMP_VEL
        poly.grounded = false
        psys:emit(32)
        psys:stop()
        sndJump:stop()
        sndSlide:stop()
        sndJump:play()
    end
end
