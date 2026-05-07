EU2 Province Viewer demo for Lurek2D.

Features:
- Loads `map.png` through `lurek.image.newProvinceGrid`.
- Maps province colors to game IDs from `prov_cols.csv`.
- Loads names and terrain from `province.toml`.
- Builds adjacency graph with `library.province_map`.
- Classifies land/sea and draws colored borders:
  - blue: sea-sea
  - gray: land-land
  - yellow: land-sea
- Pan with left mouse drag.
- Zoom with mouse wheel.
- Hover shows province ID/name; click selects and highlights neighbors.
- Caches province geometry into binary file `save/eu2/cache.bin` using `lurek.data.pack`.

Run:
`python tools/dev/parallel_cargo.py run debug -- content/games/strategy/eu2`
