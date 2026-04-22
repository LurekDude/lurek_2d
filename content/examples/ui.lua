-- content/examples/ui.lua
-- Practical usage examples for the lurek.ui API (363 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.ui.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/ui.lua

print("[example] lurek.ui — 363 API entries")

-- ── lurek.ui.* free functions ──

--@api-stub: lurek.ui.setPosition
-- Sets the widget position.
-- Call when you need to assign position.
local ok, err = pcall(function() lurek.ui.setPosition(0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setPosition applied=", ok)

--@api-stub: lurek.ui.getPosition
-- Returns the widget position.
-- Call when you need to read position.
local ok, value = pcall(function() return lurek.ui.getPosition() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getPosition ->", v)

--@api-stub: lurek.ui.setSize
-- Sets the width and height of the widget in UI pixels.
-- Call when you need to assign size.
local ok, err = pcall(function() lurek.ui.setSize(100, 100) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setSize applied=", ok)

--@api-stub: lurek.ui.getSize
-- Returns the current width and height of the widget in UI pixels.
-- Call when you need to read size.
local ok, value = pcall(function() return lurek.ui.getSize() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getSize ->", v)

--@api-stub: lurek.ui.getRect
-- Returns the computed screen-space rectangle after layout.
-- Call when you need to read rect.
local ok, value = pcall(function() return lurek.ui.getRect() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getRect ->", v)

--@api-stub: lurek.ui.setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- Call when you need to assign visible.
local ok, err = pcall(function() lurek.ui.setVisible(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setVisible applied=", ok)

--@api-stub: lurek.ui.isVisible
-- Returns whether the widget is visible.
-- Call when you need to check is visible.
local ok, result = pcall(function() return lurek.ui.isVisible() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.ui.isVisible ok=", ok)

--@api-stub: lurek.ui.setEnabled
-- Sets whether the widget is enabled.
-- Call when you need to assign enabled.
local ok, err = pcall(function() lurek.ui.setEnabled(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setEnabled applied=", ok)

--@api-stub: lurek.ui.isEnabled
-- Returns whether the widget is enabled.
-- Call when you need to check is enabled.
local ok, result = pcall(function() return lurek.ui.isEnabled() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.ui.isEnabled ok=", ok)

--@api-stub: lurek.ui.setId
-- Sets the widget string identifier.
-- Call when you need to assign id.
local ok, err = pcall(function() lurek.ui.setId(1) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setId applied=", ok)

--@api-stub: lurek.ui.getId
-- Returns the widget string identifier.
-- Call when you need to read id.
local ok, value = pcall(function() return lurek.ui.getId() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getId ->", v)

--@api-stub: lurek.ui.setTooltip
-- Sets the widget tooltip text.
-- Call when you need to assign tooltip.
local ok, err = pcall(function() lurek.ui.setTooltip("text value") end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setTooltip applied=", ok)

--@api-stub: lurek.ui.getTooltip
-- Returns the widget tooltip text.
-- Call when you need to read tooltip.
local ok, value = pcall(function() return lurek.ui.getTooltip() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getTooltip ->", v)

--@api-stub: lurek.ui.getState
-- Returns the widget interaction state name.
-- Call when you need to read state.
local ok, value = pcall(function() return lurek.ui.getState() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getState ->", v)

--@api-stub: lurek.ui.addChild
-- Adds a child widget to this container.
-- Call when you need to add child.
local ok, err = pcall(function() lurek.ui.addChild(nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.ui.addChild done=", ok)

--@api-stub: lurek.ui.removeChild
-- Removes a child widget from this container.
-- Call when you need to remove child.
local ok, err = pcall(function() lurek.ui.removeChild(nil) end)
if not ok then print("skipped:", err) end
print("lurek.ui.removeChild cleared=", ok)

--@api-stub: lurek.ui.getChildCount
-- Returns the number of children in this container.
-- Call when you need to read child count.
local ok, value = pcall(function() return lurek.ui.getChildCount() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getChildCount ->", v)

--@api-stub: lurek.ui.getChildren
-- Returns this container's children as widget-handle tables.
-- Call when you need to read children.
local ok, value = pcall(function() return lurek.ui.getChildren() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getChildren ->", v)

--@api-stub: lurek.ui.findById
-- Recursively searches for a widget by id starting from this widget.
-- Call when you need to invoke find by id.
local ok, value = pcall(function() return lurek.ui.findById(1) end)
local v = ok and value or "(unavailable)"
print("lurek.ui.findById ->", v)

--@api-stub: lurek.ui.setOnClick
-- Registers a callback invoked when this widget is clicked.
-- Call when you need to assign on click.
local ok, err = pcall(function() lurek.ui.setOnClick(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setOnClick applied=", ok)

--@api-stub: lurek.ui.setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Call when you need to assign on change.
local ok, err = pcall(function() lurek.ui.setOnChange(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setOnChange applied=", ok)

--@api-stub: lurek.ui.setOnDraw
-- Stores a custom draw callback for later invocation.
-- Call when you need to assign on draw.
local ok, err = pcall(function() lurek.ui.setOnDraw(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setOnDraw applied=", ok)

--@api-stub: lurek.ui.containsPoint
-- Returns whether (x, y) is inside this widget.
-- Call when you need to invoke contains point.
local ok, result = pcall(function() return lurek.ui.containsPoint(0, 0) end)
if ok then print("lurek.ui.containsPoint ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- Call when you need to assign padding.
local ok, err = pcall(function() lurek.ui.setPadding(nil, nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setPadding applied=", ok)

--@api-stub: lurek.ui.getPadding
-- Returns the widget padding (top, right, bottom, left).
-- Call when you need to read padding.
local ok, value = pcall(function() return lurek.ui.getPadding() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getPadding ->", v)

--@api-stub: lurek.ui.setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- Call when you need to assign margin.
local ok, err = pcall(function() lurek.ui.setMargin(nil, nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setMargin applied=", ok)

--@api-stub: lurek.ui.getMargin
-- Returns the widget margin (top, right, bottom, left).
-- Call when you need to read margin.
local ok, value = pcall(function() return lurek.ui.getMargin() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getMargin ->", v)

--@api-stub: lurek.ui.setZOrder
-- Sets the widget z-order for draw sorting.
-- Call when you need to assign z order.
local ok, err = pcall(function() lurek.ui.setZOrder(0) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setZOrder applied=", ok)

--@api-stub: lurek.ui.getZOrder
-- Returns the widget z-order.
-- Call when you need to read z order.
local ok, value = pcall(function() return lurek.ui.getZOrder() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getZOrder ->", v)

--@api-stub: lurek.ui.setMinSize
-- Sets the minimum widget size.
-- Call when you need to assign min size.
local ok, err = pcall(function() lurek.ui.setMinSize(100, 100) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setMinSize applied=", ok)

--@api-stub: lurek.ui.getMinSize
-- Returns the minimum widget size.
-- Call when you need to read min size.
local ok, value = pcall(function() return lurek.ui.getMinSize() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getMinSize ->", v)

--@api-stub: lurek.ui.setMaxSize
-- Sets the maximum widget size.
-- Call when you need to assign max size.
local ok, err = pcall(function() lurek.ui.setMaxSize(100, 100) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setMaxSize applied=", ok)

--@api-stub: lurek.ui.getMaxSize
-- Returns the maximum widget size.
-- Call when you need to read max size.
local ok, value = pcall(function() return lurek.ui.getMaxSize() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getMaxSize ->", v)

--@api-stub: lurek.ui.setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- Call when you need to assign anchor.
local ok, err = pcall(function() lurek.ui.setAnchor() end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setAnchor applied=", ok)

--@api-stub: lurek.ui.setAnchorCenter
-- Sets center anchor offsets.
-- Call when you need to assign anchor center.
local ok, err = pcall(function() lurek.ui.setAnchorCenter(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setAnchorCenter applied=", ok)

--@api-stub: lurek.ui.clearAnchor
-- Removes all anchor constraints.
-- Call when you need to invoke clear anchor.
local ok, err = pcall(function() lurek.ui.clearAnchor() end)
if not ok then print("skipped:", err) end
print("lurek.ui.clearAnchor cleared=", ok)

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex-grow factor.
-- Call when you need to assign flex grow.
local ok, err = pcall(function() lurek.ui.setFlexGrow(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setFlexGrow applied=", ok)

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex-grow factor.
-- Call when you need to read flex grow.
local ok, value = pcall(function() return lurek.ui.getFlexGrow() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getFlexGrow ->", v)

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex-shrink factor.
-- Call when you need to assign flex shrink.
local ok, err = pcall(function() lurek.ui.setFlexShrink(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setFlexShrink applied=", ok)

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex-shrink factor.
-- Call when you need to read flex shrink.
local ok, value = pcall(function() return lurek.ui.getFlexShrink() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getFlexShrink ->", v)

--@api-stub: lurek.ui.bind
-- Registers a data-binding key on this widget.
-- Call when you need to invoke bind.
local ok, result = pcall(function() return lurek.ui.bind("key") end)
if ok then print("lurek.ui.bind ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.unbind
-- Removes the data-binding key from this widget.
-- Call when you need to invoke unbind.
local ok, result = pcall(function() return lurek.ui.unbind() end)
if ok then print("lurek.ui.unbind ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- Call when you need to assign alpha.
local ok, err = pcall(function() lurek.ui.setAlpha(1) end)
if not ok then print("set skipped:", err) end
print("lurek.ui.setAlpha applied=", ok)

--@api-stub: lurek.ui.getAlpha
-- Returns the widget's current alpha transparency.
-- Call when you need to read alpha.
local ok, value = pcall(function() return lurek.ui.getAlpha() end)
local v = ok and value or "(unavailable)"
print("lurek.ui.getAlpha ->", v)

--@api-stub: lurek.ui.fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- Call when you need to invoke fade in.
local ok, result = pcall(function() return lurek.ui.fadeIn() end)
if ok then print("lurek.ui.fadeIn ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- Call when you need to invoke fade out.
local ok, result = pcall(function() return lurek.ui.fadeOut() end)
if ok then print("lurek.ui.fadeOut ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- Call when you need to invoke slide in.
local ok, result = pcall(function() return lurek.ui.slideIn(0, 0) end)
if ok then print("lurek.ui.slideIn ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- Call when you need to invoke slide out.
local ok, result = pcall(function() return lurek.ui.slideOut(0, 0) end)
if ok then print("lurek.ui.slideOut ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.ui.attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- Call when you need to invoke attach to entity.
local ok, err = pcall(function() lurek.ui.attachToEntity(1) end)
if not ok then print("mutator skipped:", err) end
print("lurek.ui.attachToEntity done=", ok)

--@api-stub: lurek.ui.detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- Call when you need to invoke detach from entity.
local ok, err = pcall(function() lurek.ui.detachFromEntity() end)
if not ok then print("skipped:", err) end
print("lurek.ui.detachFromEntity cleared=", ok)

-- ── Button methods ──

--@api-stub: Button:setText
-- Sets the text for this Button widget.
-- Call when you need to assign text.
-- Build a Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newButton(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Button:setText ->", ok, result)
end

--@api-stub: Button:getText
-- Returns the text of this Button widget.
-- Call when you need to read text.
-- Build a Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newButton(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Button:getText ->", ok, result)
end

-- ── Label methods ──

--@api-stub: Label:setText
-- Sets the text for this Label widget.
-- Call when you need to assign text.
-- Build a Label via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLabel(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Label:setText ->", ok, result)
end

--@api-stub: Label:getText
-- Returns the text of this Label widget.
-- Call when you need to read text.
-- Build a Label via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLabel(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Label:getText ->", ok, result)
end

-- ── Text_Input methods ──

--@api-stub: Text_Input:setText
-- Sets the text for this Text_Input widget.
-- Call when you need to assign text.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Text_Input:setText ->", ok, result)
end

--@api-stub: Text_Input:getText
-- Returns the text of this Text_Input widget.
-- Call when you need to read text.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Text_Input:getText ->", ok, result)
end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- Call when you need to assign placeholder.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:setPlaceholder("text value") end)
  print("Text_Input:setPlaceholder ->", ok, result)
end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- Call when you need to read placeholder.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:getPlaceholder() end)
  print("Text_Input:getPlaceholder ->", ok, result)
end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length for this Text_Input widget.
-- Call when you need to assign max length.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:setMaxLength(10) end)
  print("Text_Input:setMaxLength ->", ok, result)
end

--@api-stub: Text_Input:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- Call when you need to check is focused.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:isFocused() end)
  print("Text_Input:isFocused ->", ok, result)
end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- Call when you need to read cursor position.
-- Build a Text_Input via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newText_Input(...)
if instance then
  local ok, result = pcall(function() return instance:getCursorPosition() end)
  print("Text_Input:getCursorPosition ->", ok, result)
end

-- ── Checkbox methods ──

--@api-stub: Checkbox:setChecked
-- Sets the checked for this Checkbox widget.
-- Call when you need to assign checked.
-- Build a Checkbox via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCheckbox(...)
if instance then
  local ok, result = pcall(function() return instance:setChecked(nil) end)
  print("Checkbox:setChecked ->", ok, result)
end

--@api-stub: Checkbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- Call when you need to check is checked.
-- Build a Checkbox via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCheckbox(...)
if instance then
  local ok, result = pcall(function() return instance:isChecked() end)
  print("Checkbox:isChecked ->", ok, result)
end

--@api-stub: Checkbox:setText
-- Sets the text for this Checkbox widget.
-- Call when you need to assign text.
-- Build a Checkbox via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCheckbox(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Checkbox:setText ->", ok, result)
end

--@api-stub: Checkbox:getText
-- Returns the text of this Checkbox widget.
-- Call when you need to read text.
-- Build a Checkbox via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCheckbox(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Checkbox:getText ->", ok, result)
end

-- ── Slider methods ──

--@api-stub: Slider:setValue
-- Sets the value for this Slider widget.
-- Call when you need to assign value.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:setValue(nil) end)
  print("Slider:setValue ->", ok, result)
end

--@api-stub: Slider:getValue
-- Returns the value of this Slider widget.
-- Call when you need to read value.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:getValue() end)
  print("Slider:getValue ->", ok, result)
end

--@api-stub: Slider:setRange
-- Sets the range for this Slider widget.
-- Call when you need to assign range.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:setRange(0, 100) end)
  print("Slider:setRange ->", ok, result)
end

--@api-stub: Slider:setStep
-- Sets the step for this Slider widget.
-- Call when you need to assign step.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:setStep(nil) end)
  print("Slider:setStep ->", ok, result)
end

--@api-stub: Slider:getMin
-- Returns the min of this Slider widget.
-- Call when you need to read min.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:getMin() end)
  print("Slider:getMin ->", ok, result)
end

--@api-stub: Slider:getMax
-- Returns the max of this Slider widget.
-- Call when you need to read max.
-- Build a Slider via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSlider(...)
if instance then
  local ok, result = pcall(function() return instance:getMax() end)
  print("Slider:getMax ->", ok, result)
end

-- ── Progress_Bar methods ──

--@api-stub: Progress_Bar:setValue
-- Sets the value for this Progress_Bar widget.
-- Call when you need to assign value.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setValue(nil) end)
  print("Progress_Bar:setValue ->", ok, result)
end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this Progress_Bar widget.
-- Call when you need to read value.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getValue() end)
  print("Progress_Bar:getValue ->", ok, result)
end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- Call when you need to read progress.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getProgress() end)
  print("Progress_Bar:getProgress ->", ok, result)
end

--@api-stub: Progress_Bar:setRange
-- Sets the range for this Progress_Bar widget.
-- Call when you need to assign range.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setRange(0, 100) end)
  print("Progress_Bar:setRange ->", ok, result)
end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this Progress_Bar widget.
-- Call when you need to read min.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getMin() end)
  print("Progress_Bar:getMin ->", ok, result)
end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this Progress_Bar widget.
-- Call when you need to read max.
-- Build a Progress_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newProgress_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getMax() end)
  print("Progress_Bar:getMax ->", ok, result)
end

-- ── Combo_Box methods ──

--@api-stub: Combo_Box:addItem
-- Adds a item entry to this Combo_Box widget.
-- Call when you need to add item.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:addItem("text value") end)
  print("Combo_Box:addItem ->", ok, result)
end

--@api-stub: Combo_Box:removeItem
-- Removes the item from this Combo_Box widget.
-- Call when you need to remove item.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:removeItem(1) end)
  print("Combo_Box:removeItem ->", ok, result)
end

--@api-stub: Combo_Box:clearItems
-- Clears all items entries from this Combo_Box widget.
-- Call when you need to invoke clear items.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:clearItems() end)
  print("Combo_Box:clearItems ->", ok, result)
end

--@api-stub: Combo_Box:getItemCount
-- Returns the item count of this Combo_Box widget.
-- Call when you need to read item count.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("Combo_Box:getItemCount ->", ok, result)
end

--@api-stub: Combo_Box:getItem
-- Returns the item of this Combo_Box widget.
-- Call when you need to read item.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getItem(1) end)
  print("Combo_Box:getItem ->", ok, result)
end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- Call when you need to assign selected index.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setSelectedIndex(1) end)
  print("Combo_Box:setSelectedIndex ->", ok, result)
end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- Call when you need to read selected index.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getSelectedIndex() end)
  print("Combo_Box:getSelectedIndex ->", ok, result)
end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- Call when you need to read selected item.
-- Build a Combo_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newCombo_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getSelectedItem() end)
  print("Combo_Box:getSelectedItem ->", ok, result)
end

-- ── List_Box methods ──

--@api-stub: List_Box:addItem
-- Adds a item entry to this List_Box widget.
-- Call when you need to add item.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:addItem("text value") end)
  print("List_Box:addItem ->", ok, result)
end

--@api-stub: List_Box:removeItem
-- Removes the item from this List_Box widget.
-- Call when you need to remove item.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:removeItem(1) end)
  print("List_Box:removeItem ->", ok, result)
end

--@api-stub: List_Box:clearItems
-- Clears all items entries from this List_Box widget.
-- Call when you need to invoke clear items.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:clearItems() end)
  print("List_Box:clearItems ->", ok, result)
end

--@api-stub: List_Box:getItemCount
-- Returns the item count of this List_Box widget.
-- Call when you need to read item count.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("List_Box:getItemCount ->", ok, result)
end

--@api-stub: List_Box:getItem
-- Returns the item of this List_Box widget.
-- Call when you need to read item.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getItem(1) end)
  print("List_Box:getItem ->", ok, result)
end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- Call when you need to assign selected index.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setSelectedIndex(1) end)
  print("List_Box:setSelectedIndex ->", ok, result)
end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- Call when you need to read selected index.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getSelectedIndex() end)
  print("List_Box:getSelectedIndex ->", ok, result)
end

--@api-stub: List_Box:setItemHeight
-- Sets the item height for this List_Box widget.
-- Call when you need to assign item height.
-- Build a List_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newList_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setItemHeight(100) end)
  print("List_Box:setItemHeight ->", ok, result)
end

-- ── Tab_Bar methods ──

--@api-stub: Tab_Bar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- Call when you need to add tab.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:addTab("label") end)
  print("Tab_Bar:addTab ->", ok, result)
end

--@api-stub: Tab_Bar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- Call when you need to remove tab.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:removeTab(1) end)
  print("Tab_Bar:removeTab ->", ok, result)
end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this Tab_Bar widget.
-- Call when you need to read tab.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getTab(1) end)
  print("Tab_Bar:getTab ->", ok, result)
end

--@api-stub: Tab_Bar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- Call when you need to read tab count.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getTabCount() end)
  print("Tab_Bar:getTabCount ->", ok, result)
end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- Call when you need to assign active tab.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setActiveTab(1) end)
  print("Tab_Bar:setActiveTab ->", ok, result)
end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- Call when you need to read active tab.
-- Build a Tab_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTab_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getActiveTab() end)
  print("Tab_Bar:getActiveTab ->", ok, result)
end

-- ── Spin_Box methods ──

--@api-stub: Spin_Box:setValue
-- Sets the value for this SpinBox widget.
-- Call when you need to assign value.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setValue(nil) end)
  print("Spin_Box:setValue ->", ok, result)
end

--@api-stub: Spin_Box:getValue
-- Returns the current value of this SpinBox widget.
-- Call when you need to read value.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:getValue() end)
  print("Spin_Box:getValue ->", ok, result)
end

--@api-stub: Spin_Box:increment
-- Increments the value by one step.
-- Call when you need to invoke increment.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:increment() end)
  print("Spin_Box:increment ->", ok, result)
end

--@api-stub: Spin_Box:decrement
-- Decrements the value by one step.
-- Call when you need to invoke decrement.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:decrement() end)
  print("Spin_Box:decrement ->", ok, result)
end

--@api-stub: Spin_Box:setRange
-- Sets the valid range for this SpinBox widget.
-- Call when you need to assign range.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setRange(0, 100) end)
  print("Spin_Box:setRange ->", ok, result)
end

--@api-stub: Spin_Box:setStep
-- Sets the increment step for this SpinBox widget.
-- Call when you need to assign step.
-- Build a Spin_Box via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSpin_Box(...)
if instance then
  local ok, result = pcall(function() return instance:setStep(nil) end)
  print("Spin_Box:setStep ->", ok, result)
end

-- ── Switch methods ──

--@api-stub: Switch:setOn
-- Sets the on/off state of this Switch widget.
-- Call when you need to assign on.
-- Build a Switch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSwitch(...)
if instance then
  local ok, result = pcall(function() return instance:setOn(nil) end)
  print("Switch:setOn ->", ok, result)
end

--@api-stub: Switch:isOn
-- Returns the on/off state of this Switch widget.
-- Call when you need to check is on.
-- Build a Switch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSwitch(...)
if instance then
  local ok, result = pcall(function() return instance:isOn() end)
  print("Switch:isOn ->", ok, result)
end

--@api-stub: Switch:toggle
-- Toggles the on/off state of this Switch widget.
-- Call when you need to invoke toggle.
-- Build a Switch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSwitch(...)
if instance then
  local ok, result = pcall(function() return instance:toggle() end)
  print("Switch:toggle ->", ok, result)
end

-- ── Badge methods ──

--@api-stub: Badge:setCount
-- Sets the count displayed on this Badge widget.
-- Call when you need to assign count.
-- Build a Badge via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newBadge(...)
if instance then
  local ok, result = pcall(function() return instance:setCount(10) end)
  print("Badge:setCount ->", ok, result)
end

--@api-stub: Badge:getCount
-- Returns the raw count of this Badge widget.
-- Call when you need to read count.
-- Build a Badge via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newBadge(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("Badge:getCount ->", ok, result)
end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this Badge widget, e.g.
-- "99+" when over the max.
-- Build a Badge via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newBadge(...)
if instance then
  local ok, result = pcall(function() return instance:getDisplayText() end)
  print("Badge:getDisplayText ->", ok, result)
end

-- ── Panel methods ──

--@api-stub: Panel:setTitle
-- Sets the title for this Panel widget.
-- Call when you need to assign title.
-- Build a Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newPanel(...)
if instance then
  local ok, result = pcall(function() return instance:setTitle(nil) end)
  print("Panel:setTitle ->", ok, result)
end

--@api-stub: Panel:getTitle
-- Returns the title of this Panel widget.
-- Call when you need to read title.
-- Build a Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newPanel(...)
if instance then
  local ok, result = pcall(function() return instance:getTitle() end)
  print("Panel:getTitle ->", ok, result)
end

--@api-stub: Panel:setScrollable
-- Sets the scrollable for this Panel widget.
-- Call when you need to assign scrollable.
-- Build a Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newPanel(...)
if instance then
  local ok, result = pcall(function() return instance:setScrollable(nil) end)
  print("Panel:setScrollable ->", ok, result)
end

-- ── Layout methods ──

--@api-stub: Layout:setDirection
-- Sets the direction for this Layout widget.
-- Call when you need to assign direction.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setDirection("dir") end)
  print("Layout:setDirection ->", ok, result)
end

--@api-stub: Layout:getDirection
-- Returns the direction of this Layout widget.
-- Call when you need to read direction.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:getDirection() end)
  print("Layout:getDirection ->", ok, result)
end

--@api-stub: Layout:setSpacing
-- Sets the spacing for this Layout widget.
-- Call when you need to assign spacing.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setSpacing(nil) end)
  print("Layout:setSpacing ->", ok, result)
end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this Layout widget.
-- Call when you need to read spacing.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:getSpacing() end)
  print("Layout:getSpacing ->", ok, result)
end

--@api-stub: Layout:setColumns
-- Sets the columns for this Layout widget.
-- Call when you need to assign columns.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setColumns(10) end)
  print("Layout:setColumns ->", ok, result)
end

--@api-stub: Layout:setWrap
-- Sets the wrap for this Layout widget.
-- Call when you need to assign wrap.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setWrap(nil) end)
  print("Layout:setWrap ->", ok, result)
end

--@api-stub: Layout:getWrap
-- Returns the wrap of this Layout widget.
-- Call when you need to read wrap.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:getWrap() end)
  print("Layout:getWrap ->", ok, result)
end

--@api-stub: Layout:setAlign
-- Sets the align for this Layout widget.
-- Call when you need to assign align.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setAlign(nil) end)
  print("Layout:setAlign ->", ok, result)
end

--@api-stub: Layout:getAlign
-- Returns the align of this Layout widget.
-- Call when you need to read align.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:getAlign() end)
  print("Layout:getAlign ->", ok, result)
end

--@api-stub: Layout:setJustify
-- Sets the justify for this Layout widget.
-- Call when you need to assign justify.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:setJustify(nil) end)
  print("Layout:setJustify ->", ok, result)
end

--@api-stub: Layout:getJustify
-- Returns the justify of this Layout widget.
-- Call when you need to read justify.
-- Build a Layout via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLayout(...)
if instance then
  local ok, result = pcall(function() return instance:getJustify() end)
  print("Layout:getJustify ->", ok, result)
end

-- ── Scroll_Panel methods ──

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- Call when you need to assign content size.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setContentSize(100, 100) end)
  print("Scroll_Panel:setContentSize ->", ok, result)
end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- Call when you need to read content size.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getContentSize() end)
  print("Scroll_Panel:getContentSize ->", ok, result)
end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- Call when you need to assign scroll position.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setScrollPosition(0, 0) end)
  print("Scroll_Panel:setScrollPosition ->", ok, result)
end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- Call when you need to read scroll position.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getScrollPosition() end)
  print("Scroll_Panel:getScrollPosition ->", ok, result)
end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- Call when you need to read max scroll.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxScroll() end)
  print("Scroll_Panel:getMaxScroll ->", ok, result)
end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- Call when you need to assign scroll speed.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setScrollSpeed(nil) end)
  print("Scroll_Panel:setScrollSpeed ->", ok, result)
end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- Call when you need to read scroll speed.
-- Build a Scroll_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getScrollSpeed() end)
  print("Scroll_Panel:getScrollSpeed ->", ok, result)
end

-- ── Nine_Patch methods ──

--@api-stub: Nine_Patch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- Call when you need to assign insets.
-- Build a Nine_Patch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newNine_Patch(...)
if instance then
  local ok, result = pcall(function() return instance:setInsets(nil, nil, nil, nil) end)
  print("Nine_Patch:setInsets ->", ok, result)
end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- Call when you need to read insets.
-- Build a Nine_Patch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newNine_Patch(...)
if instance then
  local ok, result = pcall(function() return instance:getInsets() end)
  print("Nine_Patch:getInsets ->", ok, result)
end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- Call when you need to assign image dimensions.
-- Build a Nine_Patch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newNine_Patch(...)
if instance then
  local ok, result = pcall(function() return instance:setImageDimensions(100, 100) end)
  print("Nine_Patch:setImageDimensions ->", ok, result)
end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- Call when you need to read image dimensions.
-- Build a Nine_Patch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newNine_Patch(...)
if instance then
  local ok, result = pcall(function() return instance:getImageDimensions() end)
  print("Nine_Patch:getImageDimensions ->", ok, result)
end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- Call when you need to read slices.
-- Build a Nine_Patch via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newNine_Patch(...)
if instance then
  local ok, result = pcall(function() return instance:getSlices() end)
  print("Nine_Patch:getSlices ->", ok, result)
end

-- ── Toast methods ──

--@api-stub: Toast:setMessage
-- Sets the message for this Toast widget.
-- Call when you need to assign message.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:setMessage("msg value") end)
  print("Toast:setMessage ->", ok, result)
end

--@api-stub: Toast:getMessage
-- Returns the message of this Toast widget.
-- Call when you need to read message.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:getMessage() end)
  print("Toast:getMessage ->", ok, result)
end

--@api-stub: Toast:setDuration
-- Sets the duration for this Toast widget.
-- Call when you need to assign duration.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:setDuration(nil) end)
  print("Toast:setDuration ->", ok, result)
end

--@api-stub: Toast:getDuration
-- Returns the duration of this Toast widget.
-- Call when you need to read duration.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("Toast:getDuration ->", ok, result)
end

--@api-stub: Toast:getProgress
-- Returns the progress of this Toast widget.
-- Call when you need to read progress.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:getProgress() end)
  print("Toast:getProgress ->", ok, result)
end

--@api-stub: Toast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- Call when you need to check is expired.
-- Build a Toast via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToast(...)
if instance then
  local ok, result = pcall(function() return instance:isExpired() end)
  print("Toast:isExpired ->", ok, result)
end

-- ── Separator methods ──

--@api-stub: Separator:setVertical
-- Sets the vertical for this Separator widget.
-- Call when you need to assign vertical.
-- Build a Separator via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSeparator(...)
if instance then
  local ok, result = pcall(function() return instance:setVertical(nil) end)
  print("Separator:setVertical ->", ok, result)
end

--@api-stub: Separator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- Call when you need to check is vertical.
-- Build a Separator via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSeparator(...)
if instance then
  local ok, result = pcall(function() return instance:isVertical() end)
  print("Separator:isVertical ->", ok, result)
end

--@api-stub: Separator:setThickness
-- Sets the thickness for this Separator widget.
-- Call when you need to assign thickness.
-- Build a Separator via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSeparator(...)
if instance then
  local ok, result = pcall(function() return instance:setThickness(nil) end)
  print("Separator:setThickness ->", ok, result)
end

--@api-stub: Separator:getThickness
-- Returns the thickness of this Separator widget.
-- Call when you need to read thickness.
-- Build a Separator via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSeparator(...)
if instance then
  local ok, result = pcall(function() return instance:getThickness() end)
  print("Separator:getThickness ->", ok, result)
end

-- ── Tree_View methods ──

--@api-stub: Tree_View:addNode
-- Adds a node entry to this Tree_View widget.
-- Call when you need to add node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:addNode("text value", 1) end)
  print("Tree_View:addNode ->", ok, result)
end

--@api-stub: Tree_View:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- Call when you need to invoke toggle node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:toggleNode(1) end)
  print("Tree_View:toggleNode ->", ok, result)
