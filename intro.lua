
local bloom = require "bloom"

local lines = { {2,0, 0,1}, {2+2.5,0, 0+2.5,2}, {0,1, 2,2}, {0+2.5,0, 1+2.5,1} }
for i,line in ipairs(lines) do
    lines[i] = resize( line, SIZE/2 )
end

local VELOCITY = WINDOW_H*WINDOW_W/4000
local sixteenth = 60 / 100 -- bpm 100
local LIST = {0.5,0.5+sixteenth,0.5+sixteenth*2,0.5+sixteenth*3}
local time = 0
local LENGTH = sixteenth * 7
local played = false

local dir = {1.2,-0.6, -1,1, -1.2,-0.6, 1,1}

local sndIntro = love.audio.newSource("res/cy.xm", "stream")

function love.update(dt)
    time = time + dt
    if not played and time > 0.5 then
        sndIntro:play()
        played = true
    end
    if time > LENGTH then
        love.update = update
        love.draw = draw
        title()
    end
end

function love.draw()
    bloom.preDraw()
    love.graphics.push()
    love.graphics.translate(WINDOW_W/2-SIZE*1.125, WINDOW_H/2-SIZE/2)
    for i,line in ipairs(lines) do
        local t = LIST[i] - time
        if t < 0 then t = 0 end
        local e = (i-1)*2+1
        love.graphics.push()
        love.graphics.translate(VELOCITY*t*dir[e], VELOCITY*t*dir[e+1])
        love.graphics.line(line)
        love.graphics.pop()
    end
    love.graphics.pop()
    bloom.postDraw()
end
