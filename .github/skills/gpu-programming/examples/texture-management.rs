// Upload texture to GPU:
let texture_key = state.borrow_mut().textures.insert(TextureData {
    width, height, format: wgpu::TextureFormat::Rgba8UnormSrgb, ...
});
gpu_renderer.upload_texture(texture_key, rgba_bytes);

// Reference by key in RenderCommand:
RenderCommand::DrawImage { texture_key, x, y, w, h, ... }

// Release (queued for deferred GPU destruction at next frame start):
state.borrow_mut().textures.remove(texture_key);
