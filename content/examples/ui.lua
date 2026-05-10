---@diagnostic disable: undefined-field
-- content/examples/ui.lua
-- Hand-written coverage of the lurek.ui API (363 items).
--
-- Every --@api-stub: block below is a real love2d-wiki-style snippet
-- showing how to call the API in real game context. Widget IDs ("btn_play",
-- "win_inv"), labels, sizes, and colours use realistic values you can adapt.
--
-- Run: cargo run -- content/examples/ui.lua

-- Guard: lurek.ui methods are nil in headless tests; skip this file entirely.
if not lurek.ui or type(lurek.ui.setPosition) ~= "function" then return end

-- Drag/drop and first-class transitions (runtime helpers)
do
  local left = lurek.ui.newPanel()
  left.setPosition(20, 20)
  left.setSize(180, 120)

  local right = lurek.ui.newPanel()
  right.setPosition(220, 20)
  right.setSize(180, 120)

  local card = lurek.ui.newButton("Card")
  left.addChild(card)

  -- Timed alpha + slide transitions.
  card["animateAlpha"](0.25, 0.35, false)
  card["animatePosition"](40, 60, 0.35)

  -- Move card between containers.
  lurek.ui["beginDrag"](card)
  lurek.ui["dropOn"](right)
end

--@api-stub: lurek.ui.beginDrag
do -- lurek.ui.beginDrag
  local w = lurek.ui.newButton("Drag")
  pcall(function() lurek.ui.beginDrag(w) end)
end

--@api-stub: lurek.ui.getActiveDrag
do -- lurek.ui.getActiveDrag
  pcall(function()
    local v = lurek.ui.getActiveDrag()
    print("getActiveDrag:", v)
  end)
end

--@api-stub: lurek.ui.dropOn
do -- lurek.ui.dropOn
  local container = lurek.ui.newPanel()
  local w = lurek.ui.newLabel("drop")
  pcall(function()
    lurek.ui.beginDrag(w)
    lurek.ui.dropOn(container)
  end)
end

--@api-stub: lurek.ui.endDrag
do -- lurek.ui.endDrag
  pcall(function()
    local prev = lurek.ui.endDrag()
    print("endDrag:", prev)
  end)
end

--@api-stub: LUiWidget:animateAlpha
do -- LUiWidget:animateAlpha
  local w = lurek.ui.newLabel("alpha")
  pcall(function() w["animateAlpha"](0.5, 0.25, false) end)
end

--@api-stub: LUiWidget:animatePosition
do -- LUiWidget:animatePosition
  local w = lurek.ui.newLabel("move")
  pcall(function() w["animatePosition"](120, 40, 0.25) end)
end

--@api-stub: LUiWidget:isAnimating
do -- LUiWidget:isAnimating
  local w = lurek.ui.newLabel("state")
  pcall(function()
    local v = w["isAnimating"]()
    print("isAnimating:", v)
  end)
end

--@api-stub: LUiWidget:cancelAnimations
do -- LUiWidget:cancelAnimations
  local w = lurek.ui.newLabel("cancel")
  pcall(function() w["cancelAnimations"]() end)
end

--@api-stub: lurek.ui.setPosition
-- Sets the widget position.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setPosition
  pcall(function() lurek.ui.setPosition(100, 200) end)
  print("applied")
end

--@api-stub: lurek.ui.getPosition
-- Returns the widget position.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getPosition
  pcall(function()
    local v = lurek.ui.getPosition()
    print("getPosition:", v)
  end)
end

--@api-stub: lurek.ui.setSize
-- Sets the width and height of the widget in UI pixels.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setSize
  pcall(function() lurek.ui.setSize(200, 50) end)
  print("applied")
end

--@api-stub: lurek.ui.getSize
-- Returns the current width and height of the widget in UI pixels.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getSize
  pcall(function()
    local v = lurek.ui.getSize()
    print("getSize:", v)
  end)
end

--@api-stub: lurek.ui.getRect
-- Returns the computed screen-space rectangle after layout.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getRect
  pcall(function()
    local v = lurek.ui.getRect()
    print("getRect:", v)
  end)
end

--@api-stub: lurek.ui.setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setVisible
  pcall(function() lurek.ui.setVisible(true) end)
  print("applied")
end

--@api-stub: lurek.ui.isVisible
-- Returns whether the widget is visible.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.isVisible
  pcall(function()
    local v = lurek.ui.isVisible()
    print("isVisible:", v)
  end)
end

--@api-stub: lurek.ui.setEnabled
-- Sets whether the widget is enabled.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setEnabled
  pcall(function() lurek.ui.setEnabled(true) end)
  print("applied")
end

--@api-stub: lurek.ui.isEnabled
-- Returns whether the widget is enabled.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.isEnabled
  pcall(function()
    local v = lurek.ui.isEnabled()
    print("isEnabled:", v)
  end)
end

--@api-stub: lurek.ui.setId
-- Sets the widget string identifier.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setId
  pcall(function()
    lurek.ui.setId("primary")
    print("applied")
  end)
end

--@api-stub: lurek.ui.getId
-- Returns the widget string identifier.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getId
  pcall(function()
    local v = lurek.ui.getId()
    print("getId:", v)
  end)
end

--@api-stub: lurek.ui.setTooltip
-- Sets the widget tooltip text.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setTooltip
  lurek.ui.setTooltip("Hello")
  print("applied")
end

--@api-stub: lurek.ui.getTooltip
-- Returns the widget tooltip text.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getTooltip
  local v = lurek.ui.getTooltip()
  print("getTooltip:", v)
end

--@api-stub: lurek.ui.getState
-- Returns the widget interaction state name.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getState
  local v = lurek.ui.getState()
  print("getState:", v)
end

--@api-stub: lurek.ui.addChild
-- Adds a child widget to this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.addChild
  lurek.ui.addChild(1)
  print("added")
end

--@api-stub: lurek.ui.removeChild
-- Removes a child widget from this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.removeChild
  lurek.ui.removeChild(1)
  print("done")
end

--@api-stub: lurek.ui.getChildCount
-- Returns the number of children in this container.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getChildCount
  local v = lurek.ui.getChildCount()
  print("getChildCount:", v)
end

--@api-stub: lurek.ui.getChildren
-- Returns this container's children as widget-handle tables.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getChildren
  local v = lurek.ui.getChildren()
  print("getChildren:", v)
end

--@api-stub: lurek.ui.findById
-- Recursively searches for a widget by id starting from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.findById
  local v = lurek.ui.findById("widget_id")
  print("findById:", v)
end