end

--@api-stub: Tree_View:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- Call when you need to check is expanded.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:isExpanded(1) end)
  print("Tree_View:isExpanded ->", ok, result)
end

--@api-stub: Tree_View:getNodeCount
-- Returns the node count of this Tree_View widget.
-- Call when you need to read node count.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getNodeCount() end)
  print("Tree_View:getNodeCount ->", ok, result)
end

--@api-stub: Tree_View:removeNode
-- Removes the node from this Tree_View widget.
-- Call when you need to remove node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:removeNode(1) end)
  print("Tree_View:removeNode ->", ok, result)
end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- Call when you need to invoke clear nodes.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:clearNodes() end)
  print("Tree_View:clearNodes ->", ok, result)
end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this Tree_View widget.
-- Call when you need to read node text.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getNodeText(1) end)
  print("Tree_View:getNodeText ->", ok, result)
end

--@api-stub: Tree_View:setNodeText
-- Sets the node text for this Tree_View widget.
-- Call when you need to assign node text.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:setNodeText(1, "text value") end)
  print("Tree_View:setNodeText ->", ok, result)
end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- Call when you need to assign node icon.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:setNodeIcon(1, nil) end)
  print("Tree_View:setNodeIcon ->", ok, result)
end

--@api-stub: Tree_View:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- Call when you need to invoke expand node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:expandNode(1) end)
  print("Tree_View:expandNode ->", ok, result)
