-- .github/skills/html-css/snippets/common-patterns.lua
-- Copy-paste patterns for the most common lurek.html tasks.
-- Load this companion when building any HTML-based screen in Lurek2D.

-- PATTERN 1 â€” Input forwarding (place these four functions in every html-* screen)
-- Forward all events; return early when the UI consumes an event.
--
--   function lurek.mousepressed(x, y, btn)
--       if doc:mousepressed(x, y, btn) then return end
--   end
--   function lurek.mousereleased(x, y, btn)
--       doc:mousereleased(x, y, btn)
--   end
--   function lurek.mousemoved(x, y, dx, dy)
--       doc:mousemoved(x, y)
--   end
--   function lurek.keypressed(key)
--       if doc:keypressed(key) then return end
--   end
--   function lurek.textinput(text)
--       doc:textinput(text)
--   end


-- PATTERN 2 â€” Binary CSS class toggle (checkbox, switch, button)
--
--   local btn = doc:getElementById("toggle")
--   local active = btn:toggleClass("on")   -- returns true when class was added
--   save_setting("sound_on", active)


-- PATTERN 3 â€” Radio-group CSS class reset (tabs, difficulty buttons)
--
--   local function select_tab(id)
--       for _, tab in ipairs(doc:queryAll("[data-tab]")) do
--           tab:removeClass("active")
--       end
--       local el = doc:getElementById(id)
--       if el then el:addClass("active") end
--   end


-- PATTERN 4 â€” Relayout after setHtml (dialog page turn, scoreboard refresh)
--
--   doc:setHtml(build_html_for_current_page())
--   doc:relayout()   -- REQUIRED before the next draw call


-- PATTERN 5 â€” getRect-based tooltip positioning
--
--   function lurek.update(dt)
--       local icon = doc:getElementById("skill-icon")
--       if icon then
--           local x, y, w, h = icon:getRect()
--           tooltip_x = x + w + 8
--           tooltip_y = y
--       end
--       doc:update(dt)
--   end


-- PATTERN 6 â€” Dynamic inventory slot wiring
--
--   local slots = doc:queryAll(".slot")
--   for _, slot in ipairs(slots) do
--       slot:on("click", function(el)
--           local item = el:getAttribute("data-item")
--           if item then equip(item) end
--       end)
--   end


-- PATTERN 7 â€” loadDocument with error guard
--
--   local doc, err
--   do
--       local ok, result = pcall(lurek.html.loadDocument, "ui/hud.html", {
--           width  = lurek.window.getWidth(),
--           height = lurek.window.getHeight(),
--       })
--       if ok then
--           doc = result
--       else
--           lurek.log.error("Failed to load HUD: " .. tostring(result))
--           doc = lurek.html.newDocument("<p>Error loading HUD</p>")
--       end
--   end


-- PATTERN 8 â€” Viewport sync on resize
--
--   function lurek.resize(w, h)
--       doc:setViewport(w, h)
--   end
