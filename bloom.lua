
-- pretty much stolen from https://learnopengl.com/Advanced-Lighting/Bloom
-- i can't figure out who wrote that though so uh thanks whoever

local bloom = {}

if not OS_MOBILE then

local blur = love.graphics.newShader [[
float weight[9] = float[] (0.13298,0.125858,0.106701,0.081029,0.055119,0.033585,0.018331,0.008962,0.003924);
float size_x = 1 / love_ScreenSize.x;
float size_y = 1 / love_ScreenSize.y;
extern bool x;
vec4 effect(vec4 color, Image tex, vec2 coords, vec2 _)
{
    vec3 c = Texel(tex, coords).rgb * weight[0];

    if (x)
    {
        for (int i=0; i<9; ++i)
        {
            c += Texel(tex, coords + vec2(i*size_x, 0.0)).rgb * weight[i];
            c += Texel(tex, coords - vec2(i*size_x, 0.0)).rgb * weight[i];
        }
    }
    else
    {
        for (int i=0; i<9; ++i)
        {
            c += Texel(tex, coords + vec2(0.0, i*size_y)).rgb * weight[i];
            c += Texel(tex, coords - vec2(0.0, i*size_y)).rgb * weight[i];
        }
    }

    return vec4(c, 1.0) * color;
}
]]

local can = love.graphics.newCanvas()
local can_blury = love.graphics.newCanvas()

function bloom.preDraw()
    love.graphics.setCanvas(can)
    love.graphics.clear()
end

function bloom.postDraw()
    love.graphics.setCanvas(can_blury)
    love.graphics.setShader(blur)
    blur:send('x', true)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(can, 0,0)

    love.graphics.setCanvas()
    blur:send('x', false)
    love.graphics.draw(can_blury, 0,0)

    love.graphics.setShader()
    love.graphics.draw(can, 0,0)
end

else -- if OS_MOBILE

function bloom.preDraw() end
function bloom.postDraw() end

end

return bloom
