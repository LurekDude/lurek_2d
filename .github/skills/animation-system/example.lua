-- in luna.update(dt):
anim.frame_timer = anim.frame_timer + dt
if anim.frame_timer >= anim.frame_duration then
    anim.frame_timer = anim.frame_timer - anim.frame_duration
    anim.current_frame = (anim.current_frame % anim.frame_count) + 1
end

-- in luna.draw():
luna.graphics.draw(anim.frames[anim.current_frame], x, y)
-- anim.frames[i] is a texture_id loaded with luna.graphics.newImage
