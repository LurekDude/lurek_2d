---
applyTo: "main.lua"
---
# main.lua Structure Rules
- main.lua ONLY: require modules, call init, wire callbacks
- Never put game logic directly in main.lua; delegate to modules
- Required callbacks: lurek.load, lurek.update, lurek.draw
- Optional callbacks: lurek.keypressed, lurek.keyreleased, lurek.mousepressed,
  lurek.mousereleased, lurek.focus, lurek.resize, lurek.quit
- conf.lua must exist and define window.title minimally
