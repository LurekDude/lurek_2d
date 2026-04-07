"""Fix corrupted gpu_renderer.rs by replacing the broken DrawBatch handler section."""

import sys

REPLACEMENT = r"""                            let mut idxs = Vec::with_capacity(batch.len() * 6);

                            for entry in batch.entries() {
                                let (qw, qh) = if entry.quad_w == 0.0 && entry.quad_h == 0.0 {
                                    (tex_w, tex_h)
                                } else {
                                    (entry.quad_w, entry.quad_h)
                                };
                                let u0 = entry.quad_x / tex_w;
                                let v0 = entry.quad_y / tex_h;
                                let u1 = (entry.quad_x + qw) / tex_w;
                                let v1 = (entry.quad_y + qh) / tex_h;

                                push_tex_quad(
                                    &mut verts, &mut idxs,
                                    t, current_color,
                                    entry.x, entry.y, entry.rotation,
                                    entry.sx, entry.sy, entry.ox, entry.oy,
                                    qw, qh, u0, v0, u1, v1,
                                );
                            }
                            tex_draws.push((tex_id, verts, idxs, current_blend_mode));
                        }
                    }
                }
            }
        }

        // ── Upload geometry to GPU ────────────────────────────────────────

        // Flatten all color batches into single buffers with per-batch range tracking.
        let mut all_color_verts: Vec<ColorVertex> = Vec::new();
        let mut all_color_idxs: Vec<u32> = Vec::new();
        let mut color_ranges: Vec<(BlendMode, u32, u32)> = Vec::new();
        for batch in &color_batches {
            if batch.idxs.is_empty() { continue; }
            let base = all_color_verts.len() as u32;
            let idx_start = all_color_idxs.len() as u32;
            all_color_verts.extend_from_slice(&batch.verts);
            all_color_idxs.extend(batch.idxs.iter().map(|&i| i + base));
            color_ranges.push((batch.blend_mode, idx_start, batch.idxs.len() as u32));
        }
        if !all_color_verts.is_empty() {
            self.queue.write_buffer(
                &self.color_vertex_buffer, 0,
                bytemuck::cast_slice(&all_color_verts),
            );
            self.queue.write_buffer(
                &self.color_index_buffer, 0,
                bytemuck::cast_slice(&all_color_idxs),
            );
        }

        // Flatten all tex draws into one buffer; track per-draw ranges.
        let mut all_tex_verts: Vec<TexVertex> = Vec::new();
        let mut all_tex_idxs: Vec<u32> = Vec::new();
        let mut tex_ranges: Vec<(usize, u32, u32, BlendMode)> = Vec::new();
        for (tex_id, verts, idxs, blend_mode) in &tex_draws {
            let base = all_tex_verts.len() as u32;
            let idx_start = all_tex_idxs.len() as u32;
            all_tex_verts.extend_from_slice(verts);
            all_tex_idxs.extend(idxs.iter().map(|&i| i + base));
            tex_ranges.push((*tex_id, idx_start, idxs.len() as u32, *blend_mode));
        }
        if !all_tex_verts.is_empty() {
            self.queue.write_buffer(
                &self.tex_vertex_buffer, 0,
                bytemuck::cast_slice(&all_tex_verts),
            );
            self.queue.write_buffer(
                &self.tex_index_buffer, 0,
                bytemuck::cast_slice(&all_tex_idxs),
            );
        }

        // ── Render pass ───────────────────────────────────────────────────
        let output = surface.get_current_texture()?;
        let view = output.texture.create_view(&wgpu::TextureViewDescriptor::default());
        let mut encoder = self.device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("frame_encoder"),
        });
        {
            let bg = background_color;
            let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("frame_pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color {
                            r: bg[0] as f64,
                            g: bg[1] as f64,
                            b: bg[2] as f64,
                            a: bg[3] as f64,
                        }),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                timestamp_writes: None,
                occlusion_query_set: None,
            });

            // Draw colored geometry batches.
            if !all_color_idxs.is_empty() {
                let vbytes = (all_color_verts.len() * std::mem::size_of::<ColorVertex>()) as u64;
                let ibytes = (all_color_idxs.len() * std::mem::size_of::<u32>()) as u64;
                pass.set_bind_group(0, &self.viewport_bind_group, &[]);
                pass.set_vertex_buffer(0, self.color_vertex_buffer.slice(..vbytes));
                pass.set_index_buffer(
                    self.color_index_buffer.slice(..ibytes),
                    wgpu::IndexFormat::Uint32,
                );
                for (blend_mode, idx_start, idx_count) in &color_ranges {
                    pass.set_pipeline(&self.color_pipelines[blend_mode]);
                    pass.draw_indexed(*idx_start..*idx_start + *idx_count, 0, 0..1);
                }
            }

            // Draw textured geometry in submission order.
            if !tex_ranges.is_empty() {
                pass.set_bind_group(0, &self.viewport_bind_group, &[]);
                pass.set_vertex_buffer(0, self.tex_vertex_buffer.slice(..));
                pass.set_index_buffer(
                    self.tex_index_buffer.slice(..),
                    wgpu::IndexFormat::Uint32,
                );
                for (tex_id, idx_start, idx_count, blend_mode) in &tex_ranges {
                    if let Some(gt) = self.gpu_textures.get(*tex_id) {
                        pass.set_pipeline(&self.texture_pipelines[blend_mode]);
                        pass.set_bind_group(1, &gt.bind_group, &[]);
                        pass.draw_indexed(*idx_start..*idx_start + *idx_count, 0, 0..1);
                    }
                }
            }
        }

        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();
        Ok(())
    }
"""


def main():
    path = "src/graphics/gpu_renderer.rs"
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Line 809 (1-indexed) = index 808 = 'let mut verts = Vec::with_capacity(batch.len() * 4);'
    # After this line, line 810 starts the corruption (flatten code inside DrawBatch handler)
    # Line 955 (1-indexed) = index 954 = '    }' (closing brace of render_frame)
    # Line 956 = blank, Line 957 = Tessellation helpers comment

    # Keep lines[0:809] (through 'let mut verts...')
    before = lines[:809]

    # Keep from the blank line before tessellation helpers onward
    after = lines[955:]  # index 955 = blank line before '// Tessellation helpers'

    replacement_lines = [line + "\n" for line in REPLACEMENT.split("\n")]

    new_content = before + replacement_lines + after

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    print(f"Fixed: {len(lines)} -> {len(new_content)} lines")


if __name__ == "__main__":
    main()
