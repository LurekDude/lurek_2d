local sceneCanvas, blurH, blurV  -- three render targets

function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()
    sceneCanvas = lurek.render.newCanvas(w, h)
    blurH       = lurek.render.newCanvas(w, h)
    blurV       = lurek.render.newCanvas(w, h)
    blurHShader = lurek.render.newShader(BLUR_H_WGSL)
    blurVShader = lurek.render.newShader(BLUR_V_WGSL)
end

function lurek.render()
    -- Pass 1: scene → sceneCanvas
    lurek.render.setCanvas(sceneCanvas) ; drawScene() ; lurek.render.setCanvas(nil)

    -- Pass 2: horizontal blur
    lurek.render.setCanvas(blurH)
    lurek.render.setShader(blurHShader)
    lurek.render.draw(sceneCanvas, 0, 0)
    lurek.render.setCanvas(nil) ; lurek.render.setShader(nil)

    -- Pass 3: vertical blur → screen
    lurek.render.setShader(blurVShader)
    lurek.render.draw(blurH, 0, 0)
    lurek.render.setShader(nil)
end