end

--@api-stub: Tree_View:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- Call when you need to invoke collapse node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:collapseNode(1) end)
  print("Tree_View:collapseNode ->", ok, result)
end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- Call when you need to check is node expanded.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:isNodeExpanded(1) end)
  print("Tree_View:isNodeExpanded ->", ok, result)
end

--@api-stub: Tree_View:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- Call when you need to invoke expand all.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:expandAll() end)
  print("Tree_View:expandAll ->", ok, result)
end

--@api-stub: Tree_View:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- Call when you need to invoke collapse all.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:collapseAll() end)
  print("Tree_View:collapseAll ->", ok, result)
end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- Call when you need to assign selected node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:setSelectedNode(1) end)
  print("Tree_View:setSelectedNode ->", ok, result)
end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- Call when you need to read selected node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getSelectedNode() end)
  print("Tree_View:getSelectedNode ->", ok, result)
end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- Call when you need to read child nodes.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getChildNodes(1) end)
  print("Tree_View:getChildNodes ->", ok, result)
end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this Tree_View widget.
-- Call when you need to read parent node.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getParentNode(1) end)
  print("Tree_View:getParentNode ->", ok, result)
end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- Call when you need to read node depth.
-- Build a Tree_View via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTree_View(...)
if instance then
  local ok, result = pcall(function() return instance:getNodeDepth(1) end)
  print("Tree_View:getNodeDepth ->", ok, result)
