local sceneCanvas, blurH, blurV  -- three render targets

function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()
    sceneCanvas = lurek.gfx.newCanvas(w, h)
    blurH       = lurek.gfx.newCanvas(w, h)
    blurV       = lurek.gfx.newCanvas(w, h)
    blurHShader = lurek.gfx.newShader(BLUR_H_WGSL)
    blurVShader = lurek.gfx.newShader(BLUR_V_WGSL)
end

function lurek.render()
    -- Pass 1: scene → sceneCanvas
    lurek.gfx.setCanvas(sceneCanvas) ; drawScene() ; lurek.gfx.setCanvas(nil)

    -- Pass 2: horizontal blur
    lurek.gfx.setCanvas(blurH)
    lurek.gfx.setShader(blurHShader)
    lurek.gfx.draw(sceneCanvas, 0, 0)
    lurek.gfx.setCanvas(nil) ; lurek.gfx.setShader(nil)

    -- Pass 3: vertical blur → screen
    lurek.gfx.setShader(blurVShader)
    lurek.gfx.draw(blurH, 0, 0)
    lurek.gfx.setShader(nil)
end
