local sceneCanvas   -- off-screen render target
local effectShader  -- WGSL shader that reads from the canvas

function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()
    sceneCanvas = lurek.gfx.newCanvas(w, h)

    effectShader = lurek.gfx.newShader([[
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
end

function lurek.render()
    -- Phase 1: render scene to canvas
    lurek.gfx.setCanvas(sceneCanvas)
    lurek.gfx.clear()
    drawScene()           -- all normal draw calls go here
    lurek.gfx.setCanvas(nil)

    -- Phase 2: draw canvas through effect shader
    lurek.gfx.setShader(effectShader)
    lurek.gfx.draw(sceneCanvas, 0, 0)
    lurek.gfx.setShader(nil)
end