end

-- ── Radio_Button methods ──

--@api-stub: Radio_Button:getText
-- Returns the text of this Radio_Button widget.
-- Call when you need to read text.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Radio_Button:getText ->", ok, result)
end

--@api-stub: Radio_Button:setText
-- Sets the text for this Radio_Button widget.
-- Call when you need to assign text.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Radio_Button:setText ->", ok, result)
end

--@api-stub: Radio_Button:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- Call when you need to check is selected.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:isSelected() end)
  print("Radio_Button:isSelected ->", ok, result)
end

--@api-stub: Radio_Button:setSelected
-- Sets the selected for this Radio_Button widget.
-- Call when you need to assign selected.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:setSelected(nil) end)
  print("Radio_Button:setSelected ->", ok, result)
end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this Radio_Button widget.
-- Call when you need to read group.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:getGroup() end)
  print("Radio_Button:getGroup ->", ok, result)
end

--@api-stub: Radio_Button:setGroup
-- Sets the group for this Radio_Button widget.
-- Call when you need to assign group.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:setGroup(nil) end)
  print("Radio_Button:setGroup ->", ok, result)
end

--@api-stub: Radio_Button:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Call when you need to assign on change.
-- Build a Radio_Button via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newRadio_Button(...)
if instance then
  local ok, result = pcall(function() return instance:setOnChange(nil) end)
  print("Radio_Button:setOnChange ->", ok, result)
