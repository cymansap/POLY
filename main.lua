
function love.load()
    love.graphics.setLineWidth(2)

    WINDOW_W, WINDOW_H = love.graphics.getDimensions()
    GROUND_H = WINDOW_H * 0.8
    SIZE = WINDOW_W * 0.08
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

    poly = {}

    start()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(0,GROUND_H, WINDOW_W,GROUND_H)
    love.graphics.setColor(COLORS[poly.state])
    love.graphics.push()
    love.graphics.translate(poly.x, poly.y)
    love.graphics.polygon("line", SHAPES[poly.state])
    love.graphics.pop()
end

function start()
    poly.state = 1
    poly.x = WINDOW_W * 0.17
    poly.y = GROUND_H
end

function setState(state)
    poly.state = state
end

function love.keypressed(key)
    if key=='s' then setState(1)
    elseif key=='d' then setState(2)
    elseif key=='f' then setState(3)
    end
end
