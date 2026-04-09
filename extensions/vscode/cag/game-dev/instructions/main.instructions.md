---
applyTo: "main.lua"
---
# main.lua Structure Rules
- main.lua ONLY: require modules, call init, wire callbacks
- Never put game logic directly in main.lua; delegate to modules
- Required callbacks: luna.load, luna.update, luna.draw
- Optional callbacks: luna.keypressed, luna.keyreleased, luna.mousepressed,
  luna.mousereleased, luna.focus, luna.resize, luna.quit
- conf.lua must exist and define window.title minimally