end

-- ── Scroll_Bar methods ──

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- Call when you need to read scroll position.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getScrollPosition() end)
  print("Scroll_Bar:getScrollPosition ->", ok, result)
end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- Call when you need to assign scroll position.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setScrollPosition(nil) end)
  print("Scroll_Bar:setScrollPosition ->", ok, result)
end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- Call when you need to read content size.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getContentSize() end)
  print("Scroll_Bar:getContentSize ->", ok, result)
end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- Call when you need to assign content size.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setContentSize(nil) end)
  print("Scroll_Bar:setContentSize ->", ok, result)
end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- Call when you need to read view size.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getViewSize() end)
  print("Scroll_Bar:getViewSize ->", ok, result)
end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- Call when you need to assign view size.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setViewSize(nil) end)
  print("Scroll_Bar:setViewSize ->", ok, result)
end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- Call when you need to check is vertical.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:isVertical() end)
  print("Scroll_Bar:isVertical ->", ok, result)
end

--@api-stub: Scroll_Bar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Call when you need to assign on change.
-- Build a Scroll_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScroll_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setOnChange(nil) end)
  print("Scroll_Bar:setOnChange ->", ok, result)
end

-- ── Gui_Window methods ──

--@api-stub: Gui_Window:getTitle
-- Returns the title of this Gui_Window widget.
-- Call when you need to read title.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:getTitle() end)
  print("Gui_Window:getTitle ->", ok, result)
end

--@api-stub: Gui_Window:setTitle
-- Sets the title for this Gui_Window widget.
-- Call when you need to assign title.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:setTitle(nil) end)
  print("Gui_Window:setTitle ->", ok, result)
end

--@api-stub: Gui_Window:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- Call when you need to check is closeable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:isCloseable() end)
  print("Gui_Window:isCloseable ->", ok, result)
end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- Call when you need to assign closeable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:setCloseable(nil) end)
  print("Gui_Window:setCloseable ->", ok, result)
end

--@api-stub: Gui_Window:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- Call when you need to check is draggable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:isDraggable() end)
  print("Gui_Window:isDraggable ->", ok, result)
end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- Call when you need to assign draggable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:setDraggable(nil) end)
  print("Gui_Window:setDraggable ->", ok, result)
end

--@api-stub: Gui_Window:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- Call when you need to check is resizable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:isResizable() end)
  print("Gui_Window:isResizable ->", ok, result)
end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable for this Gui_Window widget.
-- Call when you need to assign resizable.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:setResizable(nil) end)
  print("Gui_Window:setResizable ->", ok, result)
end

--@api-stub: Gui_Window:setOnClose
-- Registers a callback invoked when this window is closed.
-- Call when you need to assign on close.
-- Build a Gui_Window via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Window(...)
if instance then
  local ok, result = pcall(function() return instance:setOnClose(nil) end)
  print("Gui_Window:setOnClose ->", ok, result)
end

-- ── Split_Panel methods ──

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- Call when you need to read orientation.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getOrientation() end)
  print("Split_Panel:getOrientation ->", ok, result)
end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- Call when you need to assign orientation.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setOrientation(nil) end)
  print("Split_Panel:setOrientation ->", ok, result)
end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- Call when you need to read split position.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getSplitPosition() end)
  print("Split_Panel:getSplitPosition ->", ok, result)
end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- Call when you need to assign split position.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setSplitPosition(nil) end)
  print("Split_Panel:setSplitPosition ->", ok, result)
end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- Call when you need to read min panel size.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getMinPanelSize() end)
  print("Split_Panel:getMinPanelSize ->", ok, result)
end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- Call when you need to assign min panel size.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setMinPanelSize(nil) end)
  print("Split_Panel:setMinPanelSize ->", ok, result)
end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- Call when you need to assign first child.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setFirstChild(1) end)
  print("Split_Panel:setFirstChild ->", ok, result)
end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- Call when you need to assign second child.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setSecondChild(1) end)
  print("Split_Panel:setSecondChild ->", ok, result)
end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- Call when you need to read first child.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getFirstChild() end)
  print("Split_Panel:getFirstChild ->", ok, result)
end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- Call when you need to read second child.
-- Build a Split_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newSplit_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getSecondChild() end)
  print("Split_Panel:getSecondChild ->", ok, result)
end

-- ── Dock_Panel methods ──

--@api-stub: Dock_Panel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- Call when you need to invoke dock.
-- Build a Dock_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDock_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:dock(1, nil) end)
  print("Dock_Panel:dock ->", ok, result)
end

--@api-stub: Dock_Panel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- Call when you need to invoke undock.
-- Build a Dock_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDock_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:undock(1) end)
  print("Dock_Panel:undock ->", ok, result)
end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- Call when you need to read docked count.
-- Build a Dock_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDock_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getDockedCount() end)
  print("Dock_Panel:getDockedCount ->", ok, result)
end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- Call when you need to assign split size.
-- Build a Dock_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDock_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setSplitSize(nil, 10) end)
  print("Dock_Panel:setSplitSize ->", ok, result)
end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- Call when you need to read split size.
-- Build a Dock_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDock_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getSplitSize(nil) end)
  print("Dock_Panel:getSplitSize ->", ok, result)
end

-- ── Toolbar methods ──

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- Call when you need to read orientation.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:getOrientation() end)
  print("Toolbar:getOrientation ->", ok, result)
end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- Call when you need to assign orientation.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:setOrientation(nil) end)
  print("Toolbar:setOrientation ->", ok, result)
end

--@api-stub: Toolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- Call when you need to add button.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:addButton(1, nil) end)
  print("Toolbar:addButton ->", ok, result)
end

--@api-stub: Toolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- Call when you need to add separator.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:addSeparator() end)
  print("Toolbar:addSeparator ->", ok, result)
end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- Call when you need to add spacer.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:addSpacer(10) end)
  print("Toolbar:addSpacer ->", ok, result)
end

--@api-stub: Toolbar:getButton
-- Returns the button of this Toolbar widget.
-- Call when you need to read button.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:getButton(1) end)
  print("Toolbar:getButton ->", ok, result)
end

--@api-stub: Toolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- Call when you need to assign button enabled.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:setButtonEnabled(1, nil) end)
  print("Toolbar:setButtonEnabled ->", ok, result)
end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- Call when you need to assign button toggled.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:setButtonToggled(1, nil) end)
  print("Toolbar:setButtonToggled ->", ok, result)
end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- Call when you need to check is button toggled.
-- Build a Toolbar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newToolbar(...)
if instance then
  local ok, result = pcall(function() return instance:isButtonToggled(1) end)
  print("Toolbar:isButtonToggled ->", ok, result)
end

-- ── Menu_Bar methods ──

--@api-stub: Menu_Bar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- Call when you need to add menu.
-- Build a Menu_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:addMenu(1) end)
  print("Menu_Bar:addMenu ->", ok, result)
end

--@api-stub: Menu_Bar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- Call when you need to remove menu.
-- Build a Menu_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:removeMenu(1) end)
  print("Menu_Bar:removeMenu ->", ok, result)
end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- Call when you need to read menus.
-- Build a Menu_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getMenus() end)
  print("Menu_Bar:getMenus ->", ok, result)
end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- Call when you need to read menu count.
-- Build a Menu_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getMenuCount() end)
  print("Menu_Bar:getMenuCount ->", ok, result)
end

-- ── Menu_Item methods ──

--@api-stub: Menu_Item:getText
-- Returns the text of this Menu_Item widget.
-- Call when you need to read text.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Menu_Item:getText ->", ok, result)
end

--@api-stub: Menu_Item:setText
-- Sets the text for this Menu_Item widget.
-- Call when you need to assign text.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Menu_Item:setText ->", ok, result)
end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- Call when you need to read shortcut.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:getShortcut() end)
  print("Menu_Item:getShortcut ->", ok, result)
end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- Call when you need to assign shortcut.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:setShortcut(nil) end)
  print("Menu_Item:setShortcut ->", ok, result)
end

--@api-stub: Menu_Item:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- Call when you need to check is checked.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:isChecked() end)
  print("Menu_Item:isChecked ->", ok, result)
end

--@api-stub: Menu_Item:setChecked
-- Sets the checked for this Menu_Item widget.
-- Call when you need to assign checked.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:setChecked(nil) end)
  print("Menu_Item:setChecked ->", ok, result)
end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- Call when you need to add sub item.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:addSubItem(1) end)
  print("Menu_Item:addSubItem ->", ok, result)
end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- Call when you need to read sub items.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:getSubItems() end)
  print("Menu_Item:getSubItems ->", ok, result)
end

--@api-stub: Menu_Item:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- Call when you need to assign on click.
-- Build a Menu_Item via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newMenu_Item(...)
if instance then
  local ok, result = pcall(function() return instance:setOnClick(nil) end)
  print("Menu_Item:setOnClick ->", ok, result)