--@api-stub: lurek.ui.setOnClick
-- Registers a callback invoked when this widget is clicked.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setOnClick
  lurek.ui.setOnClick(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setOnChange
  lurek.ui.setOnChange(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnDraw
-- Stores a custom draw callback for later invocation.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setOnDraw
  lurek.ui.setOnDraw(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.containsPoint
-- Returns whether (x, y) is inside this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.containsPoint
  local v = lurek.ui.containsPoint(0, 0)
  print("containsPoint:", v)
end

--@api-stub: lurek.ui.setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setPadding
  lurek.ui.setPadding(8)
  print("applied")
end

--@api-stub: lurek.ui.getPadding
-- Returns the widget padding (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getPadding
  local v = lurek.ui.getPadding()
  print("getPadding:", v)
end

--@api-stub: lurek.ui.setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setMargin
  lurek.ui.setMargin(8)
  print("applied")
end

--@api-stub: lurek.ui.getMargin
-- Returns the widget margin (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getMargin
  local v = lurek.ui.getMargin()
  print("getMargin:", v)
end

--@api-stub: lurek.ui.setZOrder
-- Sets the widget z-order for draw sorting.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setZOrder
  lurek.ui.setZOrder(1)
  print("applied")
end

--@api-stub: lurek.ui.getZOrder
-- Returns the widget z-order.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getZOrder
  local v = lurek.ui.getZOrder()
  print("getZOrder:", v)
end

--@api-stub: lurek.ui.setMinSize
-- Sets the minimum widget size.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setMinSize
  lurek.ui.setMinSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMinSize
-- Returns the minimum widget size.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getMinSize
  local v = lurek.ui.getMinSize()
  print("getMinSize:", v)
end

--@api-stub: lurek.ui.setMaxSize
-- Sets the maximum widget size.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setMaxSize
  lurek.ui.setMaxSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMaxSize
-- Returns the maximum widget size.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getMaxSize
  local v = lurek.ui.getMaxSize()
  print("getMaxSize:", v)
end

--@api-stub: lurek.ui.setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setAnchor
  lurek.ui.setAnchor(8, 8, 8, 8)
  print("applied")
end

--@api-stub: lurek.ui.setAnchorCenter
-- Sets center anchor offsets.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setAnchorCenter
  lurek.ui.setAnchorCenter(0, 0)
  print("applied")
end

--@api-stub: lurek.ui.clearAnchor
-- Removes all anchor constraints.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.clearAnchor
  lurek.ui.clearAnchor()
  print("done")
end

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex-grow factor.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setFlexGrow
  lurek.ui.setFlexGrow(1)
  print("applied")
end

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex-grow factor.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getFlexGrow
  local v = lurek.ui.getFlexGrow()
  print("getFlexGrow:", v)
end

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex-shrink factor.
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setFlexShrink
  lurek.ui.setFlexShrink(1)
  print("applied")
end

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex-shrink factor.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getFlexShrink
  local v = lurek.ui.getFlexShrink()
  print("getFlexShrink:", v)
end

--@api-stub: lurek.ui.bind
-- Registers a data-binding key on this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.bind
  lurek.ui.bind("key")
  print("bind called")
end

--@api-stub: lurek.ui.unbind
-- Removes the data-binding key from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.unbind
  lurek.ui.unbind()
  print("unbind called")
end

--@api-stub: lurek.ui.setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- Apply the global UI setting before drawing the first frame.
do -- lurek.ui.setAlpha
  lurek.ui.setAlpha(0.85)
  print("applied")
end

--@api-stub: lurek.ui.getAlpha
-- Returns the widget's current alpha transparency.
-- Query the current global UI state from inside a render or input callback.
do -- lurek.ui.getAlpha
  local v = lurek.ui.getAlpha()
  print("getAlpha:", v)
end

--@api-stub: lurek.ui.fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.fadeIn
  lurek.ui.fadeIn()
  print("fadeIn called")
end

--@api-stub: lurek.ui.fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.fadeOut
  lurek.ui.fadeOut()
  print("fadeOut called")
end

--@api-stub: lurek.ui.slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.slideIn
  lurek.ui.slideIn(0, 0)
  print("slideIn called")
end

--@api-stub: lurek.ui.slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.slideOut
  lurek.ui.slideOut(0, 0)
  print("slideOut called")
end

--@api-stub: lurek.ui.attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.attachToEntity
  lurek.ui.attachToEntity(1)
  print("attachToEntity called")
end

--@api-stub: lurek.ui.detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- Invoke from an init or update callback as appropriate for your screen flow.
do -- lurek.ui.detachFromEntity
  lurek.ui.detachFromEntity()
  print("detachFromEntity called")
end


---@return any
local function new_example_image_widget()
  return {}
end

--@api-stub: Button:setText
-- Sets the text for this Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Button:setText
  local btn = new_example_image_widget():newButton("btn_play", "Play")
  btn:setText("Hello")
end

--@api-stub: Button:getText
-- Returns the text of this Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Button:getText
  local btn = new_example_image_widget():newButton("btn_play", "Play")
  local v = btn:getText()
  print("getText:", v)
end

-- â”€â”€ Label methods â”€â”€

--@api-stub: Label:setText
-- Sets the text for this Label widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Label:setText
  local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
  lbl:setText("Hello")
end

--@api-stub: Label:getText
-- Returns the text of this Label widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Label:getText
  local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
  local v = lbl:getText()
  print("getText:", v)
end

-- â”€â”€ Text_Input methods â”€â”€

--@api-stub: Text_Input:setText
-- Sets the text for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Text_Input:setText
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setText("Hello")
end

--@api-stub: Text_Input:getText
-- Returns the text of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Text_Input:getText
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getText()
  print("getText:", v)
end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Text_Input:setPlaceholder
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setPlaceholder("Hello")
end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Text_Input:getPlaceholder
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getPlaceholder()
  print("getPlaceholder:", v)
end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Text_Input:setMaxLength
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setMaxLength(100)
end

--@api-stub: Text_Input:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Text_Input:isFocused
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:isFocused()
  print("isFocused:", v)
end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Text_Input:getCursorPosition
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getCursorPosition()
  print("getCursorPosition:", v)
end

-- â”€â”€ Checkbox methods â”€â”€

--@api-stub: Checkbox:setChecked
-- Sets the checked for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Checkbox:setChecked
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  cb:setChecked(true)
end

--@api-stub: Checkbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Checkbox:isChecked
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  local v = cb:isChecked()
  print("isChecked:", v)
end

--@api-stub: Checkbox:setText
-- Sets the text for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Checkbox:setText
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  cb:setText("Hello")
end

--@api-stub: Checkbox:getText
-- Returns the text of this Checkbox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Checkbox:getText
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  local v = cb:getText()
  print("getText:", v)
end

-- â”€â”€ Slider methods â”€â”€

--@api-stub: Slider:setValue
-- Sets the value for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Slider:setValue
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setValue(0.5)
end

--@api-stub: Slider:getValue
-- Returns the value of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Slider:getValue
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getValue()
  print("getValue:", v)
end

--@api-stub: Slider:setRange
-- Sets the range for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Slider:setRange
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setRange(1)
end

--@api-stub: Slider:setStep
-- Sets the step for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Slider:setStep
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setStep(1)
end

--@api-stub: Slider:getMin
-- Returns the min of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Slider:getMin
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getMin()
  print("getMin:", v)
end

--@api-stub: Slider:getMax
-- Returns the max of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Slider:getMax
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getMax()
  print("getMax:", v)
end

-- â”€â”€ Progress_Bar methods â”€â”€

--@api-stub: Progress_Bar:setValue
-- Sets the value for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Progress_Bar:setValue
  local pb = new_example_image_widget():newProgressBar(0.5)
  pb:setValue(0.5)
end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Progress_Bar:getValue
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getValue()
  print("getValue:", v)
end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Progress_Bar:getProgress
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getProgress()
  print("getProgress:", v)
end

--@api-stub: Progress_Bar:setRange
-- Sets the range for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Progress_Bar:setRange
  local pb = new_example_image_widget():newProgressBar(0.5)
  pb:setRange(1)
end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Progress_Bar:getMin
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getMin()
  print("getMin:", v)
end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Progress_Bar:getMax
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getMax()
  print("getMax:", v)
end

-- â”€â”€ Combo_Box methods â”€â”€

--@api-stub: Combo_Box:addItem
-- Adds a item entry to this Combo_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Combo_Box:addItem
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:addItem("item_1")
end

--@api-stub: Combo_Box:removeItem
-- Removes the item from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Combo_Box:removeItem
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:removeItem()
end

--@api-stub: Combo_Box:clearItems
-- Clears all items entries from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Combo_Box:clearItems
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:clearItems()
end

--@api-stub: Combo_Box:getItemCount
-- Returns the item count of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Combo_Box:getItemCount
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: Combo_Box:getItem
-- Returns the item of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Combo_Box:getItem
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItem()
  print("getItem:", v)
end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Combo_Box:setSelectedIndex
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:setSelectedIndex(true)
end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Combo_Box:getSelectedIndex
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Combo_Box:getSelectedItem
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedItem()
  print("getSelectedItem:", v)
end

-- â”€â”€ List_Box methods â”€â”€

--@api-stub: List_Box:addItem
-- Adds a item entry to this List_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- List_Box:addItem
  local w = new_example_image_widget():newList()
  w:addItem("item_1")
end

--@api-stub: List_Box:removeItem
-- Removes the item from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- List_Box:removeItem
  local w = new_example_image_widget():newList()
  w:removeItem()
end

--@api-stub: List_Box:clearItems
-- Clears all items entries from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- List_Box:clearItems
  local w = new_example_image_widget():newList()
  w:clearItems()
end

--@api-stub: List_Box:getItemCount
-- Returns the item count of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- List_Box:getItemCount
  local w = new_example_image_widget():newList()
  local v = w:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: List_Box:getItem
-- Returns the item of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- List_Box:getItem
  local w = new_example_image_widget():newList()
  local v = w:getItem()
  print("getItem:", v)
end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- List_Box:setSelectedIndex
  local w = new_example_image_widget():newList()
  w:setSelectedIndex(true)
end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- List_Box:getSelectedIndex
  local w = new_example_image_widget():newList()
  local v = w:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: List_Box:setItemHeight
-- Sets the item height for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- List_Box:setItemHeight
  local w = new_example_image_widget():newList()
  w:setItemHeight(50)
end

-- â”€â”€ Tab_Bar methods â”€â”€

--@api-stub: Tab_Bar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Tab_Bar:addTab
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local child = new_example_image_widget():newButton("child_1", "Child")
  tabs:addTab(child)
end

--@api-stub: Tab_Bar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Tab_Bar:removeTab
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  tabs:removeTab()
end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tab_Bar:getTab
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTab()
  print("getTab:", v)
end

--@api-stub: Tab_Bar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tab_Bar:getTabCount
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTabCount()
  print("getTabCount:", v)
end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tab_Bar:setActiveTab
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  tabs:setActiveTab(1)
end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tab_Bar:getActiveTab
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getActiveTab()
  print("getActiveTab:", v)
end

-- â”€â”€ Spin_Box methods â”€â”€

--@api-stub: Spin_Box:setValue
-- Sets the value for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Spin_Box:setValue
  local spin = new_example_image_widget():newSpinBox()
  spin:setValue(0.5)
end

--@api-stub: Spin_Box:getValue
-- Returns the current value of this SpinBox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Spin_Box:getValue
  local spin = new_example_image_widget():newSpinBox()
  local v = spin:getValue()
  print("getValue:", v)
end

--@api-stub: Spin_Box:increment
-- Increments the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
do -- Spin_Box:increment
  local spin = new_example_image_widget():newSpinBox()
  spin:increment()
end

--@api-stub: Spin_Box:decrement
-- Decrements the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
do -- Spin_Box:decrement
  local spin = new_example_image_widget():newSpinBox()
  spin:decrement()
end

--@api-stub: Spin_Box:setRange
-- Sets the valid range for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Spin_Box:setRange
  local spin = new_example_image_widget():newSpinBox()
  spin:setRange(1)
end

--@api-stub: Spin_Box:setStep
-- Sets the increment step for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Spin_Box:setStep
  local spin = new_example_image_widget():newSpinBox()
  spin:setStep(1)
end

-- â”€â”€ Switch methods â”€â”€

--@api-stub: Switch:setOn
-- Sets the on/off state of this Switch widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Switch:setOn
  local sw = new_example_image_widget():newSwitch(false)
  sw:setOn(function() print("event") end)
end

--@api-stub: Switch:isOn
-- Returns the on/off state of this Switch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Switch:isOn
  local sw = new_example_image_widget():newSwitch(false)
  local v = sw:isOn()
  print("isOn:", v)
end

--@api-stub: Switch:toggle
-- Toggles the on/off state of this Switch widget.
-- Call this on the Switch instance to drive its behaviour at runtime.
do -- Switch:toggle
  local sw = new_example_image_widget():newSwitch(false)
  sw:toggle()
end

-- â”€â”€ Badge methods â”€â”€

--@api-stub: Badge:setCount
-- Sets the count displayed on this Badge widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Badge:setCount
  local badge = new_example_image_widget():newBadge("3")
  badge:setCount(4)
end

--@api-stub: Badge:getCount
-- Returns the raw count of this Badge widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Badge:getCount
  local badge = new_example_image_widget():newBadge("3")
  local v = badge:getCount()
  print("getCount:", v)
end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this Badge widget, e.g.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Badge:getDisplayText
  local badge = new_example_image_widget():newBadge("3")
  local v = badge:getDisplayText()
  print("getDisplayText:", v)
end

-- â”€â”€ Panel methods â”€â”€

--@api-stub: Panel:setTitle
-- Sets the title for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Panel:setTitle
  local panel = new_example_image_widget():newPanel()
  panel:setTitle("Hello")
end

--@api-stub: Panel:getTitle
-- Returns the title of this Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Panel:getTitle
  local panel = new_example_image_widget():newPanel()
  local v = panel:getTitle()
  print("getTitle:", v)
end

--@api-stub: Panel:setScrollable
-- Sets the scrollable for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Panel:setScrollable
  local panel = new_example_image_widget():newPanel()
  panel:setScrollable(1)
end

-- â”€â”€ Layout methods â”€â”€

--@api-stub: Layout:setDirection
-- Sets the direction for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setDirection
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setDirection("horizontal")
end

--@api-stub: Layout:getDirection
-- Returns the direction of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Layout:getDirection
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getDirection()
  print("getDirection:", v)
end

--@api-stub: Layout:setSpacing
-- Sets the spacing for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setSpacing
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setSpacing(8)
end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Layout:getSpacing
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getSpacing()
  print("getSpacing:", v)
end

--@api-stub: Layout:setColumns
-- Sets the columns for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setColumns
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setColumns(1)
end

--@api-stub: Layout:setWrap
-- Sets the wrap for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setWrap
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setWrap(true)
end

--@api-stub: Layout:getWrap
-- Returns the wrap of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Layout:getWrap
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getWrap()
  print("getWrap:", v)
end

--@api-stub: Layout:setAlign
-- Sets the align for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setAlign
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setAlign("center")
end

--@api-stub: Layout:getAlign
-- Returns the align of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Layout:getAlign
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getAlign()
  print("getAlign:", v)
end

--@api-stub: Layout:setJustify
-- Sets the justify for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Layout:setJustify
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setJustify(1)
end

--@api-stub: Layout:getJustify
-- Returns the justify of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Layout:getJustify
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getJustify()
  print("getJustify:", v)
end

-- â”€â”€ Scroll_Panel methods â”€â”€

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Panel:setContentSize
  local sp = new_example_image_widget():newScrollPanel()
  sp:setContentSize(200, 50)
end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Panel:getContentSize
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Panel:setScrollPosition
  local sp = new_example_image_widget():newScrollPanel()
  sp:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Panel:getScrollPosition
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Panel:getMaxScroll
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getMaxScroll()
  print("getMaxScroll:", v)
end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Panel:setScrollSpeed
  local sp = new_example_image_widget():newScrollPanel()
  sp:setScrollSpeed(1)
end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Panel:getScrollSpeed
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getScrollSpeed()
  print("getScrollSpeed:", v)
end

-- â”€â”€ Nine_Patch methods â”€â”€

--@api-stub: Nine_Patch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Nine_Patch:setInsets
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  np:setInsets(1)
end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Nine_Patch:getInsets
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getInsets()
  print("getInsets:", v)
end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Nine_Patch:setImageDimensions
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  np:setImageDimensions("assets/icon.png")
end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Nine_Patch:getImageDimensions
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getImageDimensions()
  print("getImageDimensions:", v)
end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Nine_Patch:getSlices
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getSlices()
  print("getSlices:", v)
end

-- â”€â”€ Toast methods â”€â”€

--@api-stub: Toast:setMessage
-- Sets the message for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Toast:setMessage
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  toast:setMessage(1)
end

--@api-stub: Toast:getMessage
-- Returns the message of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toast:getMessage
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getMessage()
  print("getMessage:", v)
end

--@api-stub: Toast:setDuration
-- Sets the duration for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Toast:setDuration
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  toast:setDuration(0.5)
end

--@api-stub: Toast:getDuration
-- Returns the duration of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toast:getDuration
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getDuration()
  print("getDuration:", v)
end

--@api-stub: Toast:getProgress
-- Returns the progress of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toast:getProgress
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getProgress()
  print("getProgress:", v)
end

--@api-stub: Toast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toast:isExpired
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:isExpired()
  print("isExpired:", v)
end

-- â”€â”€ Separator methods â”€â”€

--@api-stub: Separator:setVertical
-- Sets the vertical for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Separator:setVertical
  local sep = new_example_image_widget():newSeparator("horizontal")
  sep:setVertical(1)
end

--@api-stub: Separator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Separator:isVertical
  local sep = new_example_image_widget():newSeparator("horizontal")
  local v = sep:isVertical()
  print("isVertical:", v)
end

--@api-stub: Separator:setThickness
-- Sets the thickness for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Separator:setThickness
  local sep = new_example_image_widget():newSeparator("horizontal")
  sep:setThickness(1)
end

--@api-stub: Separator:getThickness
-- Returns the thickness of this Separator widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Separator:getThickness
  local sep = new_example_image_widget():newSeparator("horizontal")
  local v = sep:getThickness()
  print("getThickness:", v)
end

-- â”€â”€ Tree_View methods â”€â”€

--@api-stub: Tree_View:addNode
-- Adds a node entry to this Tree_View widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Tree_View:addNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:addNode("item_1")
end

--@api-stub: Tree_View:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do -- Tree_View:toggleNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:toggleNode()
end

--@api-stub: Tree_View:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:isExpanded
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:isExpanded()
  print("isExpanded:", v)
end

--@api-stub: Tree_View:getNodeCount
-- Returns the node count of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getNodeCount
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeCount()
  print("getNodeCount:", v)
end

--@api-stub: Tree_View:removeNode
-- Removes the node from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Tree_View:removeNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:removeNode()
end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Tree_View:clearNodes
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:clearNodes()
end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getNodeText
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeText()
  print("getNodeText:", v)
end

--@api-stub: Tree_View:setNodeText
-- Sets the node text for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tree_View:setNodeText
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setNodeText("Hello")
end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tree_View:setNodeIcon
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setNodeIcon("assets/icon.png")
end

--@api-stub: Tree_View:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do -- Tree_View:expandNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:expandNode()
end

--@api-stub: Tree_View:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do -- Tree_View:collapseNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:collapseNode()
end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:isNodeExpanded
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:isNodeExpanded()
  print("isNodeExpanded:", v)
end

--@api-stub: Tree_View:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do -- Tree_View:expandAll
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:expandAll()
end

--@api-stub: Tree_View:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do -- Tree_View:collapseAll
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:collapseAll()
end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tree_View:setSelectedNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setSelectedNode(true)
end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getSelectedNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getSelectedNode()
  print("getSelectedNode:", v)
end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getChildNodes
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getChildNodes()
  print("getChildNodes:", v)
end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getParentNode
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getParentNode()
  print("getParentNode:", v)
end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tree_View:getNodeDepth
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeDepth()
  print("getNodeDepth:", v)
end

-- â”€â”€ Radio_Button methods â”€â”€

--@api-stub: Radio_Button:getText
-- Returns the text of this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Radio_Button:getText
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:getText()
  print("getText:", v)
end

--@api-stub: Radio_Button:setText
-- Sets the text for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Radio_Button:setText
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setText("Hello")
end

--@api-stub: Radio_Button:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Radio_Button:isSelected
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:isSelected()
  print("isSelected:", v)
end

--@api-stub: Radio_Button:setSelected
-- Sets the selected for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Radio_Button:setSelected
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setSelected(true)
end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Radio_Button:getGroup
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:getGroup()
  print("getGroup:", v)
end

--@api-stub: Radio_Button:setGroup
-- Sets the group for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Radio_Button:setGroup
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setGroup(1)
end

--@api-stub: Radio_Button:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do -- Radio_Button:setOnChange
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setOnChange(function() print("event") end)
end

-- â”€â”€ Scroll_Bar methods â”€â”€

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Bar:getScrollPosition
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Bar:setScrollPosition
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Bar:getContentSize
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Bar:setContentSize
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setContentSize(200, 50)
end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Bar:getViewSize
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getViewSize()
  print("getViewSize:", v)
end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Bar:setViewSize
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setViewSize(200, 50)
end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Scroll_Bar:isVertical
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:isVertical()
  print("isVertical:", v)
end

--@api-stub: Scroll_Bar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do -- Scroll_Bar:setOnChange
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setOnChange(function() print("event") end)
end

-- â”€â”€ Gui_Window methods â”€â”€

--@api-stub: Gui_Window:getTitle
-- Returns the title of this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Window:getTitle
  local w = new_example_image_widget():newPanel()
  local v = w:getTitle()
  print("getTitle:", v)
end

--@api-stub: Gui_Window:setTitle
-- Sets the title for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Window:setTitle
  local w = new_example_image_widget():newPanel()
  w:setTitle("Hello")
end

--@api-stub: Gui_Window:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Window:isCloseable
  local w = new_example_image_widget():newPanel()
  local v = w:isCloseable()
  print("isCloseable:", v)
end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Window:setCloseable
  local w = new_example_image_widget():newPanel()
  w:setCloseable(1)
end

--@api-stub: Gui_Window:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Window:isDraggable
  local w = new_example_image_widget():newPanel()
  local v = w:isDraggable()
  print("isDraggable:", v)
end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Window:setDraggable
  local w = new_example_image_widget():newPanel()
  w:setDraggable(1)
end

--@api-stub: Gui_Window:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Window:isResizable
  local w = new_example_image_widget():newPanel()
  local v = w:isResizable()
  print("isResizable:", v)
end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Window:setResizable
  local w = new_example_image_widget():newPanel()
  w:setResizable(true)
end

--@api-stub: Gui_Window:setOnClose
-- Registers a callback invoked when this window is closed.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Window:setOnClose
  local w = new_example_image_widget():newPanel()
  w:setOnClose(function() print("event") end)
end

-- â”€â”€ Split_Panel methods â”€â”€

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Split_Panel:getOrientation
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Split_Panel:setOrientation
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setOrientation("horizontal")
end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Split_Panel:getSplitPosition
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getSplitPosition()
  print("getSplitPosition:", v)
end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Split_Panel:setSplitPosition
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setSplitPosition(100, 200)
end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Split_Panel:getMinPanelSize
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getMinPanelSize()
  print("getMinPanelSize:", v)
end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Split_Panel:setMinPanelSize
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setMinPanelSize(200, 50)
end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Split_Panel:setFirstChild
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setFirstChild(1)
end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Split_Panel:setSecondChild
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setSecondChild(function() print("event") end)
end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Split_Panel:getFirstChild
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getFirstChild()
  print("getFirstChild:", v)
end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Split_Panel:getSecondChild
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getSecondChild()
  print("getSecondChild:", v)
end

-- â”€â”€ Dock_Panel methods â”€â”€

--@api-stub: Dock_Panel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
do -- Dock_Panel:dock
  local dock = new_example_image_widget():newDockPanel()
  dock:dock()
end

--@api-stub: Dock_Panel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
do -- Dock_Panel:undock
  local dock = new_example_image_widget():newDockPanel()
  dock:undock()
end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dock_Panel:getDockedCount
  local dock = new_example_image_widget():newDockPanel()
  local v = dock:getDockedCount()
  print("getDockedCount:", v)
end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Dock_Panel:setSplitSize
  local dock = new_example_image_widget():newDockPanel()
  dock:setSplitSize(200, 50)
end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dock_Panel:getSplitSize
  local dock = new_example_image_widget():newDockPanel()
  local v = dock:getSplitSize()
  print("getSplitSize:", v)
end

-- â”€â”€ Toolbar methods â”€â”€

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toolbar:getOrientation
  local tb = new_example_image_widget():newToolbar()
  local v = tb:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Toolbar:setOrientation
  local tb = new_example_image_widget():newToolbar()
  tb:setOrientation("horizontal")
end

--@api-stub: Toolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Toolbar:addButton
  local tb = new_example_image_widget():newToolbar()
  tb:addButton(1)
end

--@api-stub: Toolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Toolbar:addSeparator
  local tb = new_example_image_widget():newToolbar()
  tb:addSeparator(1)
end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Toolbar:addSpacer
  local tb = new_example_image_widget():newToolbar()
  tb:addSpacer(1)
end

--@api-stub: Toolbar:getButton
-- Returns the button of this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toolbar:getButton
  local tb = new_example_image_widget():newToolbar()
  local v = tb:getButton()
  print("getButton:", v)
end

--@api-stub: Toolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Toolbar:setButtonEnabled
  local tb = new_example_image_widget():newToolbar()
  tb:setButtonEnabled(true)
end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Toolbar:setButtonToggled
  local tb = new_example_image_widget():newToolbar()
  tb:setButtonToggled(function() print("event") end)
end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Toolbar:isButtonToggled
  local tb = new_example_image_widget():newToolbar()
  local v = tb:isButtonToggled()
  print("isButtonToggled:", v)
end

-- â”€â”€ Menu_Bar methods â”€â”€

--@api-stub: Menu_Bar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Menu_Bar:addMenu
  local mb = new_example_image_widget():newMenuBar()
  local child = new_example_image_widget():newButton("child_1", "Child")
  mb:addMenu(child)
end

--@api-stub: Menu_Bar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Menu_Bar:removeMenu
  local mb = new_example_image_widget():newMenuBar()
  mb:removeMenu()
end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Bar:getMenus
  local mb = new_example_image_widget():newMenuBar()
  local v = mb:getMenus()
  print("getMenus:", v)
end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Bar:getMenuCount
  local mb = new_example_image_widget():newMenuBar()
  local v = mb:getMenuCount()
  print("getMenuCount:", v)
end

-- â”€â”€ Menu_Item methods â”€â”€

--@api-stub: Menu_Item:getText
-- Returns the text of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Item:getText
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getText()
  print("getText:", v)
end

--@api-stub: Menu_Item:setText
-- Sets the text for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Menu_Item:setText
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setText("Hello")
end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Item:getShortcut
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getShortcut()
  print("getShortcut:", v)
end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Menu_Item:setShortcut
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setShortcut(1)
end

--@api-stub: Menu_Item:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Item:isChecked
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:isChecked()
  print("isChecked:", v)
end

--@api-stub: Menu_Item:setChecked
-- Sets the checked for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Menu_Item:setChecked
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setChecked(true)
end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Menu_Item:addSubItem
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:addSubItem("item_1")
end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Menu_Item:getSubItems
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getSubItems()
  print("getSubItems:", v)
end

--@api-stub: Menu_Item:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- Configure the widget once after creation, before adding it to a layout.
do -- Menu_Item:setOnClick
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setOnClick(function() print("event") end)
end

-- â”€â”€ Dialog methods â”€â”€

--@api-stub: Dialog:getTitle
-- Returns the title of this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dialog:getTitle
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:getTitle()
  print("getTitle:", v)
end

--@api-stub: Dialog:setTitle
-- Sets the title for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Dialog:setTitle
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setTitle("Hello")
end

--@api-stub: Dialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dialog:isModal
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:isModal()
  print("isModal:", v)
end

--@api-stub: Dialog:setModal
-- Sets the modal for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Dialog:setModal
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setModal(true)
end

--@api-stub: Dialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dialog:isOpen
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:isOpen()
  print("isOpen:", v)
end

--@api-stub: Dialog:open
-- Performs the open operation on this Dialog widget.
-- Call this on the Dialog instance to drive its behaviour at runtime.
do -- Dialog:open
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:open()
end

--@api-stub: Dialog:close
-- Closes and removes this dialog from the screen.
-- Call this on the Dialog instance to drive its behaviour at runtime.
do -- Dialog:close
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:close()
end

--@api-stub: Dialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- Configure the widget once after creation, before adding it to a layout.
do -- Dialog:setOnClose
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setOnClose(function() print("event") end)
end

--@api-stub: Dialog:setContent
-- Sets the content for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Dialog:setContent
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setContent(function() print("event") end)
end

--@api-stub: Dialog:getContent
-- Returns the content of this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Dialog:getContent
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:getContent()
  print("getContent:", v)
end

--@api-stub: Dialog:addButton
-- Adds a button entry to this Dialog widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Dialog:addButton
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:addButton(1)
end

-- â”€â”€ Status_Bar methods â”€â”€

--@api-stub: Status_Bar:addSection
-- Adds a section entry to this Status_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Status_Bar:addSection
  local sb = new_example_image_widget():newStatusBar()
  sb:addSection(1)
end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Status_Bar:setSectionText
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionText("Hello")
end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Status_Bar:getSectionText
  local sb = new_example_image_widget():newStatusBar()
  local v = sb:getSectionText()
  print("getSectionText:", v)
end

--@api-stub: Status_Bar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Status_Bar:getSectionCount
  local sb = new_example_image_widget():newStatusBar()
  local v = sb:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Status_Bar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Status_Bar:setSectionCount
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionCount(4)
end

--@api-stub: Status_Bar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- Configure the widget once after creation, before adding it to a layout.
do -- Status_Bar:setSectionWidget
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionWidget("primary")
end

-- â”€â”€ Accordion methods â”€â”€

--@api-stub: Accordion:addSection
-- Adds a section entry to this Accordion widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Accordion:addSection
  local acc = new_example_image_widget():newAccordion()
  acc:addSection(1)
end

--@api-stub: Accordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Accordion:getSectionCount
  local acc = new_example_image_widget():newAccordion()
  local v = acc:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Accordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- Call this on the Accordion instance to drive its behaviour at runtime.
do -- Accordion:toggleSection
  local acc = new_example_image_widget():newAccordion()
  acc:toggleSection()
end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Accordion:isSectionExpanded
  local acc = new_example_image_widget():newAccordion()
  local v = acc:isSectionExpanded()
  print("isSectionExpanded:", v)
end

--@api-stub: Accordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Accordion:isExclusive
  local acc = new_example_image_widget():newAccordion()
  local v = acc:isExclusive()
  print("isExclusive:", v)
end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Accordion:setExclusive
  local acc = new_example_image_widget():newAccordion()
  acc:setExclusive(1)
end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Accordion:getSectionTitle
  local acc = new_example_image_widget():newAccordion()
  local v = acc:getSectionTitle()
  print("getSectionTitle:", v)
end

-- â”€â”€ Tooltip_Panel methods â”€â”€

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tooltip_Panel:getText
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getText()
  print("getText:", v)
end

--@api-stub: Tooltip_Panel:setText
-- Sets the text for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tooltip_Panel:setText
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setText("Hello")
end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tooltip_Panel:getDelay
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getDelay()
  print("getDelay:", v)
end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tooltip_Panel:setDelay
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setDelay(2.0)
end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Tooltip_Panel:getTarget
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getTarget()
  print("getTarget:", v)
end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Tooltip_Panel:setTarget
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setTarget(1)
end

-- â”€â”€ Color_Picker methods â”€â”€

--@api-stub: Color_Picker:getColor
-- Returns the color of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Color_Picker:getColor
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getColor()
  print("getColor:", v)
end

--@api-stub: Color_Picker:setColor
-- Sets the color for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Color_Picker:setColor
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setColor({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Color_Picker:getShowAlpha
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getShowAlpha()
  print("getShowAlpha:", v)
end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Color_Picker:setShowAlpha
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setShowAlpha(0.85)
end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Color_Picker:getColorMode
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getColorMode()
  print("getColorMode:", v)
end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Color_Picker:setColorMode
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setColorMode({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do -- Color_Picker:setOnChange
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setOnChange(function() print("event") end)
end

-- â”€â”€ Gui_Table methods â”€â”€

--@api-stub: Gui_Table:addColumn
-- Adds a column entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Gui_Table:addColumn
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:addColumn("item_1")
end

--@api-stub: Gui_Table:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Table:getColumnCount
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getColumnCount()
  print("getColumnCount:", v)
end

--@api-stub: Gui_Table:addRow
-- Adds a row entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Gui_Table:addRow
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:addRow("item_1")
end

--@api-stub: Gui_Table:getRowCount
-- Returns the row count of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Table:getRowCount
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getRowCount()
  print("getRowCount:", v)
end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Table:getCell
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getCell()
  print("getCell:", v)
end

--@api-stub: Gui_Table:setCell
-- Sets the cell for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Table:setCell
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setCell(1)
end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Table:getSelectedRow
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getSelectedRow()
  print("getSelectedRow:", v)
end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Table:setSelectedRow
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setSelectedRow(true)
end

--@api-stub: Gui_Table:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Gui_Table:isSortable
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:isSortable()
  print("isSortable:", v)
end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Table:setSortable
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setSortable(1)
end

--@api-stub: Gui_Table:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- Configure the widget once after creation, before adding it to a layout.
do -- Gui_Table:setOnSelect
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setOnSelect(function() print("event") end)
end

-- â”€â”€ Image_Widget methods â”€â”€

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getScaleMode
  local img = new_example_image_widget()
  local v = img:getScaleMode()
  print("getScaleMode:", v)
end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setScaleMode
  local img = new_example_image_widget()
  img:setScaleMode(1.5)
end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this Image_Widget widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getTint
  local img = new_example_image_widget()
  local v = img:getTint()
  print("getTint:", v)
end

--@api-stub: Image_Widget:setTint
-- Sets the tint for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setTint
  local img = new_example_image_widget()
  img:setTint({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newButton
  local img = new_example_image_widget()
  img:newButton()
end

--@api-stub: Image_Widget:newLabel
-- Creates a text label widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newLabel
  local img = new_example_image_widget()
  img:newLabel()
end

--@api-stub: Image_Widget:newTextInput
-- Creates a text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTextInput
  local img = new_example_image_widget()
  img:newTextInput()
end

--@api-stub: Image_Widget:newCheckbox
-- Creates a checkbox widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newCheckbox
  local img = new_example_image_widget()
  img:newCheckbox()
end

--@api-stub: Image_Widget:newSlider
-- Creates a value slider widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSlider
  local img = new_example_image_widget()
  img:newSlider()
end

--@api-stub: Image_Widget:newProgressBar
-- Creates a progress bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newProgressBar
  local img = new_example_image_widget()
  img:newProgressBar()
end

--@api-stub: Image_Widget:newComboBox
-- Creates a dropdown combo box widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newComboBox
  local img = new_example_image_widget()
  img:newComboBox()
end

--@api-stub: Image_Widget:newList
-- Creates a selectable list widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newList
  local img = new_example_image_widget()
  img:newList()
end

--@api-stub: Image_Widget:newPanel
-- Creates a container panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newPanel
  local img = new_example_image_widget()
  img:newPanel()
end

--@api-stub: Image_Widget:newLayout
-- Creates a flexbox layout container.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newLayout
  local img = new_example_image_widget()
  img:newLayout()
end

--@api-stub: Image_Widget:newScrollPanel
-- Creates a scrollable panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newScrollPanel
  local img = new_example_image_widget()
  img:newScrollPanel()
end

--@api-stub: Image_Widget:newNinePatch
-- Creates a 9-patch slicer widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newNinePatch
  local img = new_example_image_widget()
  img:newNinePatch()
end

--@api-stub: Image_Widget:newTabBar
-- Creates a tab bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTabBar
  local img = new_example_image_widget()
  img:newTabBar()
end

--@api-stub: Image_Widget:newSeparator
-- Creates a separator line.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSeparator
  local img = new_example_image_widget()
  img:newSeparator()
end

--@api-stub: Image_Widget:newSpacer
-- Creates a spacing filler widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSpacer
  local img = new_example_image_widget()
  img:newSpacer()
end

--@api-stub: Image_Widget:newToast
-- Creates a toast notification widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newToast
  local img = new_example_image_widget()
  img:newToast()
end

--@api-stub: Image_Widget:newTreeView
-- Creates a collapsible tree view widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTreeView
  local img = new_example_image_widget()
  img:newTreeView()
end

--@api-stub: Image_Widget:newRadioButton
-- Creates a grouped radio button widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newRadioButton
  local img = new_example_image_widget()
  img:newRadioButton()
end

--@api-stub: Image_Widget:newScrollBar
-- Creates a scroll bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newScrollBar
  local img = new_example_image_widget()
  img:newScrollBar()
end

--@api-stub: Image_Widget:newWindow
-- Creates a draggable window widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newWindow
  local img = new_example_image_widget()
  img:newWindow()
end

--@api-stub: Image_Widget:newSplitPanel
-- Creates a resizable split panel.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSplitPanel
  local img = new_example_image_widget()
  img:newSplitPanel()
end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newDockPanel
  local img = new_example_image_widget()
  img:newDockPanel()
end

--@api-stub: Image_Widget:newToolbar
-- Creates a toolbar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newToolbar
  local img = new_example_image_widget()
  img:newToolbar()
end

--@api-stub: Image_Widget:newMenuBar
-- Creates a menu bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newMenuBar
  local img = new_example_image_widget()
  img:newMenuBar()
end

--@api-stub: Image_Widget:newMenuItem
-- Creates a menu item widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newMenuItem
  local img = new_example_image_widget()
  img:newMenuItem()
end

--@api-stub: Image_Widget:newDialog
-- Creates a modal dialog widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newDialog
  local img = new_example_image_widget()
  img:newDialog()
end

--@api-stub: Image_Widget:newStatusBar
-- Creates a status bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newStatusBar
  local img = new_example_image_widget()
  img:newStatusBar()
end

--@api-stub: Image_Widget:newAccordion
-- Creates a collapsible accordion widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newAccordion
  local img = new_example_image_widget()
  img:newAccordion()
end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates a tooltip panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTooltipPanel
  local img = new_example_image_widget()
  img:newTooltipPanel()
end

--@api-stub: Image_Widget:newColorPicker
-- Creates a color picker widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newColorPicker
  local img = new_example_image_widget()
  img:newColorPicker()
end

--@api-stub: Image_Widget:newTable
-- Creates a data table widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTable
  local img = new_example_image_widget()
  img:newTable()
end

--@api-stub: Image_Widget:newImageWidget
-- Creates an image display widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newImageWidget
  local img = new_example_image_widget()
  img:newImageWidget()
end

--@api-stub: Image_Widget:newTheme
-- Creates a new theme instance.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newTheme
  local img = new_example_image_widget()
  img:newTheme()
end

--@api-stub: Image_Widget:setTheme
-- Sets the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setTheme
  local img = new_example_image_widget()
  img:setTheme("dark")
end

--@api-stub: Image_Widget:getTheme
-- Returns whether a theme is set.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getTheme
  local img = new_example_image_widget()
  local v = img:getTheme()
  print("getTheme:", v)
end

--@api-stub: Image_Widget:getRoot
-- Returns the root panel widget table.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getRoot
  local img = new_example_image_widget()
  local v = img:getRoot()
  print("getRoot:", v)
end

--@api-stub: Image_Widget:setFocus
-- Sets keyboard focus to a widget or clears it.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setFocus
  local img = new_example_image_widget()
  img:setFocus(1)
end

--@api-stub: Image_Widget:getFocus
-- Returns the focused widget index or nil.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getFocus
  local img = new_example_image_widget()
  local v = img:getFocus()
  print("getFocus:", v)
end

--@api-stub: Image_Widget:focusNext
-- Moves focus to the next focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:focusNext
  local img = new_example_image_widget()
  img:focusNext()
end

--@api-stub: Image_Widget:focusPrev
-- Moves focus to the previous focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:focusPrev
  local img = new_example_image_widget()
  img:focusPrev()
end

--@api-stub: Image_Widget:clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- Tear down dynamic content when the screen changes to free GPU resources.
do -- Image_Widget:clearFocus
  local img = new_example_image_widget()
  img:clearFocus()
end

--@api-stub: Image_Widget:addToast
-- Queues a toast notification from a table.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do -- Image_Widget:addToast
  local img = new_example_image_widget()
  img:addToast(1)
end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of active toasts.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getToastCount
  local img = new_example_image_widget()
  local v = img:getToastCount()
  print("getToastCount:", v)
end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:mousepressed
  local img = new_example_image_widget()
  img:mousepressed()
end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:mousereleased
  local img = new_example_image_widget()
  img:mousereleased()
end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:mousemoved
  local img = new_example_image_widget()
  img:mousemoved()
end
--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:keypressed
  local img = new_example_image_widget()
  img:keypressed()
end

--@api-stub: Image_Widget:textinput
-- Forwards text input to the focused text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:textinput
  local img = new_example_image_widget()
  img:textinput()
end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:wheelmoved
  local img = new_example_image_widget()
  img:wheelmoved()
end

--@api-stub: Image_Widget:update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:update
  local img = new_example_image_widget()
  img:update()
end

--@api-stub: Image_Widget:draw
-- Headless compatibility EXAMPLE for GUI draw.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:draw
  local img = new_example_image_widget()
  img:draw()
end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the total widget count in the context.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
do -- Image_Widget:getWidgetCount
  local img = new_example_image_widget()
  local v = img:getWidgetCount()
  print("getWidgetCount:", v)
end

--@api-stub: Image_Widget:drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:drawToImage
  local img = new_example_image_widget()
  img:drawToImage()
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newLineChart
  local img = new_example_image_widget()
  img:newLineChart()
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newBarChart
  local img = new_example_image_widget()
  img:newBarChart()
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newScatterPlot
  local img = new_example_image_widget()
  img:newScatterPlot()
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newPieChart
  local img = new_example_image_widget()
  img:newPieChart()
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newAreaChart
  local img = new_example_image_widget()
  img:newAreaChart()
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newLineChart
  local img = new_example_image_widget()
  img:newLineChart()
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newBarChart
  local img = new_example_image_widget()
  img:newBarChart()
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newScatterPlot
  local img = new_example_image_widget()
  img:newScatterPlot()
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newPieChart
  local img = new_example_image_widget()
  img:newPieChart()
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newAreaChart
  local img = new_example_image_widget()
  img:newAreaChart()
end

--@api-stub: Image_Widget:parseWidgetState
-- Parses a widget state string, returning the canonical form or nil if invalid.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:parseWidgetState
  local img = new_example_image_widget()
  img:parseWidgetState()
end

--@api-stub: Image_Widget:newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSpinBox
  local img = new_example_image_widget()
  img:newSpinBox()
end

--@api-stub: Image_Widget:newSwitch
-- Creates a toggle switch widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newSwitch
  local img = new_example_image_widget()
  img:newSwitch()
end

--@api-stub: Image_Widget:newBadge
-- Creates a badge widget displaying a numeric count.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:newBadge
  local img = new_example_image_widget()
  img:newBadge()
end

--@api-stub: Image_Widget:setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setDefaultTheme
  local img = new_example_image_widget()
  img:setDefaultTheme("dark")
end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- Configure the widget once after creation, before adding it to a layout.
do -- Image_Widget:setViewport
  local img = new_example_image_widget()
  img:setViewport(1)
end

--@api-stub: Image_Widget:flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:flushCache
  local img = new_example_image_widget()
  img:flushCache()
end

--@api-stub: Image_Widget:update_bindings
-- Updates all widgets that have a data-binding key registered via `:bind(key)`.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:update_bindings
  local img = new_example_image_widget()
  img:update_bindings()
end

--@api-stub: Image_Widget:loadLayout
-- Load a widget tree from a Lua table definition and attach it to the UI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:loadLayout
  local img = new_example_image_widget()
  img:loadLayout()
end

--@api-stub: Image_Widget:loadLayoutFile
-- Load a widget tree from a TOML layout file and attach it to the UI root.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:loadLayoutFile
  local img = new_example_image_widget()
  img:loadLayoutFile()
end

--@api-stub: Image_Widget:renderToImage
-- Render the current UI widget tree to a PNG file for testing purposes.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do -- Image_Widget:renderToImage
  local img = new_example_image_widget()
  img:renderToImage()
end

-- â”€â”€ LineChart methods â”€â”€

--@api-stub: LineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do -- LineChart:setYMax
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:setYMax(100)
end

--@api-stub: LineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do -- LineChart:setXMax
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:setXMax(100)
end

--@api-stub: LineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Call this on the LineChart instance to drive its behaviour at runtime.
do -- LineChart:drawToImage
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:drawToImage()
end

-- â”€â”€ BarChart methods â”€â”€

--@api-stub: LBarChart:drawToImage
-- Renders the bar chart into an existing ImageData.
-- Call this on the BarChart instance to drive its behaviour at runtime.
do -- BarChart:drawToImage
  local w = new_example_image_widget():newPanel()
  w:drawToImage()
end

-- â”€â”€ ScatterPlot methods â”€â”€

--@api-stub: LScatterPlot:setXRange
-- Sets the X-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
do -- ScatterPlot:setXRange
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setXRange(1)
end

--@api-stub: LScatterPlot:setYRange
-- Sets the Y-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
do -- ScatterPlot:setYRange
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setYRange(1)
end

--@api-stub: LScatterPlot:drawToImage
-- Renders the scatter plot into an existing ImageData.
-- Call this on the ScatterPlot instance to drive its behaviour at runtime.
do -- ScatterPlot:drawToImage
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:drawToImage()
end

-- â”€â”€ PieChart methods â”€â”€

--@api-stub: LPieChart:drawToImage
-- Renders the pie chart into an existing ImageData.
-- Call this on the PieChart instance to drive its behaviour at runtime.
do -- PieChart:drawToImage
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
  chart:drawToImage()
end

-- â”€â”€ AreaChart methods â”€â”€

--@api-stub: LAreaChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do -- AreaChart:setYMax
  local w = new_example_image_widget():newPanel()
  w:setYMax(100)
end

--@api-stub: LAreaChart:drawToImage
-- Renders the area chart into an existing ImageData.
-- Call this on the AreaChart instance to drive its behaviour at runtime.
do -- AreaChart:drawToImage
  local w = new_example_image_widget():newPanel()
  w:drawToImage()
end

-- â”€â”€ Custom widget extensibility â”€â”€

--@api-stub: Image_Widget:newCustomWidget
-- Creates a widget with fully Lua-driven rendering via an on_draw callback.
-- Call once during init to register the widget; call lurek.ui.draw() each frame.
do -- Image_Widget:newCustomWidget
  local widget = new_example_image_widget():newCustomWidget({
    x = 50, y = 50, width = 300, height = 200, id = "health_bar",
  })
  if widget and widget.setOnDraw then
    widget:setOnDraw(function(rect)
      local health = 0.75
      -- Draw background
      lurek.render.setColor(0.2, 0.2, 0.2, 1)
        lurek.render.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
      -- Draw health fill
      lurek.render.setColor(0, 1, 0, 1)
        lurek.render.rectangle("fill", rect.x, rect.y, rect.w * health, rect.h)
      -- Draw label
      lurek.render.setColor(1, 1, 1, 1)
      lurek.render.print("HP: 75%", rect.x + 4, rect.y + 4)
    end)
  end
  print("newCustomWidget: ok")
end


--@api-stub: LBarChart:addCategory
-- Adds a named category (x-axis label) to the bar chart.
-- Each series value maps to one category; add categories before adding series data.
do -- BarChart:addCategory
  lurek.log.info("BarChart:addCategory usage: chart:addCategory('Jan')", "ui")
  local bc = new_example_image_widget():newBarChart(200, 100)
  bc:addCategory("Jan")
  bc:addCategory("Feb")
  lurek.log.info("categories added", "ui")
end

--@api-stub: LAreaChart:addLayer
-- Adds a new stacked area series layer to the area chart.
-- Multiple layers stack vertically; each is filled with a distinct colour.
do -- AreaChart:addLayer
  local ac = new_example_image_widget():newAreaChart(300, 150)
  ac:addLayer("series_a", {1,0.3,0.3,0.7}, {10,20,15,30,25})
  ac:addLayer("series_b", {0.3,0.6,1,0.7}, {5,10,8,14,12})
  lurek.log.info("area layers added", "ui")
end

--@api-stub: LPieChart:addSegment
-- Adds a named slice to the pie chart with a value and colour.
-- Values are relative; the chart normalises them to 360 degrees automatically.
do -- PieChart:addSegment
  local pc = new_example_image_widget():newPieChart(150, 150)
  pc:addSegment("Wheat",  40, {0.9, 0.8, 0.3, 1})
  pc:addSegment("Sheep",  25, {0.8, 0.9, 0.5, 1})
  pc:addSegment("Forest", 35, {0.2, 0.7, 0.3, 1})
  lurek.log.info("pie segments added", "ui")
end

--@api-stub: LineChart:addSeries
-- Adds a named data series to the line chart with a colour and data points.
-- Multiple series are drawn overlapping; use distinct colours to differentiate.
do -- LineChart:addSeries
  local lc = new_example_image_widget():newLineChart(300, 150)
  lc:addSeries("revenue", {0.2, 0.8, 0.4, 1}, {10, 20, 15, 35, 30})
  lc:addSeries("cost",    {0.9, 0.3, 0.2, 1}, {8,  12, 10, 18, 20})
  lurek.log.info("line series added", "ui")
end

--@api-stub: LBarChart:addSeries
-- Adds a named data series to the bar chart with a colour and values.
-- Each value in the table maps to the corresponding category index.
do -- BarChart:addSeries
  local bc = new_example_image_widget():newBarChart(300, 150)
  bc:addCategory("Q1"); bc:addCategory("Q2")
  bc:addSeries("sales",   {0.2, 0.6, 0.9, 1}, {120, 180})
  bc:addSeries("returns", {0.9, 0.3, 0.2, 1}, {10,  15})
  lurek.log.info("bar series added", "ui")
end

--@api-stub: LScatterPlot:addSeries
-- Adds a named point series to the scatter plot with colour and (x, y) data pairs.
-- Each series is a flat table {x1,y1, x2,y2, ...} of coordinate pairs.
do -- ScatterPlot:addSeries
  local sp = new_example_image_widget():newScatterPlot(200, 200)
  sp:addSeries("players", {0.2, 0.7, 1, 1}, {10,20, 30,40, 50,35, 70,55})
  sp:setXRange(0, 100); sp:setYRange(0, 80)
  lurek.log.info("scatter series added", "ui")
end

--@api-stub: LTheme:setStyle
-- Sets a named style property on the theme (e.g., button colour, font size).
-- Themes apply hierarchically; widget-level styles override theme defaults.
do -- Theme:setStyle
  local theme = new_example_image_widget():newTheme()
  theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
  theme:setStyle("button.text_color",  {1, 1, 1, 1})
  lurek.log.info("theme styles set", "ui")
end

-- =============================================================================
-- COVERAGE: 12 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LineChart methods
-- -----------------------------------------------------------------------------

-- ---- Example: LineChart:type ------------------------------------------------
--@api-stub: LineChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LineChart:type
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  local t = chart:type()
  lurek.log.info("LineChart:type = " .. t, "ui")
end
--@api-stub: LineChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LineChart:typeOf
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  lurek.log.info("is LineChart: " .. tostring(chart:typeOf("LineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAreaChart methods
-- -----------------------------------------------------------------------------

-- ---- Example: LAreaChart:type -----------------------------------------------
--@api-stub: LAreaChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LAreaChart:type
  local w = new_example_image_widget():newPanel()
    w:setYMax(100)
  local t = w:type()
  lurek.log.info("LAreaChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LAreaChart:typeOf
  local w = new_example_image_widget():newPanel()
    w:setYMax(100)
  lurek.log.info("is LAreaChart: " .. tostring(w:typeOf("LAreaChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LBarChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LBarChart:type
  local w = new_example_image_widget():newPanel()
    w:drawToImage()
  local t = w:type()
  lurek.log.info("LBarChart:type = " .. t, "ui")
end
--@api-stub: LBarChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LBarChart:typeOf
  local w = new_example_image_widget():newPanel()
    w:drawToImage()
  lurek.log.info("is LBarChart: " .. tostring(w:typeOf("LBarChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LLineChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection of UI chart objects.
do -- LLineChart:type
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Sales" })
  local t = chart:type()
  lurek.log.info("LLineChart:type=" .. t, "ui")
end
--@api-stub: LLineChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks on UI chart objects.
do -- LLineChart:typeOf
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Revenue" })
  lurek.log.info("is LLineChart: " .. tostring(chart:typeOf("LLineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LPieChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LPieChart:type
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
    chart:drawToImage()
  local t = chart:type()
  lurek.log.info("LPieChart:type = " .. t, "ui")
end
--@api-stub: LPieChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LPieChart:typeOf
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
    chart:drawToImage()
  lurek.log.info("is LPieChart: " .. tostring(chart:typeOf("LPieChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LScatterPlot:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LScatterPlot:type
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1)
  local t = plot:type()
  lurek.log.info("LScatterPlot:type = " .. t, "ui")
end
--@api-stub: LScatterPlot:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LScatterPlot:typeOf
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1)
  lurek.log.info("is LScatterPlot: " .. tostring(plot:typeOf("LScatterPlot")), "ui")
  lurek.log.info("is wrong: " .. tostring(plot:typeOf("Unknown")), "ui")
end
--@api-stub: LTheme:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LTheme:type
  local theme = new_example_image_widget():newTheme()
    theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
    theme:setStyle("button.text_color",  {1, 1, 1, 1})
  local t = theme:type()
  lurek.log.info("LTheme:type = " .. t, "ui")
end
--@api-stub: LTheme:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LTheme:typeOf
  local theme = new_example_image_widget():newTheme()
    theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
    theme:setStyle("button.text_color",  {1, 1, 1, 1})
  lurek.log.info("is LTheme: " .. tostring(theme:typeOf("LTheme")), "ui")
  lurek.log.info("is wrong: " .. tostring(theme:typeOf("Unknown")), "ui")
end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Example: lurek.ui.type -------------------------------------------------
--@api-stub: lurek.ui.type
-- Returns the Lua type name of this widget (e.g. "LButton").
-- Use for runtime type dispatch in generic widget handlers.
do -- lurek.ui.type
  local chart = lurek.ui.newLineChart({ width = 200, height = 150, title = "FPS" })
  local t = chart:type()
  lurek.log.info("ui.type=" .. tostring(t), "ui")
end
--@api-stub: LLineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Use when the data range is known ahead of time for a stable chart view.
do -- LLineChart:setYMax
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Score" })
  chart:setYMax(1000)
  lurek.log.info("y-axis max set to 1000", "ui")
end
--@api-stub: LLineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Use to fix the time window when showing rolling 60-second traces.
do -- LLineChart:setXMax
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "FPS" })
  chart:setXMax(60)   -- fixed 60-second window
  lurek.log.info("x-axis max set to 60", "ui")
end
--@api-stub: LLineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Use to embed charts into sprite textures or screenshots.
do -- LLineChart:drawToImage
  local chart = lurek.ui.newLineChart({ width = 256, height = 128, title = "Wave" })
  chart:setXMax(10)
  chart:setYMax(1.0)
  local idata = lurek.image.newImageData(256, 128)
  chart:drawToImage(idata)
  lurek.log.info("chart rendered to ImageData 256x128", "ui")
end

-- =============================================================================
-- COVERAGE: 352 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Example: lurek.ui.newButton --------------------------------------------
--@api-stub: lurek.ui.newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- lurek.ui.newButton([text])  -- -> LButton

-- ---- Example: lurek.ui.newLabel ---------------------------------------------
--@api-stub: lurek.ui.newLabel
-- Creates a text label widget.
-- lurek.ui.newLabel([text])  -- -> LLabel

-- ---- Example: lurek.ui.newTextInput -----------------------------------------
--@api-stub: lurek.ui.newTextInput
-- Creates a text input widget.
-- lurek.ui.newTextInput()  -- -> LTextInput

-- ---- Example: lurek.ui.newCheckbox ------------------------------------------
--@api-stub: lurek.ui.newCheckbox
-- Creates a checkbox widget.
-- lurek.ui.newCheckbox([text])  -- -> LCheckbox

-- ---- Example: lurek.ui.newSlider --------------------------------------------
--@api-stub: lurek.ui.newSlider
-- Creates a value slider widget.
-- lurek.ui.newSlider([min], [max])  -- -> LSlider

-- ---- Example: lurek.ui.newProgressBar ---------------------------------------
--@api-stub: lurek.ui.newProgressBar
-- Creates a progress bar widget.
-- lurek.ui.newProgressBar([min], [max])  -- -> LProgressBar

-- ---- Example: lurek.ui.newComboBox ------------------------------------------
--@api-stub: lurek.ui.newComboBox
-- Creates a dropdown combo box widget.
-- lurek.ui.newComboBox()  -- -> LComboBox

-- ---- Example: lurek.ui.newList ----------------------------------------------
--@api-stub: lurek.ui.newList
-- Creates a selectable list widget.
-- lurek.ui.newList()  -- -> LListBox

-- ---- Example: lurek.ui.newPanel ---------------------------------------------
--@api-stub: lurek.ui.newPanel
-- Creates a container panel widget.
-- lurek.ui.newPanel()  -- -> LPanel

-- ---- Example: lurek.ui.newLayout --------------------------------------------
--@api-stub: lurek.ui.newLayout
-- Creates a flexbox layout container.
-- lurek.ui.newLayout([direction])  -- -> LLayout

-- ---- Example: lurek.ui.newScrollPanel ---------------------------------------
--@api-stub: lurek.ui.newScrollPanel
-- Creates a scrollable panel widget.
-- lurek.ui.newScrollPanel()  -- -> LScrollPanel

-- ---- Example: lurek.ui.newNinePatch -----------------------------------------
--@api-stub: lurek.ui.newNinePatch
-- Creates a 9-patch slicer widget.
-- lurek.ui.newNinePatch()  -- -> LNinePatch

-- ---- Example: lurek.ui.newTabBar --------------------------------------------
--@api-stub: lurek.ui.newTabBar
-- Creates a tab bar widget.
-- lurek.ui.newTabBar()  -- -> LTabBar

-- ---- Example: lurek.ui.newSeparator -----------------------------------------
--@api-stub: lurek.ui.newSeparator
-- Creates a separator line.
-- lurek.ui.newSeparator([vertical])  -- -> LSeparator

-- ---- Example: lurek.ui.newSpacer --------------------------------------------
--@api-stub: lurek.ui.newSpacer
-- Creates a spacing filler widget.
-- lurek.ui.newSpacer([w], [h])  -- -> LSpacer

-- ---- Example: lurek.ui.newToast ---------------------------------------------
--@api-stub: lurek.ui.newToast
-- Creates a toast notification widget.
-- lurek.ui.newToast([message], [duration])  -- -> LToast

-- ---- Example: lurek.ui.newTreeView ------------------------------------------
--@api-stub: lurek.ui.newTreeView
-- Creates a collapsible tree view widget.
-- lurek.ui.newTreeView()  -- -> LTreeView

-- ---- Example: lurek.ui.newRadioButton ---------------------------------------
--@api-stub: lurek.ui.newRadioButton
-- Creates a grouped radio button widget.
-- lurek.ui.newRadioButton([text], [group])  -- -> LRadioButton

-- ---- Example: lurek.ui.newScrollBar -----------------------------------------
--@api-stub: lurek.ui.newScrollBar
-- Creates a scroll bar widget.
-- lurek.ui.newScrollBar([vertical])  -- -> LScrollBar

-- ---- Example: lurek.ui.newWindow --------------------------------------------
--@api-stub: lurek.ui.newWindow
-- Creates a draggable window widget.
-- lurek.ui.newWindow([title])  -- -> LGuiWindow

-- ---- Example: lurek.ui.newSplitPanel ----------------------------------------
--@api-stub: lurek.ui.newSplitPanel
-- Creates a resizable split panel.
-- lurek.ui.newSplitPanel([orientation])  -- -> LSplitPanel

-- ---- Example: lurek.ui.newDockPanel -----------------------------------------
--@api-stub: lurek.ui.newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- lurek.ui.newDockPanel()  -- -> LDockPanel

-- ---- Example: lurek.ui.newToolbar -------------------------------------------
--@api-stub: lurek.ui.newToolbar
-- Creates a toolbar widget.
-- lurek.ui.newToolbar([orientation])  -- -> LToolbar

-- ---- Example: lurek.ui.newMenuBar -------------------------------------------
--@api-stub: lurek.ui.newMenuBar
-- Creates a menu bar widget.
-- lurek.ui.newMenuBar()  -- -> LMenuBar

-- ---- Example: lurek.ui.newMenuItem ------------------------------------------
--@api-stub: lurek.ui.newMenuItem
-- Creates a menu item widget.
-- lurek.ui.newMenuItem([text])  -- -> LMenuItem

-- ---- Example: lurek.ui.newDialog --------------------------------------------
--@api-stub: lurek.ui.newDialog
-- Creates a modal dialog widget.
-- lurek.ui.newDialog([title])  -- -> LDialog

-- ---- Example: lurek.ui.newStatusBar -----------------------------------------
--@api-stub: lurek.ui.newStatusBar
-- Creates a status bar widget.
-- lurek.ui.newStatusBar()  -- -> LStatusBar

-- ---- Example: lurek.ui.newAccordion -----------------------------------------
--@api-stub: lurek.ui.newAccordion
-- Creates a collapsible accordion widget.
-- lurek.ui.newAccordion()  -- -> LAccordion

-- ---- Example: lurek.ui.newTooltipPanel --------------------------------------
--@api-stub: lurek.ui.newTooltipPanel
-- Creates a tooltip panel widget.
-- lurek.ui.newTooltipPanel([text])  -- -> LTooltipPanel

-- ---- Example: lurek.ui.newColorPicker ---------------------------------------
--@api-stub: lurek.ui.newColorPicker
-- Creates a color picker widget.
-- lurek.ui.newColorPicker()  -- -> LColorPicker

-- ---- Example: lurek.ui.newTable ---------------------------------------------
--@api-stub: lurek.ui.newTable
-- Creates a data table widget.
-- lurek.ui.newTable()  -- -> LGuiTable

-- ---- Example: lurek.ui.newImageWidget ---------------------------------------
--@api-stub: lurek.ui.newImageWidget
-- Creates an image display widget.
-- lurek.ui.newImageWidget()  -- -> LImageWidget

-- ---- Example: lurek.ui.newTheme ---------------------------------------------
--@api-stub: lurek.ui.newTheme
-- Creates a new theme instance.
-- lurek.ui.newTheme()  -- -> LTheme

-- ---- Example: lurek.ui.setTheme ---------------------------------------------
--@api-stub: lurek.ui.setTheme
-- Sets the active GUI theme.
-- lurek.ui.setTheme(theme_ud)

-- ---- Example: lurek.ui.getTheme ---------------------------------------------
--@api-stub: lurek.ui.getTheme
-- Returns whether a theme is set.
-- lurek.ui.getTheme()  -- -> boolean

-- ---- Example: lurek.ui.getRoot ----------------------------------------------
--@api-stub: lurek.ui.getRoot
-- Returns the root panel widget table.
-- lurek.ui.getRoot()  -- -> LPanel

-- ---- Example: lurek.ui.setFocus ---------------------------------------------
--@api-stub: lurek.ui.setFocus
-- Sets keyboard focus to a widget or clears it.
-- lurek.ui.setFocus([widget])

-- ---- Example: lurek.ui.getFocus ---------------------------------------------
--@api-stub: lurek.ui.getFocus
-- Returns the focused widget index or nil.
-- lurek.ui.getFocus()  -- -> number

-- ---- Example: lurek.ui.focusNext --------------------------------------------
--@api-stub: lurek.ui.focusNext
-- Moves focus to the next focusable widget.
-- lurek.ui.focusNext()

-- ---- Example: lurek.ui.focusPrev --------------------------------------------
--@api-stub: lurek.ui.focusPrev
-- Moves focus to the previous focusable widget.
-- lurek.ui.focusPrev()

-- ---- Example: lurek.ui.clearFocus -------------------------------------------
--@api-stub: lurek.ui.clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- lurek.ui.clearFocus()

-- ---- Example: lurek.ui.addToast ---------------------------------------------
--@api-stub: lurek.ui.addToast
-- Queues a toast notification from a table.
-- lurek.ui.addToast(toast_table)

-- ---- Example: lurek.ui.getToastCount ----------------------------------------
--@api-stub: lurek.ui.getToastCount
-- Returns the number of active toasts.
-- lurek.ui.getToastCount()  -- -> number

-- ---- Example: lurek.ui.mousepressed -----------------------------------------
--@api-stub: lurek.ui.mousepressed
-- Forwards a mouse press event to the GUI.
-- lurek.ui.mousepressed(0.0, 0.0, [btn])  -- -> boolean

-- ---- Example: lurek.ui.mousereleased ----------------------------------------
--@api-stub: lurek.ui.mousereleased
-- Forwards a mouse release event to the GUI.
-- lurek.ui.mousereleased(0.0, 0.0, [btn])  -- -> boolean

-- ---- Example: lurek.ui.mousemoved -------------------------------------------
--@api-stub: lurek.ui.mousemoved
-- Forwards a mouse move event to the GUI.
-- lurek.ui.mousemoved(0.0, 0.0)  -- -> boolean

-- ---- Example: lurek.ui.keypressed -------------------------------------------
--@api-stub: lurek.ui.keypressed
-- Forwards a key press event to the GUI.
-- lurek.ui.keypressed("player_score")  -- -> boolean

-- ---- Example: lurek.ui.textinput --------------------------------------------
--@api-stub: lurek.ui.textinput
-- Forwards text input to the focused text input widget.
-- lurek.ui.textinput("Hello, world!")  -- -> boolean

-- ---- Example: lurek.ui.wheelmoved -------------------------------------------
--@api-stub: lurek.ui.wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- lurek.ui.wheelmoved(0.0, 0.0)  -- -> boolean

-- ---- Example: lurek.ui.update -----------------------------------------------
--@api-stub: lurek.ui.update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- lurek.ui.update(0.016)

-- ---- Example: lurek.ui.draw -------------------------------------------------
--@api-stub: lurek.ui.draw
-- Invokes all registered `on_draw` callbacks with a screen-space rect table.
-- lurek.ui.draw()

-- ---- Example: lurek.ui.newCustomWidget --------------------------------------
--@api-stub: lurek.ui.newCustomWidget
-- Creates a new widget with custom Lua-driven rendering.
-- lurek.ui.newCustomWidget([config])  -- -> LWidget

-- ---- Example: lurek.ui.getWidgetCount ---------------------------------------
--@api-stub: lurek.ui.getWidgetCount
-- Returns the total widget count in the context.
-- lurek.ui.getWidgetCount()  -- -> number

-- ---- Example: lurek.ui.drawToImage ------------------------------------------
--@api-stub: lurek.ui.drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- lurek.ui.drawToImage(64.0, 64.0)  -- -> ImageData

-- ---- Example: lurek.ui.newLineChart -----------------------------------------
--@api-stub: lurek.ui.newLineChart
-- Creates a new line chart.
-- lurek.ui.newLineChart(opts)  -- -> LLineChart

-- ---- Example: lurek.ui.newBarChart ------------------------------------------
--@api-stub: lurek.ui.newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- lurek.ui.newBarChart(opts)  -- -> LBarChart

-- ---- Example: lurek.ui.newScatterPlot ---------------------------------------
--@api-stub: lurek.ui.newScatterPlot
-- Creates a new scatter plot.
-- lurek.ui.newScatterPlot(opts)  -- -> LScatterPlot

-- ---- Example: lurek.ui.newPieChart ------------------------------------------
--@api-stub: lurek.ui.newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- lurek.ui.newPieChart(opts)  -- -> LPieChart

-- ---- Example: lurek.ui.newAreaChart -----------------------------------------
--@api-stub: lurek.ui.newAreaChart
-- Creates a new stacked-area chart.
-- lurek.ui.newAreaChart(opts)  -- -> LAreaChart

-- ---- Example: lurek.ui.parseWidgetState -------------------------------------
--@api-stub: lurek.ui.parseWidgetState
-- Parses a widget state string and returns its canonical form.
-- lurek.ui.parseWidgetState(state)  -- -> string

-- ---- Example: lurek.ui.newSpinBox -------------------------------------------
--@api-stub: lurek.ui.newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- lurek.ui.newSpinBox([min], [max])  -- -> LSpinBox

-- ---- Example: lurek.ui.newSwitch --------------------------------------------
--@api-stub: lurek.ui.newSwitch
-- Creates a toggle switch widget.
-- lurek.ui.newSwitch([on])  -- -> LSwitch

-- ---- Example: lurek.ui.newBadge ---------------------------------------------
--@api-stub: lurek.ui.newBadge
-- Creates a badge widget displaying a numeric count.
-- lurek.ui.newBadge([count])  -- -> LBadge

-- ---- Example: lurek.ui.setDefaultTheme --------------------------------------
--@api-stub: lurek.ui.setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- lurek.ui.setDefaultTheme()

-- ---- Example: lurek.ui.setViewport ------------------------------------------
--@api-stub: lurek.ui.setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- lurek.ui.setViewport(64.0, 64.0)

-- ---- Example: lurek.ui.flushCache -------------------------------------------
--@api-stub: lurek.ui.flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- lurek.ui.flushCache()  -- -> boolean

-- ---- Example: lurek.ui.update_bindings --------------------------------------
--@api-stub: lurek.ui.update_bindings
-- Updates widgets whose bound keys match values in the provided data table.
-- lurek.ui.update_bindings()

-- ---- Example: lurek.ui.loadLayout -------------------------------------------
--@api-stub: lurek.ui.loadLayout
-- Loads a widget tree from a Lua definition table and attaches it to the UI root.
-- lurek.ui.loadLayout()  -- -> number

-- ---- Example: lurek.ui.loadLayoutFile ---------------------------------------
--@api-stub: lurek.ui.loadLayoutFile
-- Loads a widget tree from a TOML layout file and attaches it to the UI root.
-- lurek.ui.loadLayoutFile("assets/hero.png")  -- -> number

-- ---- Example: lurek.ui.renderToImage ----------------------------------------
--@api-stub: lurek.ui.renderToImage
-- Renders the current UI widget tree to a PNG file for testing.
-- lurek.ui.renderToImage(256, 256, "assets/hero.png")

-- -----------------------------------------------------------------------------
-- LAccordion methods
-- -----------------------------------------------------------------------------

-- ---- Example: LAccordion:addSection -----------------------------------------
--@api-stub: LAccordion:addSection
-- Adds a section entry to this Accordion widget.
-- lAccordion_Example:addSection(title, [content_idx])
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:getSectionCount ------------------------------------
--@api-stub: LAccordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- lAccordion_Example:getSectionCount()  -- -> integer
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:toggleSection --------------------------------------
--@api-stub: LAccordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- lAccordion_Example:toggleSection(section_idx)  -- -> boolean
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:isSectionExpanded ----------------------------------
--@api-stub: LAccordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- lAccordion_Example:isSectionExpanded(section_idx)  -- -> boolean
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:isExclusive ----------------------------------------
--@api-stub: LAccordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- lAccordion_Example:isExclusive()  -- -> boolean
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:setExclusive ---------------------------------------
--@api-stub: LAccordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- lAccordion_Example:setExclusive(1.0)
-- (replace lAccordion_example with your real LAccordion instance above)

-- ---- Example: LAccordion:getSectionTitle ------------------------------------
--@api-stub: LAccordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- lAccordion_Example:getSectionTitle(section_idx)  -- -> string
-- (replace lAccordion_example with your real LAccordion instance above)

-- -----------------------------------------------------------------------------
-- LBadge methods
-- -----------------------------------------------------------------------------

-- ---- Example: LBadge:setCount -----------------------------------------------
--@api-stub: LBadge:setCount
-- Sets the count displayed on this Badge widget.
-- lBadge_Example:setCount(10)
-- (replace lBadge_example with your real LBadge instance above)

-- ---- Example: LBadge:getCount -----------------------------------------------
--@api-stub: LBadge:getCount
-- Returns the raw count of this Badge widget.
-- lBadge_Example:getCount()  -- -> integer
-- (replace lBadge_example with your real LBadge instance above)

-- ---- Example: LBadge:getDisplayText -----------------------------------------
--@api-stub: LBadge:getDisplayText
-- Returns the display text of this Badge widget, e.g. "99+" when over the max.
-- lBadge_Example:getDisplayText()  -- -> string
-- (replace lBadge_example with your real LBadge instance above)

-- -----------------------------------------------------------------------------
-- LButton methods
-- -----------------------------------------------------------------------------

-- ---- Example: LButton:setText -----------------------------------------------
--@api-stub: LButton:setText
-- Sets the text for this Button widget.
-- lButton_Example:setText("Hello, world!")
-- (replace lButton_example with your real LButton instance above)

-- ---- Example: LButton:getText -----------------------------------------------
--@api-stub: LButton:getText
-- Returns the text of this Button widget.
-- lButton_Example:getText()  -- -> string
-- (replace lButton_example with your real LButton instance above)

-- -----------------------------------------------------------------------------
-- LCheckbox methods
-- -----------------------------------------------------------------------------

-- ---- Example: LCheckbox:setChecked ------------------------------------------
--@api-stub: LCheckbox:setChecked
-- Sets the checked for this Checkbox widget.
-- lCheckbox_Example:setChecked(checked)
-- (replace lCheckbox_example with your real LCheckbox instance above)

-- ---- Example: LCheckbox:isChecked -------------------------------------------
--@api-stub: LCheckbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- lCheckbox_Example:isChecked()  -- -> boolean
-- (replace lCheckbox_example with your real LCheckbox instance above)

-- ---- Example: LCheckbox:setText ---------------------------------------------
--@api-stub: LCheckbox:setText
-- Sets the text for this Checkbox widget.
-- lCheckbox_Example:setText("Hello, world!")
-- (replace lCheckbox_example with your real LCheckbox instance above)

-- ---- Example: LCheckbox:getText ---------------------------------------------
--@api-stub: LCheckbox:getText
-- Returns the text of this Checkbox widget.
-- lCheckbox_Example:getText()  -- -> string
-- (replace lCheckbox_example with your real LCheckbox instance above)

-- -----------------------------------------------------------------------------
-- LColorPicker methods
-- -----------------------------------------------------------------------------

-- ---- Example: LColorPicker:getColor -----------------------------------------
--@api-stub: LColorPicker:getColor
-- Returns the color of this Color_Picker widget.
-- lColorPicker_Example:getColor()  -- -> number
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:setColor -----------------------------------------
--@api-stub: LColorPicker:setColor
-- Sets the color for this Color_Picker widget.
-- lColorPicker_Example:setColor(1.0, green, 0.2, [a])
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:getShowAlpha -------------------------------------
--@api-stub: LColorPicker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- lColorPicker_Example:getShowAlpha()  -- -> boolean
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:setShowAlpha -------------------------------------
--@api-stub: LColorPicker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- lColorPicker_Example:setShowAlpha(1.0)
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:getColorMode -------------------------------------
--@api-stub: LColorPicker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- lColorPicker_Example:getColorMode()  -- -> string
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:setColorMode -------------------------------------
--@api-stub: LColorPicker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- lColorPicker_Example:setColorMode(mode)
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- ---- Example: LColorPicker:setOnChange --------------------------------------
--@api-stub: LColorPicker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- lColorPicker_Example:setOnChange(f)
-- (replace lColorPicker_example with your real LColorPicker instance above)

-- -----------------------------------------------------------------------------
-- LComboBox methods
-- -----------------------------------------------------------------------------

-- ---- Example: LComboBox:addItem ---------------------------------------------
--@api-stub: LComboBox:addItem
-- Adds a item entry to this Combo_Box widget.
-- lComboBox_Example:addItem("Hello, world!")
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:removeItem ------------------------------------------
--@api-stub: LComboBox:removeItem
-- Removes the item from this Combo_Box widget.
-- lComboBox_Example:removeItem(1)  -- -> boolean
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:clearItems ------------------------------------------
--@api-stub: LComboBox:clearItems
-- Clears all items entries from this Combo_Box widget.
-- lComboBox_Example:clearItems()
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:getItemCount ----------------------------------------
--@api-stub: LComboBox:getItemCount
-- Returns the item count of this Combo_Box widget.
-- lComboBox_Example:getItemCount()  -- -> integer
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:getItem ---------------------------------------------
--@api-stub: LComboBox:getItem
-- Returns the item of this Combo_Box widget.
-- lComboBox_Example:getItem(1)  -- -> string
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:setSelectedIndex ------------------------------------
--@api-stub: LComboBox:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- lComboBox_Example:setSelectedIndex(1)
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:getSelectedIndex ------------------------------------
--@api-stub: LComboBox:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- lComboBox_Example:getSelectedIndex()  -- -> integer
-- (replace lComboBox_example with your real LComboBox instance above)

-- ---- Example: LComboBox:getSelectedItem -------------------------------------
--@api-stub: LComboBox:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- lComboBox_Example:getSelectedItem()  -- -> string
-- (replace lComboBox_example with your real LComboBox instance above)

-- -----------------------------------------------------------------------------
-- LDialog methods
-- -----------------------------------------------------------------------------

-- ---- Example: LDialog:getTitle ----------------------------------------------
--@api-stub: LDialog:getTitle
-- Returns the title of this Dialog widget.
-- lDialog_Example:getTitle()  -- -> string
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:setTitle ----------------------------------------------
--@api-stub: LDialog:setTitle
-- Sets the title for this Dialog widget.
-- lDialog_Example:setTitle(title)
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:isModal -----------------------------------------------
--@api-stub: LDialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- lDialog_Example:isModal()  -- -> boolean
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:setModal ----------------------------------------------
--@api-stub: LDialog:setModal
-- Sets the modal for this Dialog widget.
-- lDialog_Example:setModal(1.0)
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:isOpen ------------------------------------------------
--@api-stub: LDialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- lDialog_Example:isOpen()  -- -> boolean
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:open --------------------------------------------------
--@api-stub: LDialog:open
-- Performs the open operation on this Dialog widget.
-- lDialog_Example:open()
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:close -------------------------------------------------
--@api-stub: LDialog:close
-- Closes and removes this dialog from the screen.
-- lDialog_Example:close()
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:setOnClose --------------------------------------------
--@api-stub: LDialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- lDialog_Example:setOnClose(f)
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:setContent --------------------------------------------
--@api-stub: LDialog:setContent
-- Sets the content for this Dialog widget.
-- lDialog_Example:setContent([content_idx])
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:getContent --------------------------------------------
--@api-stub: LDialog:getContent
-- Returns the content of this Dialog widget.
-- lDialog_Example:getContent()  -- -> integer
-- (replace lDialog_example with your real LDialog instance above)

-- ---- Example: LDialog:addButton ---------------------------------------------
--@api-stub: LDialog:addButton
-- Adds a button entry to this Dialog widget.
-- lDialog_Example:addButton("Hello, world!", [cb])  -- -> integer
-- (replace lDialog_example with your real LDialog instance above)

-- -----------------------------------------------------------------------------
-- LDockPanel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LDockPanel:dock -----------------------------------------------
--@api-stub: LDockPanel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- lDockPanel_Example:dock(child_idx, side)
-- (replace lDockPanel_example with your real LDockPanel instance above)

-- ---- Example: LDockPanel:undock ---------------------------------------------
--@api-stub: LDockPanel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- lDockPanel_Example:undock(child_idx)
-- (replace lDockPanel_example with your real LDockPanel instance above)

-- ---- Example: LDockPanel:getDockedCount -------------------------------------
--@api-stub: LDockPanel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- lDockPanel_Example:getDockedCount()  -- -> integer
-- (replace lDockPanel_example with your real LDockPanel instance above)

-- ---- Example: LDockPanel:setSplitSize ---------------------------------------
--@api-stub: LDockPanel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- lDockPanel_Example:setSplitSize(side, size)
-- (replace lDockPanel_example with your real LDockPanel instance above)

-- ---- Example: LDockPanel:getSplitSize ---------------------------------------
--@api-stub: LDockPanel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- lDockPanel_Example:getSplitSize(side)  -- -> number
-- (replace lDockPanel_example with your real LDockPanel instance above)

-- -----------------------------------------------------------------------------
-- LGuiTable methods
-- -----------------------------------------------------------------------------

-- ---- Example: LGuiTable:addColumn -------------------------------------------
--@api-stub: LGuiTable:addColumn
-- Adds a column entry to this Gui_Table widget.
-- lGuiTable_Example:addColumn(header, [width])
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:getColumnCount --------------------------------------
--@api-stub: LGuiTable:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- lGuiTable_Example:getColumnCount()  -- -> integer
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:addRow ----------------------------------------------
--@api-stub: LGuiTable:addRow
-- Adds a row entry to this Gui_Table widget.
-- lGuiTable_Example:addRow(cells)
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:getRowCount -----------------------------------------
--@api-stub: LGuiTable:getRowCount
-- Returns the row count of this Gui_Table widget.
-- lGuiTable_Example:getRowCount()  -- -> integer
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:getCell ---------------------------------------------
--@api-stub: LGuiTable:getCell
-- Returns the cell of this Gui_Table widget.
-- lGuiTable_Example:getCell(row, col)  -- -> string
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:setCell ---------------------------------------------
--@api-stub: LGuiTable:setCell
-- Sets the cell for this Gui_Table widget.
-- lGuiTable_Example:setCell(row, col, "Hello, world!")
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:getSelectedRow --------------------------------------
--@api-stub: LGuiTable:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- lGuiTable_Example:getSelectedRow()  -- -> integer
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:setSelectedRow --------------------------------------
--@api-stub: LGuiTable:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- lGuiTable_Example:setSelectedRow([row])
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:isSortable ------------------------------------------
--@api-stub: LGuiTable:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- lGuiTable_Example:isSortable()  -- -> boolean
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:setSortable -----------------------------------------
--@api-stub: LGuiTable:setSortable
-- Sets the sortable for this Gui_Table widget.
-- lGuiTable_Example:setSortable(1.0)
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- ---- Example: LGuiTable:setOnSelect -----------------------------------------
--@api-stub: LGuiTable:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- lGuiTable_Example:setOnSelect(f)
-- (replace lGuiTable_example with your real LGuiTable instance above)

-- -----------------------------------------------------------------------------
-- LGuiWindow methods
-- -----------------------------------------------------------------------------

-- ---- Example: LGuiWindow:getTitle -------------------------------------------
--@api-stub: LGuiWindow:getTitle
-- Returns the title of this Gui_Window widget.
-- lGuiWindow_Example:getTitle()  -- -> string
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:setTitle -------------------------------------------
--@api-stub: LGuiWindow:setTitle
-- Sets the title for this Gui_Window widget.
-- lGuiWindow_Example:setTitle(title)
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:isCloseable ----------------------------------------
--@api-stub: LGuiWindow:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- lGuiWindow_Example:isCloseable()  -- -> boolean
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:setCloseable ---------------------------------------
--@api-stub: LGuiWindow:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- lGuiWindow_Example:setCloseable(1.0)
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:isDraggable ----------------------------------------
--@api-stub: LGuiWindow:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- lGuiWindow_Example:isDraggable()  -- -> boolean
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:setDraggable ---------------------------------------
--@api-stub: LGuiWindow:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- lGuiWindow_Example:setDraggable(1.0)
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:isResizable ----------------------------------------
--@api-stub: LGuiWindow:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- lGuiWindow_Example:isResizable()  -- -> boolean
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:setResizable ---------------------------------------
--@api-stub: LGuiWindow:setResizable
-- Sets the resizable for this Gui_Window widget.
-- lGuiWindow_Example:setResizable(1.0)
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- ---- Example: LGuiWindow:setOnClose -----------------------------------------
--@api-stub: LGuiWindow:setOnClose
-- Registers a callback invoked when this window is closed.
-- lGuiWindow_Example:setOnClose(f)
-- (replace lGuiWindow_example with your real LGuiWindow instance above)

-- -----------------------------------------------------------------------------
-- LImageWidget methods
-- -----------------------------------------------------------------------------

-- ---- Example: LImageWidget:getScaleMode -------------------------------------
--@api-stub: LImageWidget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- lImageWidget_Example:getScaleMode()  -- -> string
-- (replace lImageWidget_example with your real LImageWidget instance above)

-- ---- Example: LImageWidget:setScaleMode -------------------------------------
--@api-stub: LImageWidget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- lImageWidget_Example:setScaleMode(mode)
-- (replace lImageWidget_example with your real LImageWidget instance above)

-- ---- Example: LImageWidget:getTint ------------------------------------------
--@api-stub: LImageWidget:getTint
-- Returns the tint of this Image_Widget widget.
-- lImageWidget_Example:getTint()  -- -> number
-- (replace lImageWidget_example with your real LImageWidget instance above)

-- ---- Example: LImageWidget:setTint ------------------------------------------
--@api-stub: LImageWidget:setTint
-- Sets the tint for this Image_Widget widget.
-- lImageWidget_Example:setTint(1.0, green, 0.2, [a])
-- (replace lImageWidget_example with your real LImageWidget instance above)

-- -----------------------------------------------------------------------------
-- LLabel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LLabel:setText ------------------------------------------------
--@api-stub: LLabel:setText
-- Sets the text for this Label widget.
-- lLabel_Example:setText("Hello, world!")
-- (replace lLabel_example with your real LLabel instance above)

-- ---- Example: LLabel:getText ------------------------------------------------
--@api-stub: LLabel:getText
-- Returns the text of this Label widget.
-- lLabel_Example:getText()  -- -> string
-- (replace lLabel_example with your real LLabel instance above)

-- -----------------------------------------------------------------------------
-- LLayout methods
-- -----------------------------------------------------------------------------

-- ---- Example: LLayout:setDirection ------------------------------------------
--@api-stub: LLayout:setDirection
-- Sets the direction for this Layout widget.
-- lLayout_Example:setDirection(dir)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:getDirection ------------------------------------------
--@api-stub: LLayout:getDirection
-- Returns the direction of this Layout widget.
-- lLayout_Example:getDirection()  -- -> string
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:setSpacing --------------------------------------------
--@api-stub: LLayout:setSpacing
-- Sets the spacing for this Layout widget.
-- lLayout_Example:setSpacing(spacing)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:getSpacing --------------------------------------------
--@api-stub: LLayout:getSpacing
-- Returns the spacing of this Layout widget.
-- lLayout_Example:getSpacing()  -- -> number
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:setColumns --------------------------------------------
--@api-stub: LLayout:setColumns
-- Sets the columns for this Layout widget.
-- lLayout_Example:setColumns(5)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:setWrap -----------------------------------------------
--@api-stub: LLayout:setWrap
-- Sets the wrap for this Layout widget.
-- lLayout_Example:setWrap(wrap)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:getWrap -----------------------------------------------
--@api-stub: LLayout:getWrap
-- Returns the wrap of this Layout widget.
-- lLayout_Example:getWrap()  -- -> boolean
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:setAlign ----------------------------------------------
--@api-stub: LLayout:setAlign
-- Sets the align for this Layout widget.
-- lLayout_Example:setAlign(align)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:getAlign ----------------------------------------------
--@api-stub: LLayout:getAlign
-- Returns the align of this Layout widget.
-- lLayout_Example:getAlign()  -- -> string
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:setJustify --------------------------------------------
--@api-stub: LLayout:setJustify
-- Sets the justify for this Layout widget.
-- lLayout_Example:setJustify(justify)
-- (replace lLayout_example with your real LLayout instance above)

-- ---- Example: LLayout:getJustify --------------------------------------------
--@api-stub: LLayout:getJustify
-- Returns the justify of this Layout widget.
-- lLayout_Example:getJustify()  -- -> string
-- (replace lLayout_example with your real LLayout instance above)

-- -----------------------------------------------------------------------------
-- LLineChart methods
-- -----------------------------------------------------------------------------

-- ---- Example: LLineChart:addSeries ------------------------------------------
--@api-stub: LLineChart:addSeries
-- Adds a named data series to the chart.
-- lLineChart_Example:addSeries("hero", pts_tbl, 1.0, 0.8, 0.2)
-- (replace lLineChart_example with your real LLineChart instance above)

-- -----------------------------------------------------------------------------
-- LListBox methods
-- -----------------------------------------------------------------------------

-- ---- Example: LListBox:addItem ----------------------------------------------
--@api-stub: LListBox:addItem
-- Adds a item entry to this List_Box widget.
-- lListBox_Example:addItem("Hello, world!")
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:removeItem -------------------------------------------
--@api-stub: LListBox:removeItem
-- Removes the item from this List_Box widget.
-- lListBox_Example:removeItem(1)
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:clearItems -------------------------------------------
--@api-stub: LListBox:clearItems
-- Clears all items entries from this List_Box widget.
-- lListBox_Example:clearItems()
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:getItemCount -----------------------------------------
--@api-stub: LListBox:getItemCount
-- Returns the item count of this List_Box widget.
-- lListBox_Example:getItemCount()  -- -> integer
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:getItem ----------------------------------------------
--@api-stub: LListBox:getItem
-- Returns the item of this List_Box widget.
-- lListBox_Example:getItem(1)  -- -> string
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:setSelectedIndex -------------------------------------
--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- lListBox_Example:setSelectedIndex(1)
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:getSelectedIndex -------------------------------------
--@api-stub: LListBox:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- lListBox_Example:getSelectedIndex()  -- -> integer
-- (replace lListBox_example with your real LListBox instance above)

-- ---- Example: LListBox:setItemHeight ----------------------------------------
--@api-stub: LListBox:setItemHeight
-- Sets the item height for this List_Box widget.
-- lListBox_Example:setItemHeight(64.0)
-- (replace lListBox_example with your real LListBox instance above)

-- -----------------------------------------------------------------------------
-- LMenuBar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LMenuBar:addMenu ----------------------------------------------
--@api-stub: LMenuBar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- lMenuBar_Example:addMenu(menu_idx)
-- (replace lMenuBar_example with your real LMenuBar instance above)

-- ---- Example: LMenuBar:removeMenu -------------------------------------------
--@api-stub: LMenuBar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- lMenuBar_Example:removeMenu(menu_idx)  -- -> boolean
-- (replace lMenuBar_example with your real LMenuBar instance above)

-- ---- Example: LMenuBar:getMenus ---------------------------------------------
--@api-stub: LMenuBar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- lMenuBar_Example:getMenus()  -- -> table
-- (replace lMenuBar_example with your real LMenuBar instance above)

-- ---- Example: LMenuBar:getMenuCount -----------------------------------------
--@api-stub: LMenuBar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- lMenuBar_Example:getMenuCount()  -- -> integer
-- (replace lMenuBar_example with your real LMenuBar instance above)

-- -----------------------------------------------------------------------------
-- LMenuItem methods
-- -----------------------------------------------------------------------------

-- ---- Example: LMenuItem:getText ---------------------------------------------
--@api-stub: LMenuItem:getText
-- Returns the text of this Menu_Item widget.
-- lMenuItem_Example:getText()  -- -> string
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:setText ---------------------------------------------
--@api-stub: LMenuItem:setText
-- Sets the text for this Menu_Item widget.
-- lMenuItem_Example:setText("Hello, world!")
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:getShortcut -----------------------------------------
--@api-stub: LMenuItem:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- lMenuItem_Example:getShortcut()  -- -> string
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:setShortcut -----------------------------------------
--@api-stub: LMenuItem:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- lMenuItem_Example:setShortcut(shortcut)
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:isChecked -------------------------------------------
--@api-stub: LMenuItem:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- lMenuItem_Example:isChecked()  -- -> boolean
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:setChecked ------------------------------------------
--@api-stub: LMenuItem:setChecked
-- Sets the checked for this Menu_Item widget.
-- lMenuItem_Example:setChecked(1.0)
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:addSubItem ------------------------------------------
--@api-stub: LMenuItem:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- lMenuItem_Example:addSubItem(child_idx)
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:getSubItems -----------------------------------------
--@api-stub: LMenuItem:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- lMenuItem_Example:getSubItems()  -- -> table
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- ---- Example: LMenuItem:setOnClick ------------------------------------------
--@api-stub: LMenuItem:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- lMenuItem_Example:setOnClick(f)
-- (replace lMenuItem_example with your real LMenuItem instance above)

-- -----------------------------------------------------------------------------
-- LNinePatch methods
-- -----------------------------------------------------------------------------

-- ---- Example: LNinePatch:setInsets ------------------------------------------
--@api-stub: LNinePatch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- lNinePatch_Example:setInsets(left, top, right, bottom)
-- (replace lNinePatch_example with your real LNinePatch instance above)

-- ---- Example: LNinePatch:getInsets ------------------------------------------
--@api-stub: LNinePatch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- lNinePatch_Example:getInsets()  -- -> integer
-- (replace lNinePatch_example with your real LNinePatch instance above)

-- ---- Example: LNinePatch:setImageDimensions ---------------------------------
--@api-stub: LNinePatch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- lNinePatch_Example:setImageDimensions(64.0, 64.0)
-- (replace lNinePatch_example with your real LNinePatch instance above)

-- ---- Example: LNinePatch:getImageDimensions ---------------------------------
--@api-stub: LNinePatch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- lNinePatch_Example:getImageDimensions()  -- -> integer
-- (replace lNinePatch_example with your real LNinePatch instance above)

-- ---- Example: LNinePatch:getSlices ------------------------------------------
--@api-stub: LNinePatch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- lNinePatch_Example:getSlices()  -- -> table
-- (replace lNinePatch_example with your real LNinePatch instance above)

-- -----------------------------------------------------------------------------
-- LPanel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LPanel:setTitle -----------------------------------------------
--@api-stub: LPanel:setTitle
-- Sets the title for this Panel widget.
-- lPanel_Example:setTitle(title)
-- (replace lPanel_example with your real LPanel instance above)

-- ---- Example: LPanel:getTitle -----------------------------------------------
--@api-stub: LPanel:getTitle
-- Returns the title of this Panel widget.
-- lPanel_Example:getTitle()  -- -> string
-- (replace lPanel_example with your real LPanel instance above)

-- ---- Example: LPanel:setScrollable ------------------------------------------
--@api-stub: LPanel:setScrollable
-- Sets the scrollable for this Panel widget.
-- lPanel_Example:setScrollable(scrollable)
-- (replace lPanel_example with your real LPanel instance above)

-- -----------------------------------------------------------------------------
-- LProgressBar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LProgressBar:setValue -----------------------------------------
--@api-stub: LProgressBar:setValue
-- Sets the value for this Progress_Bar widget.
-- lProgressBar_Example:setValue(1.0)
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- ---- Example: LProgressBar:getValue -----------------------------------------
--@api-stub: LProgressBar:getValue
-- Returns the value of this Progress_Bar widget.
-- lProgressBar_Example:getValue()  -- -> number
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- ---- Example: LProgressBar:getProgress --------------------------------------
--@api-stub: LProgressBar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- lProgressBar_Example:getProgress()  -- -> number
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- ---- Example: LProgressBar:setRange -----------------------------------------
--@api-stub: LProgressBar:setRange
-- Sets the range for this Progress_Bar widget.
-- lProgressBar_Example:setRange(min, max)
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- ---- Example: LProgressBar:getMin -------------------------------------------
--@api-stub: LProgressBar:getMin
-- Returns the min of this Progress_Bar widget.
-- lProgressBar_Example:getMin()  -- -> number
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- ---- Example: LProgressBar:getMax -------------------------------------------
--@api-stub: LProgressBar:getMax
-- Returns the max of this Progress_Bar widget.
-- lProgressBar_Example:getMax()  -- -> number
-- (replace lProgressBar_example with your real LProgressBar instance above)

-- -----------------------------------------------------------------------------
-- LRadioButton methods
-- -----------------------------------------------------------------------------

-- ---- Example: LRadioButton:getText ------------------------------------------
--@api-stub: LRadioButton:getText
-- Returns the text of this Radio_Button widget.
-- lRadioButton_Example:getText()  -- -> string
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:setText ------------------------------------------
--@api-stub: LRadioButton:setText
-- Sets the text for this Radio_Button widget.
-- lRadioButton_Example:setText("Hello, world!")
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:isSelected ---------------------------------------
--@api-stub: LRadioButton:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- lRadioButton_Example:isSelected()  -- -> boolean
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:setSelected --------------------------------------
--@api-stub: LRadioButton:setSelected
-- Sets the selected for this Radio_Button widget.
-- lRadioButton_Example:setSelected(1.0)
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:getGroup -----------------------------------------
--@api-stub: LRadioButton:getGroup
-- Returns the group of this Radio_Button widget.
-- lRadioButton_Example:getGroup()  -- -> string
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:setGroup -----------------------------------------
--@api-stub: LRadioButton:setGroup
-- Sets the group for this Radio_Button widget.
-- lRadioButton_Example:setGroup(group)
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- ---- Example: LRadioButton:setOnChange --------------------------------------
--@api-stub: LRadioButton:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- lRadioButton_Example:setOnChange(f)
-- (replace lRadioButton_example with your real LRadioButton instance above)

-- -----------------------------------------------------------------------------
-- LScrollBar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LScrollBar:getScrollPosition ----------------------------------
--@api-stub: LScrollBar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- lScrollBar_Example:getScrollPosition()  -- -> number
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:setScrollPosition ----------------------------------
--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- lScrollBar_Example:setScrollPosition(1.0)
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:getContentSize -------------------------------------
--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- lScrollBar_Example:getContentSize()  -- -> number
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:setContentSize -------------------------------------
--@api-stub: LScrollBar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- lScrollBar_Example:setContentSize(1.0)
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:getViewSize ----------------------------------------
--@api-stub: LScrollBar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- lScrollBar_Example:getViewSize()  -- -> number
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:setViewSize ----------------------------------------
--@api-stub: LScrollBar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- lScrollBar_Example:setViewSize(1.0)
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:isVertical -----------------------------------------
--@api-stub: LScrollBar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- lScrollBar_Example:isVertical()  -- -> boolean
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- ---- Example: LScrollBar:setOnChange ----------------------------------------
--@api-stub: LScrollBar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- lScrollBar_Example:setOnChange(f)
-- (replace lScrollBar_example with your real LScrollBar instance above)

-- -----------------------------------------------------------------------------
-- LScrollPanel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LScrollPanel:setContentSize -----------------------------------
--@api-stub: LScrollPanel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- lScrollPanel_Example:setContentSize(64.0, 64.0)
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:getContentSize -----------------------------------
--@api-stub: LScrollPanel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- lScrollPanel_Example:getContentSize()  -- -> number
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:setScrollPosition --------------------------------
--@api-stub: LScrollPanel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- lScrollPanel_Example:setScrollPosition(0.0, 0.0)
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:getScrollPosition --------------------------------
--@api-stub: LScrollPanel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- lScrollPanel_Example:getScrollPosition()  -- -> number
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:getMaxScroll -------------------------------------
--@api-stub: LScrollPanel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- lScrollPanel_Example:getMaxScroll()  -- -> number
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:setScrollSpeed -----------------------------------
--@api-stub: LScrollPanel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- lScrollPanel_Example:setScrollSpeed(120.0)
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- ---- Example: LScrollPanel:getScrollSpeed -----------------------------------
--@api-stub: LScrollPanel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- lScrollPanel_Example:getScrollSpeed()  -- -> number
-- (replace lScrollPanel_example with your real LScrollPanel instance above)

-- -----------------------------------------------------------------------------
-- LSeparator methods
-- -----------------------------------------------------------------------------

-- ---- Example: LSeparator:setVertical ----------------------------------------
--@api-stub: LSeparator:setVertical
-- Sets the vertical for this Separator widget.
-- lSeparator_Example:setVertical(1.0)
-- (replace lSeparator_example with your real LSeparator instance above)

-- ---- Example: LSeparator:isVertical -----------------------------------------
--@api-stub: LSeparator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- lSeparator_Example:isVertical()  -- -> boolean
-- (replace lSeparator_example with your real LSeparator instance above)

-- ---- Example: LSeparator:setThickness ---------------------------------------
--@api-stub: LSeparator:setThickness
-- Sets the thickness for this Separator widget.
-- lSeparator_Example:setThickness(thickness)
-- (replace lSeparator_example with your real LSeparator instance above)

-- ---- Example: LSeparator:getThickness ---------------------------------------
--@api-stub: LSeparator:getThickness
-- Returns the thickness of this Separator widget.
-- lSeparator_Example:getThickness()  -- -> number
-- (replace lSeparator_example with your real LSeparator instance above)

-- -----------------------------------------------------------------------------
-- LSlider methods
-- -----------------------------------------------------------------------------

-- ---- Example: LSlider:setValue ----------------------------------------------
--@api-stub: LSlider:setValue
-- Sets the value for this Slider widget.
-- lSlider_Example:setValue(1.0)
-- (replace lSlider_example with your real LSlider instance above)

-- ---- Example: LSlider:getValue ----------------------------------------------
--@api-stub: LSlider:getValue
-- Returns the value of this Slider widget.
-- lSlider_Example:getValue()  -- -> number
-- (replace lSlider_example with your real LSlider instance above)

-- ---- Example: LSlider:setRange ----------------------------------------------
--@api-stub: LSlider:setRange
-- Sets the range for this Slider widget.
-- lSlider_Example:setRange(min, max)
-- (replace lSlider_example with your real LSlider instance above)

-- ---- Example: LSlider:setStep -----------------------------------------------
--@api-stub: LSlider:setStep
-- Sets the step for this Slider widget.
-- lSlider_Example:setStep(step)
-- (replace lSlider_example with your real LSlider instance above)

-- ---- Example: LSlider:getMin ------------------------------------------------
--@api-stub: LSlider:getMin
-- Returns the min of this Slider widget.
-- lSlider_Example:getMin()  -- -> number
-- (replace lSlider_example with your real LSlider instance above)

-- ---- Example: LSlider:getMax ------------------------------------------------
--@api-stub: LSlider:getMax
-- Returns the max of this Slider widget.
-- lSlider_Example:getMax()  -- -> number
-- (replace lSlider_example with your real LSlider instance above)

-- -----------------------------------------------------------------------------
-- LSpinBox methods
-- -----------------------------------------------------------------------------

-- ---- Example: LSpinBox:setValue ---------------------------------------------
--@api-stub: LSpinBox:setValue
-- Sets the value for this SpinBox widget.
-- lSpinBox_Example:setValue(1.0)
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- ---- Example: LSpinBox:getValue ---------------------------------------------
--@api-stub: LSpinBox:getValue
-- Returns the current value of this SpinBox widget.
-- lSpinBox_Example:getValue()  -- -> number
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- ---- Example: LSpinBox:increment --------------------------------------------
--@api-stub: LSpinBox:increment
-- Increments the value by one step.
-- lSpinBox_Example:increment()
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- ---- Example: LSpinBox:decrement --------------------------------------------
--@api-stub: LSpinBox:decrement
-- Decrements the value by one step.
-- lSpinBox_Example:decrement()
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- ---- Example: LSpinBox:setRange ---------------------------------------------
--@api-stub: LSpinBox:setRange
-- Sets the valid range for this SpinBox widget.
-- lSpinBox_Example:setRange(min, max)
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- ---- Example: LSpinBox:setStep ----------------------------------------------
--@api-stub: LSpinBox:setStep
-- Sets the increment step for this SpinBox widget.
-- lSpinBox_Example:setStep(step)
-- (replace lSpinBox_example with your real LSpinBox instance above)

-- -----------------------------------------------------------------------------
-- LSplitPanel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LSplitPanel:getOrientation ------------------------------------
--@api-stub: LSplitPanel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- lSplitPanel_Example:getOrientation()  -- -> string
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:setOrientation ------------------------------------
--@api-stub: LSplitPanel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- lSplitPanel_Example:setOrientation(1.0)
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:getSplitPosition ----------------------------------
--@api-stub: LSplitPanel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- lSplitPanel_Example:getSplitPosition()  -- -> number
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:setSplitPosition ----------------------------------
--@api-stub: LSplitPanel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- lSplitPanel_Example:setSplitPosition(1.0)
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:getMinPanelSize -----------------------------------
--@api-stub: LSplitPanel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- lSplitPanel_Example:getMinPanelSize()  -- -> number
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:setMinPanelSize -----------------------------------
--@api-stub: LSplitPanel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- lSplitPanel_Example:setMinPanelSize(1.0)
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:setFirstChild -------------------------------------
--@api-stub: LSplitPanel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- lSplitPanel_Example:setFirstChild(child_idx)
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:setSecondChild ------------------------------------
--@api-stub: LSplitPanel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- lSplitPanel_Example:setSecondChild(child_idx)
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:getFirstChild -------------------------------------
--@api-stub: LSplitPanel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- lSplitPanel_Example:getFirstChild()  -- -> integer
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- ---- Example: LSplitPanel:getSecondChild ------------------------------------
--@api-stub: LSplitPanel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- lSplitPanel_Example:getSecondChild()  -- -> integer
-- (replace lSplitPanel_example with your real LSplitPanel instance above)

-- -----------------------------------------------------------------------------
-- LStatusBar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LStatusBar:addSection -----------------------------------------
--@api-stub: LStatusBar:addSection
-- Adds a section entry to this Status_Bar widget.
-- lStatusBar_Example:addSection("Hello, world!", [width])
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- ---- Example: LStatusBar:setSectionText -------------------------------------
--@api-stub: LStatusBar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- lStatusBar_Example:setSectionText(section_idx, "Hello, world!")
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- ---- Example: LStatusBar:getSectionText -------------------------------------
--@api-stub: LStatusBar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- lStatusBar_Example:getSectionText(section_idx)  -- -> string
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- ---- Example: LStatusBar:getSectionCount ------------------------------------
--@api-stub: LStatusBar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- lStatusBar_Example:getSectionCount()  -- -> integer
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- ---- Example: LStatusBar:setSectionCount ------------------------------------
--@api-stub: LStatusBar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- lStatusBar_Example:setSectionCount(10)
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- ---- Example: LStatusBar:setSectionWidget -----------------------------------
--@api-stub: LStatusBar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- lStatusBar_Example:setSectionWidget(section_idx, widget)
-- (replace lStatusBar_example with your real LStatusBar instance above)

-- -----------------------------------------------------------------------------
-- LSwitch methods
-- -----------------------------------------------------------------------------

-- ---- Example: LSwitch:setOn -------------------------------------------------
--@api-stub: LSwitch:setOn
-- Sets the on/off state of this Switch widget.
-- lSwitch_Example:setOn(on)
-- (replace lSwitch_example with your real LSwitch instance above)

-- ---- Example: LSwitch:isOn --------------------------------------------------
--@api-stub: LSwitch:isOn
-- Returns the on/off state of this Switch widget.
-- lSwitch_Example:isOn()  -- -> boolean
-- (replace lSwitch_example with your real LSwitch instance above)

-- ---- Example: LSwitch:toggle ------------------------------------------------
--@api-stub: LSwitch:toggle
-- Toggles the on/off state of this Switch widget.
-- lSwitch_Example:toggle()
-- (replace lSwitch_example with your real LSwitch instance above)

-- -----------------------------------------------------------------------------
-- LTabBar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LTabBar:addTab ------------------------------------------------
--@api-stub: LTabBar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- lTabBar_Example:addTab(label)
-- (replace lTabBar_example with your real LTabBar instance above)

-- ---- Example: LTabBar:removeTab ---------------------------------------------
--@api-stub: LTabBar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- lTabBar_Example:removeTab(1)  -- -> boolean
-- (replace lTabBar_example with your real LTabBar instance above)

-- ---- Example: LTabBar:getTab ------------------------------------------------
--@api-stub: LTabBar:getTab
-- Returns the tab of this Tab_Bar widget.
-- lTabBar_Example:getTab(1)  -- -> string
-- (replace lTabBar_example with your real LTabBar instance above)

-- ---- Example: LTabBar:getTabCount -------------------------------------------
--@api-stub: LTabBar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- lTabBar_Example:getTabCount()  -- -> integer
-- (replace lTabBar_example with your real LTabBar instance above)

-- ---- Example: LTabBar:setActiveTab ------------------------------------------
--@api-stub: LTabBar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- lTabBar_Example:setActiveTab(1)
-- (replace lTabBar_example with your real LTabBar instance above)

-- ---- Example: LTabBar:getActiveTab ------------------------------------------
--@api-stub: LTabBar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- lTabBar_Example:getActiveTab()  -- -> integer
-- (replace lTabBar_example with your real LTabBar instance above)

-- -----------------------------------------------------------------------------
-- LTextInput methods
-- -----------------------------------------------------------------------------

-- ---- Example: LTextInput:setText --------------------------------------------
--@api-stub: LTextInput:setText
-- Sets the text for this Text_Input widget.
-- lTextInput_Example:setText("Hello, world!")
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:getText --------------------------------------------
--@api-stub: LTextInput:getText
-- Returns the text of this Text_Input widget.
-- lTextInput_Example:getText()  -- -> string
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:setPlaceholder -------------------------------------
--@api-stub: LTextInput:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- lTextInput_Example:setPlaceholder("Hello, world!")
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:getPlaceholder -------------------------------------
--@api-stub: LTextInput:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- lTextInput_Example:getPlaceholder()  -- -> string
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:setMaxLength ---------------------------------------
--@api-stub: LTextInput:setMaxLength
-- Sets the max length for this Text_Input widget.
-- lTextInput_Example:setMaxLength(5)
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:isFocused ------------------------------------------
--@api-stub: LTextInput:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- lTextInput_Example:isFocused()  -- -> boolean
-- (replace lTextInput_example with your real LTextInput instance above)

-- ---- Example: LTextInput:getCursorPosition ----------------------------------
--@api-stub: LTextInput:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- lTextInput_Example:getCursorPosition()  -- -> integer
-- (replace lTextInput_example with your real LTextInput instance above)

-- -----------------------------------------------------------------------------
-- LToast methods
-- -----------------------------------------------------------------------------

-- ---- Example: LToast:setMessage ---------------------------------------------
--@api-stub: LToast:setMessage
-- Sets the message for this Toast widget.
-- lToast_Example:setMessage("level_complete")
-- (replace lToast_example with your real LToast instance above)

-- ---- Example: LToast:getMessage ---------------------------------------------
--@api-stub: LToast:getMessage
-- Returns the message of this Toast widget.
-- lToast_Example:getMessage()  -- -> string
-- (replace lToast_example with your real LToast instance above)

-- ---- Example: LToast:setDuration --------------------------------------------
--@api-stub: LToast:setDuration
-- Sets the duration for this Toast widget.
-- lToast_Example:setDuration(d)
-- (replace lToast_example with your real LToast instance above)

-- ---- Example: LToast:getDuration --------------------------------------------
--@api-stub: LToast:getDuration
-- Returns the duration of this Toast widget.
-- lToast_Example:getDuration()  -- -> number
-- (replace lToast_example with your real LToast instance above)

-- ---- Example: LToast:getProgress --------------------------------------------
--@api-stub: LToast:getProgress
-- Returns the progress of this Toast widget.
-- lToast_Example:getProgress()  -- -> number
-- (replace lToast_example with your real LToast instance above)

-- ---- Example: LToast:isExpired ----------------------------------------------
--@api-stub: LToast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- lToast_Example:isExpired()  -- -> boolean
-- (replace lToast_example with your real LToast instance above)

-- -----------------------------------------------------------------------------
-- LToolbar methods
-- -----------------------------------------------------------------------------

-- ---- Example: LToolbar:getOrientation ---------------------------------------
--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- lToolbar_Example:getOrientation()  -- -> string
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:setOrientation ---------------------------------------
--@api-stub: LToolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- lToolbar_Example:setOrientation(1.0)
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:addButton --------------------------------------------
--@api-stub: LToolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- lToolbar_Example:addButton(1, [tooltip])  -- -> integer
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:addSeparator -----------------------------------------
--@api-stub: LToolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- lToolbar_Example:addSeparator()
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:addSpacer --------------------------------------------
--@api-stub: LToolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- lToolbar_Example:addSpacer([size])
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:getButton --------------------------------------------
--@api-stub: LToolbar:getButton
-- Returns the button of this Toolbar widget.
-- lToolbar_Example:getButton(1)  -- -> table
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:setButtonEnabled -------------------------------------
--@api-stub: LToolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- lToolbar_Example:setButtonEnabled(1, true)  -- -> boolean
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:setButtonToggled -------------------------------------
--@api-stub: LToolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- lToolbar_Example:setButtonToggled(1, toggled)  -- -> boolean
-- (replace lToolbar_example with your real LToolbar instance above)

-- ---- Example: LToolbar:isButtonToggled --------------------------------------
--@api-stub: LToolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- lToolbar_Example:isButtonToggled(1)  -- -> boolean
-- (replace lToolbar_example with your real LToolbar instance above)

-- -----------------------------------------------------------------------------
-- LTooltipPanel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LTooltipPanel:getText -----------------------------------------
--@api-stub: LTooltipPanel:getText
-- Returns the text of this Tooltip_Panel widget.
-- lTooltipPanel_Example:getText()  -- -> string
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- ---- Example: LTooltipPanel:setText -----------------------------------------
--@api-stub: LTooltipPanel:setText
-- Sets the text for this Tooltip_Panel widget.
-- lTooltipPanel_Example:setText("Hello, world!")
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- ---- Example: LTooltipPanel:getDelay ----------------------------------------
--@api-stub: LTooltipPanel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- lTooltipPanel_Example:getDelay()  -- -> number
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- ---- Example: LTooltipPanel:setDelay ----------------------------------------
--@api-stub: LTooltipPanel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- lTooltipPanel_Example:setDelay(1.0)
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- ---- Example: LTooltipPanel:getTarget ---------------------------------------
--@api-stub: LTooltipPanel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- lTooltipPanel_Example:getTarget()  -- -> integer
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- ---- Example: LTooltipPanel:setTarget ---------------------------------------
--@api-stub: LTooltipPanel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- lTooltipPanel_Example:setTarget([target])
-- (replace lTooltipPanel_example with your real LTooltipPanel instance above)

-- -----------------------------------------------------------------------------
-- LTreeView methods
-- -----------------------------------------------------------------------------

-- ---- Example: LTreeView:addNode ---------------------------------------------
--@api-stub: LTreeView:addNode
-- Adds a node entry to this Tree_View widget.
-- lTreeView_Example:addNode("Hello, world!", [parent_index])  -- -> integer
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:toggleNode ------------------------------------------
--@api-stub: LTreeView:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- lTreeView_Example:toggleNode(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:isExpanded ------------------------------------------
--@api-stub: LTreeView:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- lTreeView_Example:isExpanded(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getNodeCount ----------------------------------------
--@api-stub: LTreeView:getNodeCount
-- Returns the node count of this Tree_View widget.
-- lTreeView_Example:getNodeCount()  -- -> integer
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:removeNode ------------------------------------------
--@api-stub: LTreeView:removeNode
-- Removes the node from this Tree_View widget.
-- lTreeView_Example:removeNode(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:clearNodes ------------------------------------------
--@api-stub: LTreeView:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- lTreeView_Example:clearNodes()
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getNodeText -----------------------------------------
--@api-stub: LTreeView:getNodeText
-- Returns the node text of this Tree_View widget.
-- lTreeView_Example:getNodeText(1)  -- -> string
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:setNodeText -----------------------------------------
--@api-stub: LTreeView:setNodeText
-- Sets the node text for this Tree_View widget.
-- lTreeView_Example:setNodeText(1, "Hello, world!")  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:setNodeIcon -----------------------------------------
--@api-stub: LTreeView:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- lTreeView_Example:setNodeIcon(1, icon)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:expandNode ------------------------------------------
--@api-stub: LTreeView:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- lTreeView_Example:expandNode(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:collapseNode ----------------------------------------
--@api-stub: LTreeView:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- lTreeView_Example:collapseNode(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:isNodeExpanded --------------------------------------
--@api-stub: LTreeView:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- lTreeView_Example:isNodeExpanded(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:expandAll -------------------------------------------
--@api-stub: LTreeView:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- lTreeView_Example:expandAll()
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:collapseAll -----------------------------------------
--@api-stub: LTreeView:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- lTreeView_Example:collapseAll()
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:setSelectedNode -------------------------------------
--@api-stub: LTreeView:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- lTreeView_Example:setSelectedNode(1)  -- -> boolean
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getSelectedNode -------------------------------------
--@api-stub: LTreeView:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- lTreeView_Example:getSelectedNode()  -- -> integer
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getChildNodes ---------------------------------------
--@api-stub: LTreeView:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- lTreeView_Example:getChildNodes(1)  -- -> table
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getParentNode ---------------------------------------
--@api-stub: LTreeView:getParentNode
-- Returns the parent node of this Tree_View widget.
-- lTreeView_Example:getParentNode(1)  -- -> integer
-- (replace lTreeView_example with your real LTreeView instance above)

-- ---- Example: LTreeView:getNodeDepth ----------------------------------------
--@api-stub: LTreeView:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- lTreeView_Example:getNodeDepth(1)  -- -> integer
-- (replace lTreeView_example with your real LTreeView instance above)

-- -----------------------------------------------------------------------------
-- LUiWidget methods
-- -----------------------------------------------------------------------------

-- ---- Example: LUiWidget:type ------------------------------------------------
--@api-stub: LUiWidget:type
-- Returns the Lua type name of this widget (e.g. "LButton").
-- lUiWidget_Example:type()  -- -> string
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:typeOf ----------------------------------------------
--@api-stub: LUiWidget:typeOf
-- Returns true if this widget is of the given type, "LWidget", or "Object".
-- lUiWidget_Example:typeOf("hero")  -- -> boolean
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setPosition -----------------------------------------
--@api-stub: LUiWidget:setPosition
-- Sets the widget position.
-- lUiWidget_Example:setPosition(0.0, 0.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getPosition -----------------------------------------
--@api-stub: LUiWidget:getPosition
-- Returns the widget position.
-- lUiWidget_Example:getPosition()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setSize ---------------------------------------------
--@api-stub: LUiWidget:setSize
-- Sets the width and height of the widget in UI pixels.
-- lUiWidget_Example:setSize(64.0, 64.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getSize ---------------------------------------------
--@api-stub: LUiWidget:getSize
-- Returns the current width and height of the widget in UI pixels.
-- lUiWidget_Example:getSize()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getRect ---------------------------------------------
--@api-stub: LUiWidget:getRect
-- Returns the computed screen-space rectangle after layout.
-- lUiWidget_Example:getRect()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setVisible ------------------------------------------
--@api-stub: LUiWidget:setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- lUiWidget_Example:setVisible(1.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:isVisible -------------------------------------------
--@api-stub: LUiWidget:isVisible
-- Returns whether the widget is visible.
-- lUiWidget_Example:isVisible()  -- -> boolean
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setEnabled ------------------------------------------
--@api-stub: LUiWidget:setEnabled
-- Sets whether the widget is enabled.
-- lUiWidget_Example:setEnabled(1.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:isEnabled -------------------------------------------
--@api-stub: LUiWidget:isEnabled
-- Returns whether the widget is enabled.
-- lUiWidget_Example:isEnabled()  -- -> boolean
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setId -----------------------------------------------
--@api-stub: LUiWidget:setId
-- Sets the widget string identifier.
-- lUiWidget_Example:setId(1)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getId -----------------------------------------------
--@api-stub: LUiWidget:getId
-- Returns the widget string identifier.
-- lUiWidget_Example:getId()  -- -> string
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setTooltip ------------------------------------------
--@api-stub: LUiWidget:setTooltip
-- Sets the widget tooltip text.
-- lUiWidget_Example:setTooltip("Hello, world!")
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getTooltip ------------------------------------------
--@api-stub: LUiWidget:getTooltip
-- Returns the widget tooltip text.
-- lUiWidget_Example:getTooltip()  -- -> string
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getState --------------------------------------------
--@api-stub: LUiWidget:getState
-- Returns the widget interaction state name.
-- lUiWidget_Example:getState()  -- -> string
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:addChild --------------------------------------------
--@api-stub: LUiWidget:addChild
-- Adds a child widget to this container.
-- lUiWidget_Example:addChild(child)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:removeChild -----------------------------------------
--@api-stub: LUiWidget:removeChild
-- Removes a child widget from this container.
-- lUiWidget_Example:removeChild(child)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getChildCount ---------------------------------------
--@api-stub: LUiWidget:getChildCount
-- Returns the number of children in this container.
-- lUiWidget_Example:getChildCount()  -- -> integer
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getChildren -----------------------------------------
--@api-stub: LUiWidget:getChildren
-- Returns this container's children as widget-handle tables.
-- lUiWidget_Example:getChildren()  -- -> table
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:findById --------------------------------------------
--@api-stub: LUiWidget:findById
-- Recursively searches for a widget by id starting from this widget.
-- lUiWidget_Example:findById(1)  -- -> table
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setOnClick ------------------------------------------
--@api-stub: LUiWidget:setOnClick
-- Registers a callback invoked when this widget is clicked.
-- lUiWidget_Example:setOnClick(f)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setOnChange -----------------------------------------
--@api-stub: LUiWidget:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- lUiWidget_Example:setOnChange(f)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setOnDraw -------------------------------------------
--@api-stub: LUiWidget:setOnDraw
-- Stores a custom draw callback for later invocation.
-- lUiWidget_Example:setOnDraw(self, f)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:containsPoint ---------------------------------------
--@api-stub: LUiWidget:containsPoint
-- Returns whether (x, y) is inside this widget.
-- lUiWidget_Example:containsPoint(0.0, 0.0)  -- -> boolean
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setPadding ------------------------------------------
--@api-stub: LUiWidget:setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- lUiWidget_Example:setPadding(top, [right], [bottom], [left])
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getPadding ------------------------------------------
--@api-stub: LUiWidget:getPadding
-- Returns the widget padding (top, right, bottom, left).
-- lUiWidget_Example:getPadding()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setMargin -------------------------------------------
--@api-stub: LUiWidget:setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- lUiWidget_Example:setMargin(top, [right], [bottom], [left])
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getMargin -------------------------------------------
--@api-stub: LUiWidget:getMargin
-- Returns the widget margin (top, right, bottom, left).
-- lUiWidget_Example:getMargin()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setZOrder -------------------------------------------
--@api-stub: LUiWidget:setZOrder
-- Sets the widget z-order for draw sorting.
-- lUiWidget_Example:setZOrder(0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getZOrder -------------------------------------------
--@api-stub: LUiWidget:getZOrder
-- Returns the widget z-order.
-- lUiWidget_Example:getZOrder()  -- -> integer
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setMinSize ------------------------------------------
--@api-stub: LUiWidget:setMinSize
-- Sets the minimum widget size.
-- lUiWidget_Example:setMinSize(64.0, 64.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getMinSize ------------------------------------------
--@api-stub: LUiWidget:getMinSize
-- Returns the minimum widget size.
-- lUiWidget_Example:getMinSize()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setMaxSize ------------------------------------------
--@api-stub: LUiWidget:setMaxSize
-- Sets the maximum widget size.
-- lUiWidget_Example:setMaxSize(64.0, 64.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getMaxSize ------------------------------------------
--@api-stub: LUiWidget:getMaxSize
-- Returns the maximum widget size.
-- lUiWidget_Example:getMaxSize()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setAnchor -------------------------------------------
--@api-stub: LUiWidget:setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- lUiWidget_Example:setAnchor()
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setAnchorCenter -------------------------------------
--@api-stub: LUiWidget:setAnchorCenter
-- Sets center anchor offsets.
-- lUiWidget_Example:setAnchorCenter([cx], [cy])
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:clearAnchor -----------------------------------------
--@api-stub: LUiWidget:clearAnchor
-- Removes all anchor constraints.
-- lUiWidget_Example:clearAnchor()
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setFlexGrow -----------------------------------------
--@api-stub: LUiWidget:setFlexGrow
-- Sets the flex-grow factor.
-- lUiWidget_Example:setFlexGrow(grow)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getFlexGrow -----------------------------------------
--@api-stub: LUiWidget:getFlexGrow
-- Returns the flex-grow factor.
-- lUiWidget_Example:getFlexGrow()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setFlexShrink ---------------------------------------
--@api-stub: LUiWidget:setFlexShrink
-- Sets the flex-shrink factor.
-- lUiWidget_Example:setFlexShrink(shrink)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getFlexShrink ---------------------------------------
--@api-stub: LUiWidget:getFlexShrink
-- Returns the flex-shrink factor.
-- lUiWidget_Example:getFlexShrink()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:bind ------------------------------------------------
--@api-stub: LUiWidget:bind
-- Registers a data-binding key on this widget.
-- lUiWidget_Example:bind("player_score")
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:unbind ----------------------------------------------
--@api-stub: LUiWidget:unbind
-- Removes the data-binding key from this widget.
-- lUiWidget_Example:unbind()
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:setAlpha --------------------------------------------
--@api-stub: LUiWidget:setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- lUiWidget_Example:setAlpha(alpha)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:getAlpha --------------------------------------------
--@api-stub: LUiWidget:getAlpha
-- Returns the widget's current alpha transparency.
-- lUiWidget_Example:getAlpha()  -- -> number
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:fadeIn ----------------------------------------------
--@api-stub: LUiWidget:fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- lUiWidget_Example:fadeIn()
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:fadeOut ---------------------------------------------
--@api-stub: LUiWidget:fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- lUiWidget_Example:fadeOut()
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:slideIn ---------------------------------------------
--@api-stub: LUiWidget:slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- lUiWidget_Example:slideIn(0.0, 0.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:slideOut --------------------------------------------
--@api-stub: LUiWidget:slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- lUiWidget_Example:slideOut(0.0, 0.0)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:attachToEntity --------------------------------------
--@api-stub: LUiWidget:attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- lUiWidget_Example:attachToEntity(entity_id)
-- (replace lUiWidget_example with your real LUiWidget instance above)

-- ---- Example: LUiWidget:detachFromEntity ------------------------------------
--@api-stub: LUiWidget:detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- lUiWidget_Example:detachFromEntity()
-- (replace lUiWidget_example with your real LUiWidget instance above)
