local sceneCanvas = lurek.render.newCanvas(800, 600)   -- off-screen render target
local effectShader = lurek.render.newShader([[         -- WGSL shader that reads from the canvas
    @group(0) @binding(0) var tex: texture_2d<f32>;
    @group(0) @binding(1) var smp: sampler;

    @fragment
    fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
        let colour = textureSample(tex, smp, uv);

        // Example: vignette
        let center = uv - vec2<f32>(0.5, 0.5);
        let dist   = length(center);
        let vignette = 1.0 - smoothstep(0.4, 0.8, dist);

        return vec4<f32>(colour.rgb * vignette, colour.a);
    }
]])

local function drawScene()
    lurek.render.clear(0.02, 0.02, 0.03)
end

function lurek.draw()
    -- Phase 1: render scene to canvas
    lurek.render.setCanvas(sceneCanvas)
    lurek.render.clear()
    drawScene()           -- all normal draw calls go here
    lurek.render.setCanvas(nil)

    -- Phase 2: draw canvas through effect shader
    lurek.render.setShader(effectShader)
    lurek.render.draw(sceneCanvas, 0, 0)
    lurek.render.setShader(nil)
end