end

-- ── Dialog methods ──

--@api-stub: Dialog:getTitle
-- Returns the title of this Dialog widget.
-- Call when you need to read title.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:getTitle() end)
  print("Dialog:getTitle ->", ok, result)
end

--@api-stub: Dialog:setTitle
-- Sets the title for this Dialog widget.
-- Call when you need to assign title.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:setTitle(nil) end)
  print("Dialog:setTitle ->", ok, result)
end

--@api-stub: Dialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- Call when you need to check is modal.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:isModal() end)
  print("Dialog:isModal ->", ok, result)
end

--@api-stub: Dialog:setModal
-- Sets the modal for this Dialog widget.
-- Call when you need to assign modal.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:setModal(nil) end)
  print("Dialog:setModal ->", ok, result)
end

--@api-stub: Dialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- Call when you need to check is open.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:isOpen() end)
  print("Dialog:isOpen ->", ok, result)
end

--@api-stub: Dialog:open
-- Performs the open operation on this Dialog widget.
-- Call when you need to invoke open.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:open() end)
  print("Dialog:open ->", ok, result)
end

--@api-stub: Dialog:close
-- Closes and removes this dialog from the screen.
-- Call when you need to invoke close.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:close() end)
  print("Dialog:close ->", ok, result)
end

--@api-stub: Dialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- Call when you need to assign on close.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:setOnClose(nil) end)
  print("Dialog:setOnClose ->", ok, result)
end

--@api-stub: Dialog:setContent
-- Sets the content for this Dialog widget.
-- Call when you need to assign content.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:setContent(1) end)
  print("Dialog:setContent ->", ok, result)
end

--@api-stub: Dialog:getContent
-- Returns the content of this Dialog widget.
-- Call when you need to read content.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:getContent() end)
  print("Dialog:getContent ->", ok, result)
end

--@api-stub: Dialog:addButton
-- Adds a button entry to this Dialog widget.
-- Call when you need to add button.
-- Build a Dialog via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newDialog(...)
if instance then
  local ok, result = pcall(function() return instance:addButton("text value", function() end) end)
  print("Dialog:addButton ->", ok, result)
end

-- ── Status_Bar methods ──

--@api-stub: Status_Bar:addSection
-- Adds a section entry to this Status_Bar widget.
-- Call when you need to add section.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:addSection("text value", 100) end)
  print("Status_Bar:addSection ->", ok, result)
end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- Call when you need to assign section text.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setSectionText(1, "text value") end)
  print("Status_Bar:setSectionText ->", ok, result)
end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- Call when you need to read section text.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getSectionText(1) end)
  print("Status_Bar:getSectionText ->", ok, result)
end

--@api-stub: Status_Bar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- Call when you need to read section count.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:getSectionCount() end)
  print("Status_Bar:getSectionCount ->", ok, result)
end

--@api-stub: Status_Bar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- Call when you need to assign section count.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setSectionCount(10) end)
  print("Status_Bar:setSectionCount ->", ok, result)
end

--@api-stub: Status_Bar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- Call when you need to assign section widget.
-- Build a Status_Bar via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newStatus_Bar(...)
if instance then
  local ok, result = pcall(function() return instance:setSectionWidget(1, nil) end)
  print("Status_Bar:setSectionWidget ->", ok, result)
end

-- ── Accordion methods ──

--@api-stub: Accordion:addSection
-- Adds a section entry to this Accordion widget.
-- Call when you need to add section.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:addSection(nil, 1) end)
  print("Accordion:addSection ->", ok, result)
end

--@api-stub: Accordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- Call when you need to read section count.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:getSectionCount() end)
  print("Accordion:getSectionCount ->", ok, result)
end

--@api-stub: Accordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- Call when you need to invoke toggle section.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:toggleSection(1) end)
  print("Accordion:toggleSection ->", ok, result)
end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- Call when you need to check is section expanded.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:isSectionExpanded(1) end)
  print("Accordion:isSectionExpanded ->", ok, result)
end

--@api-stub: Accordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- Call when you need to check is exclusive.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:isExclusive() end)
  print("Accordion:isExclusive ->", ok, result)
end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- Call when you need to assign exclusive.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:setExclusive(nil) end)
  print("Accordion:setExclusive ->", ok, result)
end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- Call when you need to read section title.
-- Build a Accordion via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAccordion(...)
if instance then
  local ok, result = pcall(function() return instance:getSectionTitle(1) end)
  print("Accordion:getSectionTitle ->", ok, result)
end

-- ── Tooltip_Panel methods ──

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this Tooltip_Panel widget.
-- Call when you need to read text.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Tooltip_Panel:getText ->", ok, result)
end

--@api-stub: Tooltip_Panel:setText
-- Sets the text for this Tooltip_Panel widget.
-- Call when you need to assign text.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Tooltip_Panel:setText ->", ok, result)
end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- Call when you need to read delay.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getDelay() end)
  print("Tooltip_Panel:getDelay ->", ok, result)
end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- Call when you need to assign delay.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setDelay(nil) end)
  print("Tooltip_Panel:setDelay ->", ok, result)
end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- Call when you need to read target.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:getTarget() end)
  print("Tooltip_Panel:getTarget ->", ok, result)
end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- Call when you need to assign target.
-- Build a Tooltip_Panel via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newTooltip_Panel(...)
if instance then
  local ok, result = pcall(function() return instance:setTarget(nil) end)
  print("Tooltip_Panel:setTarget ->", ok, result)
end

-- ── Color_Picker methods ──

--@api-stub: Color_Picker:getColor
-- Returns the color of this Color_Picker widget.
-- Call when you need to read color.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:getColor() end)
  print("Color_Picker:getColor ->", ok, result)
end

--@api-stub: Color_Picker:setColor
-- Sets the color for this Color_Picker widget.
-- Call when you need to assign color.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:setColor(1, 1, 1, 1) end)
  print("Color_Picker:setColor ->", ok, result)
end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- Call when you need to read show alpha.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:getShowAlpha() end)
  print("Color_Picker:getShowAlpha ->", ok, result)
end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- Call when you need to assign show alpha.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:setShowAlpha(nil) end)
  print("Color_Picker:setShowAlpha ->", ok, result)
end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- Call when you need to read color mode.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:getColorMode() end)
  print("Color_Picker:getColorMode ->", ok, result)
end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- Call when you need to assign color mode.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:setColorMode(nil) end)
  print("Color_Picker:setColorMode ->", ok, result)
end

--@api-stub: Color_Picker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Call when you need to assign on change.
-- Build a Color_Picker via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newColor_Picker(...)
if instance then
  local ok, result = pcall(function() return instance:setOnChange(nil) end)
  print("Color_Picker:setOnChange ->", ok, result)
end

-- ── Gui_Table methods ──

--@api-stub: Gui_Table:addColumn
-- Adds a column entry to this Gui_Table widget.
-- Call when you need to add column.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:addColumn(nil, 100) end)
  print("Gui_Table:addColumn ->", ok, result)
end

--@api-stub: Gui_Table:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- Call when you need to read column count.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:getColumnCount() end)
  print("Gui_Table:getColumnCount ->", ok, result)
end

--@api-stub: Gui_Table:addRow
-- Adds a row entry to this Gui_Table widget.
-- Call when you need to add row.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:addRow(nil) end)
  print("Gui_Table:addRow ->", ok, result)
end

--@api-stub: Gui_Table:getRowCount
-- Returns the row count of this Gui_Table widget.
-- Call when you need to read row count.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:getRowCount() end)
  print("Gui_Table:getRowCount ->", ok, result)
end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this Gui_Table widget.
-- Call when you need to read cell.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:getCell(nil, nil) end)
  print("Gui_Table:getCell ->", ok, result)
end

--@api-stub: Gui_Table:setCell
-- Sets the cell for this Gui_Table widget.
-- Call when you need to assign cell.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:setCell(nil, nil, "text value") end)
  print("Gui_Table:setCell ->", ok, result)
end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- Call when you need to read selected row.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:getSelectedRow() end)
  print("Gui_Table:getSelectedRow ->", ok, result)
end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- Call when you need to assign selected row.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:setSelectedRow(nil) end)
  print("Gui_Table:setSelectedRow ->", ok, result)
end

--@api-stub: Gui_Table:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- Call when you need to check is sortable.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:isSortable() end)
  print("Gui_Table:isSortable ->", ok, result)
end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable for this Gui_Table widget.
-- Call when you need to assign sortable.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:setSortable(nil) end)
  print("Gui_Table:setSortable ->", ok, result)
end

--@api-stub: Gui_Table:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- Call when you need to assign on select.
-- Build a Gui_Table via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newGui_Table(...)
if instance then
  local ok, result = pcall(function() return instance:setOnSelect(nil) end)
  print("Gui_Table:setOnSelect ->", ok, result)
