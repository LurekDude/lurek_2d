---

### CPU-Side Image Filters (Offline / Load-Time)
For effects that only need to run once (level load, asset generation):

> See [examples/cpu-side-image-filters-offline-load.lua](examples/cpu-side-image-filters-offline-load.lua) for the example.

---

### Performance Budget
Full-screen shader passes are expensive on integrated GPUs. Target: **≤ 2ms total** for all FX passes per frame.

| Effect type | Cost (1080p, Intel UHD) | Notes |
|-------------|------------------------|-------|
| Simple colour math (vignette, greyscale) | ~0.3ms | Safe |
| Texture sample + math (CRT, distortion) | ~0.5ms | Safe |
| Box blur 5×5 | ~1.2ms | Acceptable |
| Gaussian blur 13-tap | ~2.5ms | Tight — consider half-res |
| 3+ chained passes | > 3ms | Risky — profile before shipping |

**Rule**: Halve the canvas resolution for effects that don't need pixel-level precision (bloom, blur). Draw final composite at full resolution:

> See [examples/performance-budget.lua](examples/performance-budget.lua) for the example.