end

-- ── Image_Widget methods ──

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- Call when you need to read scale mode.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getScaleMode() end)
  print("Image_Widget:getScaleMode ->", ok, result)
end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- Call when you need to assign scale mode.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setScaleMode(nil) end)
  print("Image_Widget:setScaleMode ->", ok, result)
end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this Image_Widget widget.
-- Call when you need to read tint.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getTint() end)
  print("Image_Widget:getTint ->", ok, result)
end

--@api-stub: Image_Widget:setTint
-- Sets the tint for this Image_Widget widget.
-- Call when you need to assign tint.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setTint(1, 1, 1, 1) end)
  print("Image_Widget:setTint ->", ok, result)
end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- Call when you need to create a new button.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newButton("text value") end)
  print("Image_Widget:newButton ->", ok, result)
end

--@api-stub: Image_Widget:newLabel
-- Creates a text label widget.
-- Call when you need to create a new label.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newLabel("text value") end)
  print("Image_Widget:newLabel ->", ok, result)
end

--@api-stub: Image_Widget:newTextInput
-- Creates a text input widget.
-- Call when you need to create a new text input.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTextInput() end)
  print("Image_Widget:newTextInput ->", ok, result)
end

--@api-stub: Image_Widget:newCheckbox
-- Creates a checkbox widget.
-- Call when you need to create a new checkbox.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newCheckbox("text value") end)
  print("Image_Widget:newCheckbox ->", ok, result)
end

--@api-stub: Image_Widget:newSlider
-- Creates a value slider widget.
-- Call when you need to create a new slider.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSlider(0, 100) end)
  print("Image_Widget:newSlider ->", ok, result)
end

--@api-stub: Image_Widget:newProgressBar
-- Creates a progress bar widget.
-- Call when you need to create a new progress bar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newProgressBar(0, 100) end)
  print("Image_Widget:newProgressBar ->", ok, result)
end

--@api-stub: Image_Widget:newComboBox
-- Creates a dropdown combo box widget.
-- Call when you need to create a new combo box.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newComboBox() end)
  print("Image_Widget:newComboBox ->", ok, result)
end

--@api-stub: Image_Widget:newList
-- Creates a selectable list widget.
-- Call when you need to create a new list.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newList() end)
  print("Image_Widget:newList ->", ok, result)
end

--@api-stub: Image_Widget:newPanel
-- Creates a container panel widget.
-- Call when you need to create a new panel.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newPanel() end)
  print("Image_Widget:newPanel ->", ok, result)
end

--@api-stub: Image_Widget:newLayout
-- Creates a flexbox layout container.
-- Call when you need to create a new layout.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newLayout("direction") end)
  print("Image_Widget:newLayout ->", ok, result)
end

--@api-stub: Image_Widget:newScrollPanel
-- Creates a scrollable panel widget.
-- Call when you need to create a new scroll panel.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newScrollPanel() end)
  print("Image_Widget:newScrollPanel ->", ok, result)
end

--@api-stub: Image_Widget:newNinePatch
-- Creates a 9-patch slicer widget.
-- Call when you need to create a new nine patch.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newNinePatch() end)
  print("Image_Widget:newNinePatch ->", ok, result)
end

--@api-stub: Image_Widget:newTabBar
-- Creates a tab bar widget.
-- Call when you need to create a new tab bar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTabBar() end)
  print("Image_Widget:newTabBar ->", ok, result)
end

--@api-stub: Image_Widget:newSeparator
-- Creates a separator line.
-- Call when you need to create a new separator.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSeparator(nil) end)
  print("Image_Widget:newSeparator ->", ok, result)
end

--@api-stub: Image_Widget:newSpacer
-- Creates a spacing filler widget.
-- Call when you need to create a new spacer.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSpacer(100, 100) end)
  print("Image_Widget:newSpacer ->", ok, result)
end

--@api-stub: Image_Widget:newToast
-- Creates a toast notification widget.
-- Call when you need to create a new toast.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newToast(nil, 1.0) end)
  print("Image_Widget:newToast ->", ok, result)
end

--@api-stub: Image_Widget:newTreeView
-- Creates a collapsible tree view widget.
-- Call when you need to create a new tree view.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTreeView() end)
  print("Image_Widget:newTreeView ->", ok, result)
end

--@api-stub: Image_Widget:newRadioButton
-- Creates a grouped radio button widget.
-- Call when you need to create a new radio button.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newRadioButton("text value", nil) end)
  print("Image_Widget:newRadioButton ->", ok, result)
end

--@api-stub: Image_Widget:newScrollBar
-- Creates a scroll bar widget.
-- Call when you need to create a new scroll bar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newScrollBar(nil) end)
  print("Image_Widget:newScrollBar ->", ok, result)
end

--@api-stub: Image_Widget:newWindow
-- Creates a draggable window widget.
-- Call when you need to create a new window.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newWindow(nil) end)
  print("Image_Widget:newWindow ->", ok, result)
end

--@api-stub: Image_Widget:newSplitPanel
-- Creates a resizable split panel.
-- Call when you need to create a new split panel.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSplitPanel(nil) end)
  print("Image_Widget:newSplitPanel ->", ok, result)
end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- Call when you need to create a new dock panel.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newDockPanel() end)
  print("Image_Widget:newDockPanel ->", ok, result)
end

--@api-stub: Image_Widget:newToolbar
-- Creates a toolbar widget.
-- Call when you need to create a new toolbar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newToolbar(nil) end)
  print("Image_Widget:newToolbar ->", ok, result)
end

--@api-stub: Image_Widget:newMenuBar
-- Creates a menu bar widget.
-- Call when you need to create a new menu bar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newMenuBar() end)
  print("Image_Widget:newMenuBar ->", ok, result)
end

--@api-stub: Image_Widget:newMenuItem
-- Creates a menu item widget.
-- Call when you need to create a new menu item.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newMenuItem("text value") end)
  print("Image_Widget:newMenuItem ->", ok, result)
end

--@api-stub: Image_Widget:newDialog
-- Creates a modal dialog widget.
-- Call when you need to create a new dialog.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newDialog(nil) end)
  print("Image_Widget:newDialog ->", ok, result)
end

--@api-stub: Image_Widget:newStatusBar
-- Creates a status bar widget.
-- Call when you need to create a new status bar.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newStatusBar() end)
  print("Image_Widget:newStatusBar ->", ok, result)
end

--@api-stub: Image_Widget:newAccordion
-- Creates a collapsible accordion widget.
-- Call when you need to create a new accordion.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newAccordion() end)
  print("Image_Widget:newAccordion ->", ok, result)
end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates a tooltip panel widget.
-- Call when you need to create a new tooltip panel.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTooltipPanel("text value") end)
  print("Image_Widget:newTooltipPanel ->", ok, result)
end

--@api-stub: Image_Widget:newColorPicker
-- Creates a color picker widget.
-- Call when you need to create a new color picker.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newColorPicker() end)
  print("Image_Widget:newColorPicker ->", ok, result)
end

--@api-stub: Image_Widget:newTable
-- Creates a data table widget.
-- Call when you need to create a new table.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTable() end)
  print("Image_Widget:newTable ->", ok, result)
end

--@api-stub: Image_Widget:newImageWidget
-- Creates an image display widget.
-- Call when you need to create a new image widget.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newImageWidget() end)
  print("Image_Widget:newImageWidget ->", ok, result)
end

--@api-stub: Image_Widget:newTheme
-- Creates a new theme instance.
-- Call when you need to create a new theme.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newTheme() end)
  print("Image_Widget:newTheme ->", ok, result)
end

--@api-stub: Image_Widget:setTheme
-- Sets the active GUI theme.
-- Call when you need to assign theme.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setTheme(nil) end)
  print("Image_Widget:setTheme ->", ok, result)
end

--@api-stub: Image_Widget:getTheme
-- Returns whether a theme is set.
-- Call when you need to read theme.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getTheme() end)
  print("Image_Widget:getTheme ->", ok, result)
end

--@api-stub: Image_Widget:getRoot
-- Returns the root panel widget table.
-- Call when you need to read root.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getRoot() end)
  print("Image_Widget:getRoot ->", ok, result)
end

--@api-stub: Image_Widget:setFocus
-- Sets keyboard focus to a widget or clears it.
-- Call when you need to assign focus.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setFocus(nil) end)
  print("Image_Widget:setFocus ->", ok, result)
end

--@api-stub: Image_Widget:getFocus
-- Returns the focused widget index or nil.
-- Call when you need to read focus.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getFocus() end)
  print("Image_Widget:getFocus ->", ok, result)
end

--@api-stub: Image_Widget:focusNext
-- Moves focus to the next focusable widget.
-- Call when you need to invoke focus next.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:focusNext() end)
  print("Image_Widget:focusNext ->", ok, result)
end

--@api-stub: Image_Widget:focusPrev
-- Moves focus to the previous focusable widget.
-- Call when you need to invoke focus prev.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:focusPrev() end)
  print("Image_Widget:focusPrev ->", ok, result)
end

--@api-stub: Image_Widget:clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- Call when you need to invoke clear focus.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:clearFocus() end)
  print("Image_Widget:clearFocus ->", ok, result)
end

--@api-stub: Image_Widget:addToast
-- Queues a toast notification from a table.
-- Call when you need to add toast.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:addToast({}) end)
  print("Image_Widget:addToast ->", ok, result)
end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of active toasts.
-- Call when you need to read toast count.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getToastCount() end)
  print("Image_Widget:getToastCount ->", ok, result)
end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to the GUI.
-- Call when you need to invoke mousepressed.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:mousepressed(0, 0, nil) end)
  print("Image_Widget:mousepressed ->", ok, result)
end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to the GUI.
-- Call when you need to invoke mousereleased.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:mousereleased(0, 0, nil) end)
  print("Image_Widget:mousereleased ->", ok, result)
end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to the GUI.
-- Call when you need to invoke mousemoved.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:mousemoved(0, 0) end)
  print("Image_Widget:mousemoved ->", ok, result)
end

--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to the GUI.
-- Call when you need to invoke keypressed.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:keypressed("key") end)
  print("Image_Widget:keypressed ->", ok, result)
end

--@api-stub: Image_Widget:textinput
-- Forwards text input to the focused text input widget.
-- Call when you need to invoke textinput.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:textinput("text value") end)
  print("Image_Widget:textinput ->", ok, result)
end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- Call when you need to invoke wheelmoved.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:wheelmoved(0, 0) end)
  print("Image_Widget:wheelmoved ->", ok, result)
end

--@api-stub: Image_Widget:update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- Call when you need to invoke update.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Image_Widget:update ->", ok, result)
end

--@api-stub: Image_Widget:draw
-- Headless compatibility stub for GUI draw.
-- Call when you need to invoke draw.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:draw() end)
  print("Image_Widget:draw ->", ok, result)
end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the total widget count in the context.
-- Call when you need to read widget count.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:getWidgetCount() end)
  print("Image_Widget:getWidgetCount ->", ok, result)
end

--@api-stub: Image_Widget:drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- Call when you need to render to image.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("Image_Widget:drawToImage ->", ok, result)
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call when you need to create a new line chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newLineChart({}) end)
  print("Image_Widget:newLineChart ->", ok, result)
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call when you need to create a new bar chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newBarChart({}) end)
  print("Image_Widget:newBarChart ->", ok, result)
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call when you need to create a new scatter plot.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newScatterPlot({}) end)
  print("Image_Widget:newScatterPlot ->", ok, result)
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call when you need to create a new pie chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newPieChart({}) end)
  print("Image_Widget:newPieChart ->", ok, result)
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call when you need to create a new area chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newAreaChart({}) end)
  print("Image_Widget:newAreaChart ->", ok, result)
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call when you need to create a new line chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newLineChart({}) end)
  print("Image_Widget:newLineChart ->", ok, result)
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call when you need to create a new bar chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newBarChart({}) end)
  print("Image_Widget:newBarChart ->", ok, result)
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call when you need to create a new scatter plot.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newScatterPlot({}) end)
  print("Image_Widget:newScatterPlot ->", ok, result)
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call when you need to create a new pie chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newPieChart({}) end)
  print("Image_Widget:newPieChart ->", ok, result)
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call when you need to create a new area chart.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newAreaChart({}) end)
  print("Image_Widget:newAreaChart ->", ok, result)
end

--@api-stub: Image_Widget:parseWidgetState
-- Parses a widget state string, returning the canonical form or nil if invalid.
-- Call when you need to invoke parse widget state.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:parseWidgetState(nil) end)
  print("Image_Widget:parseWidgetState ->", ok, result)
end

--@api-stub: Image_Widget:newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- Call when you need to create a new spin box.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSpinBox(0, 100) end)
  print("Image_Widget:newSpinBox ->", ok, result)
end

--@api-stub: Image_Widget:newSwitch
-- Creates a toggle switch widget.
-- Call when you need to create a new switch.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newSwitch(nil) end)
  print("Image_Widget:newSwitch ->", ok, result)
end

--@api-stub: Image_Widget:newBadge
-- Creates a badge widget displaying a numeric count.
-- Call when you need to create a new badge.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:newBadge(10) end)
  print("Image_Widget:newBadge ->", ok, result)
end

--@api-stub: Image_Widget:setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- Call when you need to assign default theme.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setDefaultTheme() end)
  print("Image_Widget:setDefaultTheme ->", ok, result)
end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- Call when you need to assign viewport.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:setViewport(100, 100) end)
  print("Image_Widget:setViewport ->", ok, result)
end

--@api-stub: Image_Widget:flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- Call when you need to invoke flush cache.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:flushCache() end)
  print("Image_Widget:flushCache ->", ok, result)
end

--@api-stub: Image_Widget:update_bindings
-- Updates all widgets that have a data-binding key registered via `:bind(key)`.
-- Call when you need to invoke update_bindings.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:update_bindings() end)
  print("Image_Widget:update_bindings ->", ok, result)
end

--@api-stub: Image_Widget:loadLayout
-- Load a widget tree from a Lua table definition and attach it to the UI.
-- Call when you need to load layout.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:loadLayout() end)
  print("Image_Widget:loadLayout ->", ok, result)
end

--@api-stub: Image_Widget:loadLayoutFile
-- Load a widget tree from a TOML layout file and attach it to the UI root.
-- Call when you need to load layout file.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:loadLayoutFile("path") end)
  print("Image_Widget:loadLayoutFile ->", ok, result)
end

--@api-stub: Image_Widget:renderToImage
-- Render the current UI widget tree to a PNG file for testing purposes.
-- Call when you need to invoke render to image.
-- Build a Image_Widget via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newImage_Widget(...)
if instance then
  local ok, result = pcall(function() return instance:renderToImage(100, 100, "path") end)
  print("Image_Widget:renderToImage ->", ok, result)
end

-- ── LineChart methods ──

--@api-stub: LineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Call when you need to assign y max.
-- Build a LineChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLineChart(...)
if instance then
  local ok, result = pcall(function() return instance:setYMax(nil) end)
  print("LineChart:setYMax ->", ok, result)
end

--@api-stub: LineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Call when you need to assign x max.
-- Build a LineChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLineChart(...)
if instance then
  local ok, result = pcall(function() return instance:setXMax(nil) end)
  print("LineChart:setXMax ->", ok, result)
end

--@api-stub: LineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Call when you need to render to image.
-- Build a LineChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newLineChart(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage() end)
  print("LineChart:drawToImage ->", ok, result)
end

-- ── BarChart methods ──

--@api-stub: BarChart:drawToImage
-- Renders the bar chart into an existing ImageData.
-- Call when you need to render to image.
-- Build a BarChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newBarChart(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage() end)
  print("BarChart:drawToImage ->", ok, result)
end

-- ── ScatterPlot methods ──

--@api-stub: ScatterPlot:setXRange
-- Sets the X-axis data range.
-- Call when you need to assign x range.
-- Build a ScatterPlot via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScatterPlot(...)
if instance then
  local ok, result = pcall(function() return instance:setXRange(nil, nil) end)
  print("ScatterPlot:setXRange ->", ok, result)
end

--@api-stub: ScatterPlot:setYRange
-- Sets the Y-axis data range.
-- Call when you need to assign y range.
-- Build a ScatterPlot via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScatterPlot(...)
if instance then
  local ok, result = pcall(function() return instance:setYRange(nil, nil) end)
  print("ScatterPlot:setYRange ->", ok, result)
end

--@api-stub: ScatterPlot:drawToImage
-- Renders the scatter plot into an existing ImageData.
-- Call when you need to render to image.
-- Build a ScatterPlot via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newScatterPlot(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage() end)
  print("ScatterPlot:drawToImage ->", ok, result)
end

-- ── PieChart methods ──

--@api-stub: PieChart:drawToImage
-- Renders the pie chart into an existing ImageData.
-- Call when you need to render to image.
-- Build a PieChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newPieChart(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage() end)
  print("PieChart:drawToImage ->", ok, result)
end

-- ── AreaChart methods ──

--@api-stub: AreaChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Call when you need to assign y max.
-- Build a AreaChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAreaChart(...)
if instance then
  local ok, result = pcall(function() return instance:setYMax(nil) end)
  print("AreaChart:setYMax ->", ok, result)
end

--@api-stub: AreaChart:drawToImage
-- Renders the area chart into an existing ImageData.
-- Call when you need to render to image.
-- Build a AreaChart via the appropriate lurek.ui.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ui.newAreaChart(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage() end)
  print("AreaChart:drawToImage ->", ok, result)
end

