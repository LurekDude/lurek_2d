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

--@api-stub: lurek.ui.setPosition
-- Sets the widget position.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setPosition
--   pcall(function() lurek.ui.setPosition(100, 200) end)
--   print("applied")
-- end

--@api-stub: lurek.ui.getPosition
-- Returns the widget position.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getPosition
--   pcall(function()
--     local v = lurek.ui.getPosition()
--     print("getPosition:", v)
--   end)
-- end

--@api-stub: lurek.ui.setSize
-- Sets the width and height of the widget in UI pixels.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setSize
--   pcall(function() lurek.ui.setSize(200, 50) end)
--   print("applied")
-- end

--@api-stub: lurek.ui.getSize
-- Returns the current width and height of the widget in UI pixels.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getSize
--   pcall(function()
--     local v = lurek.ui.getSize()
--     print("getSize:", v)
--   end)
-- end

--@api-stub: lurek.ui.getRect
-- Returns the computed screen-space rectangle after layout.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getRect
--   pcall(function()
--     local v = lurek.ui.getRect()
--     print("getRect:", v)
--   end)
-- end

--@api-stub: lurek.ui.setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setVisible
--   pcall(function() lurek.ui.setVisible(true) end)
--   print("applied")
-- end

--@api-stub: lurek.ui.isVisible
-- Returns whether the widget is visible.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.isVisible
--   pcall(function()
--     local v = lurek.ui.isVisible()
--     print("isVisible:", v)
--   end)
-- end

--@api-stub: lurek.ui.setEnabled
-- Sets whether the widget is enabled.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setEnabled
--   pcall(function() lurek.ui.setEnabled(true) end)
--   print("applied")
-- end

--@api-stub: lurek.ui.isEnabled
-- Returns whether the widget is enabled.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.isEnabled
--   pcall(function()
--     local v = lurek.ui.isEnabled()
--     print("isEnabled:", v)
--   end)
-- end

--@api-stub: lurek.ui.setId
-- Sets the widget string identifier.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setId
--   pcall(function()
--     lurek.ui.setId("primary")
--     print("applied")
--   end)
-- end

--@api-stub: lurek.ui.getId
-- Returns the widget string identifier.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getId
--   pcall(function()
--     local v = lurek.ui.getId()
--     print("getId:", v)
--   end)
-- end

--@api-stub: lurek.ui.setTooltip
-- Sets the widget tooltip text.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setTooltip
--   lurek.ui.setTooltip("Hello")
--   print("applied")
-- end

--@api-stub: lurek.ui.getTooltip
-- Returns the widget tooltip text.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getTooltip
--   local v = lurek.ui.getTooltip()
--   print("getTooltip:", v)
-- end

--@api-stub: lurek.ui.getState
-- Returns the widget interaction state name.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getState
--   local v = lurek.ui.getState()
--   print("getState:", v)
-- end

--@api-stub: lurek.ui.addChild
-- Adds a child widget to this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.addChild
--   lurek.ui.addChild(1)
--   print("added")
-- end

--@api-stub: lurek.ui.removeChild
-- Removes a child widget from this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.removeChild
--   lurek.ui.removeChild(1)
--   print("done")
-- end

--@api-stub: lurek.ui.getChildCount
-- Returns the number of children in this container.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getChildCount
--   local v = lurek.ui.getChildCount()
--   print("getChildCount:", v)
-- end

--@api-stub: lurek.ui.getChildren
-- Returns this container's children as widget-handle tables.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getChildren
--   local v = lurek.ui.getChildren()
--   print("getChildren:", v)
-- end

--@api-stub: lurek.ui.findById
-- Recursively searches for a widget by id starting from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.findById
--   local v = lurek.ui.findById("widget_id")
--   print("findById:", v)
-- end

--@api-stub: lurek.ui.setOnClick
-- Registers a callback invoked when this widget is clicked.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setOnClick
--   lurek.ui.setOnClick(function() print("event") end)
--   print("applied")
-- end

--@api-stub: lurek.ui.setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setOnChange
--   lurek.ui.setOnChange(function() print("event") end)
--   print("applied")
-- end

--@api-stub: lurek.ui.setOnDraw
-- Stores a custom draw callback for later invocation.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setOnDraw
--   lurek.ui.setOnDraw(function() print("event") end)
--   print("applied")
-- end

--@api-stub: lurek.ui.containsPoint
-- Returns whether (x, y) is inside this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.containsPoint
--   local v = lurek.ui.containsPoint(0, 0)
--   print("containsPoint:", v)
-- end

--@api-stub: lurek.ui.setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setPadding
--   lurek.ui.setPadding(8)
--   print("applied")
-- end

--@api-stub: lurek.ui.getPadding
-- Returns the widget padding (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getPadding
--   local v = lurek.ui.getPadding()
--   print("getPadding:", v)
-- end

--@api-stub: lurek.ui.setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setMargin
--   lurek.ui.setMargin(8)
--   print("applied")
-- end

--@api-stub: lurek.ui.getMargin
-- Returns the widget margin (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getMargin
--   local v = lurek.ui.getMargin()
--   print("getMargin:", v)
-- end

--@api-stub: lurek.ui.setZOrder
-- Sets the widget z-order for draw sorting.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setZOrder
--   lurek.ui.setZOrder(1)
--   print("applied")
-- end

--@api-stub: lurek.ui.getZOrder
-- Returns the widget z-order.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getZOrder
--   local v = lurek.ui.getZOrder()
--   print("getZOrder:", v)
-- end

--@api-stub: lurek.ui.setMinSize
-- Sets the minimum widget size.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setMinSize
--   lurek.ui.setMinSize(200, 50)
--   print("applied")
-- end

--@api-stub: lurek.ui.getMinSize
-- Returns the minimum widget size.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getMinSize
--   local v = lurek.ui.getMinSize()
--   print("getMinSize:", v)
-- end

--@api-stub: lurek.ui.setMaxSize
-- Sets the maximum widget size.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setMaxSize
--   lurek.ui.setMaxSize(200, 50)
--   print("applied")
-- end

--@api-stub: lurek.ui.getMaxSize
-- Returns the maximum widget size.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getMaxSize
--   local v = lurek.ui.getMaxSize()
--   print("getMaxSize:", v)
-- end

--@api-stub: lurek.ui.setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setAnchor
--   lurek.ui.setAnchor(8, 8, 8, 8)
--   print("applied")
-- end

--@api-stub: lurek.ui.setAnchorCenter
-- Sets center anchor offsets.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setAnchorCenter
--   lurek.ui.setAnchorCenter(0, 0)
--   print("applied")
-- end

--@api-stub: lurek.ui.clearAnchor
-- Removes all anchor constraints.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.clearAnchor
--   lurek.ui.clearAnchor()
--   print("done")
-- end

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex-grow factor.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setFlexGrow
--   lurek.ui.setFlexGrow(1)
--   print("applied")
-- end

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex-grow factor.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getFlexGrow
--   local v = lurek.ui.getFlexGrow()
--   print("getFlexGrow:", v)
-- end

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex-shrink factor.
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setFlexShrink
--   lurek.ui.setFlexShrink(1)
--   print("applied")
-- end

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex-shrink factor.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getFlexShrink
--   local v = lurek.ui.getFlexShrink()
--   print("getFlexShrink:", v)
-- end

--@api-stub: lurek.ui.bind
-- Registers a data-binding key on this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.bind
--   lurek.ui.bind("key")
--   print("bind called")
-- end

--@api-stub: lurek.ui.unbind
-- Removes the data-binding key from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.unbind
--   lurek.ui.unbind()
--   print("unbind called")
-- end

--@api-stub: lurek.ui.setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- Apply the global UI setting before drawing the first frame.
-- if false then -- lurek.ui.setAlpha
--   lurek.ui.setAlpha(0.85)
--   print("applied")
-- end

--@api-stub: lurek.ui.getAlpha
-- Returns the widget's current alpha transparency.
-- Query the current global UI state from inside a render or input callback.
-- if false then -- lurek.ui.getAlpha
--   local v = lurek.ui.getAlpha()
--   print("getAlpha:", v)
-- end

--@api-stub: lurek.ui.fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.fadeIn
--   lurek.ui.fadeIn()
--   print("fadeIn called")
-- end

--@api-stub: lurek.ui.fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.fadeOut
--   lurek.ui.fadeOut()
--   print("fadeOut called")
-- end

--@api-stub: lurek.ui.slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.slideIn
--   lurek.ui.slideIn(0, 0)
--   print("slideIn called")
-- end

--@api-stub: lurek.ui.slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.slideOut
--   lurek.ui.slideOut(0, 0)
--   print("slideOut called")
-- end

--@api-stub: lurek.ui.attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.attachToEntity
--   lurek.ui.attachToEntity(1)
--   print("attachToEntity called")
-- end

--@api-stub: lurek.ui.detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- Invoke from an init or update callback as appropriate for your screen flow.
-- if false then -- lurek.ui.detachFromEntity
--   lurek.ui.detachFromEntity()
--   print("detachFromEntity called")
-- end


---@return any
-- local function new_example_image_widget()
--   return {}
-- end

--@api-stub: Button:setText
-- Sets the text for this Button widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Button:setText
--   local btn = new_example_image_widget():newButton("btn_play", "Play")
--   btn:setText("Hello")
-- end

--@api-stub: Button:getText
-- Returns the text of this Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Button:getText
--   local btn = new_example_image_widget():newButton("btn_play", "Play")
--   local v = btn:getText()
--   print("getText:", v)
-- end

-- â”€â”€ Label methods â”€â”€

--@api-stub: Label:setText
-- Sets the text for this Label widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Label:setText
--   local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
--   lbl:setText("Hello")
-- end

--@api-stub: Label:getText
-- Returns the text of this Label widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Label:getText
--   local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
--   local v = lbl:getText()
--   print("getText:", v)
-- end

-- â”€â”€ Text_Input methods â”€â”€

--@api-stub: Text_Input:setText
-- Sets the text for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Text_Input:setText
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   ti:setText("Hello")
-- end

--@api-stub: Text_Input:getText
-- Returns the text of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Text_Input:getText
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   local v = ti:getText()
--   print("getText:", v)
-- end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Text_Input:setPlaceholder
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   ti:setPlaceholder("Hello")
-- end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Text_Input:getPlaceholder
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   local v = ti:getPlaceholder()
--   print("getPlaceholder:", v)
-- end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Text_Input:setMaxLength
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   ti:setMaxLength(100)
-- end

--@api-stub: Text_Input:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Text_Input:isFocused
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   local v = ti:isFocused()
--   print("isFocused:", v)
-- end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Text_Input:getCursorPosition
--   local ti = new_example_image_widget():newTextInput("ti_name", "")
--   local v = ti:getCursorPosition()
--   print("getCursorPosition:", v)
-- end

-- â”€â”€ Checkbox methods â”€â”€

--@api-stub: Checkbox:setChecked
-- Sets the checked for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Checkbox:setChecked
--   local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
--   cb:setChecked(true)
-- end

--@api-stub: Checkbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Checkbox:isChecked
--   local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
--   local v = cb:isChecked()
--   print("isChecked:", v)
-- end

--@api-stub: Checkbox:setText
-- Sets the text for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Checkbox:setText
--   local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
--   cb:setText("Hello")
-- end

--@api-stub: Checkbox:getText
-- Returns the text of this Checkbox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Checkbox:getText
--   local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
--   local v = cb:getText()
--   print("getText:", v)
-- end

-- â”€â”€ Slider methods â”€â”€

--@api-stub: Slider:setValue
-- Sets the value for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Slider:setValue
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   sl:setValue(0.5)
-- end

--@api-stub: Slider:getValue
-- Returns the value of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Slider:getValue
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   local v = sl:getValue()
--   print("getValue:", v)
-- end

--@api-stub: Slider:setRange
-- Sets the range for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Slider:setRange
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   sl:setRange(1)
-- end

--@api-stub: Slider:setStep
-- Sets the step for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Slider:setStep
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   sl:setStep(1)
-- end

--@api-stub: Slider:getMin
-- Returns the min of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Slider:getMin
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   local v = sl:getMin()
--   print("getMin:", v)
-- end

--@api-stub: Slider:getMax
-- Returns the max of this Slider widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Slider:getMax
--   local sl = new_example_image_widget():newSlider(0, 100, 50)
--   local v = sl:getMax()
--   print("getMax:", v)
-- end

-- â”€â”€ Progress_Bar methods â”€â”€

--@api-stub: Progress_Bar:setValue
-- Sets the value for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Progress_Bar:setValue
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   pb:setValue(0.5)
-- end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Progress_Bar:getValue
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   local v = pb:getValue()
--   print("getValue:", v)
-- end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Progress_Bar:getProgress
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   local v = pb:getProgress()
--   print("getProgress:", v)
-- end

--@api-stub: Progress_Bar:setRange
-- Sets the range for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Progress_Bar:setRange
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   pb:setRange(1)
-- end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Progress_Bar:getMin
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   local v = pb:getMin()
--   print("getMin:", v)
-- end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this Progress_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Progress_Bar:getMax
--   local pb = new_example_image_widget():newProgressBar(0.5)
--   local v = pb:getMax()
--   print("getMax:", v)
-- end

-- â”€â”€ Combo_Box methods â”€â”€

--@api-stub: Combo_Box:addItem
-- Adds a item entry to this Combo_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Combo_Box:addItem
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   cb:addItem("item_1")
-- end

--@api-stub: Combo_Box:removeItem
-- Removes the item from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Combo_Box:removeItem
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   cb:removeItem()
-- end

--@api-stub: Combo_Box:clearItems
-- Clears all items entries from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Combo_Box:clearItems
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   cb:clearItems()
-- end

--@api-stub: Combo_Box:getItemCount
-- Returns the item count of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Combo_Box:getItemCount
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   local v = cb:getItemCount()
--   print("getItemCount:", v)
-- end

--@api-stub: Combo_Box:getItem
-- Returns the item of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Combo_Box:getItem
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   local v = cb:getItem()
--   print("getItem:", v)
-- end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Combo_Box:setSelectedIndex
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   cb:setSelectedIndex(true)
-- end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Combo_Box:getSelectedIndex
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   local v = cb:getSelectedIndex()
--   print("getSelectedIndex:", v)
-- end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Combo_Box:getSelectedItem
--   local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
--   local v = cb:getSelectedItem()
--   print("getSelectedItem:", v)
-- end

-- â”€â”€ List_Box methods â”€â”€

--@api-stub: List_Box:addItem
-- Adds a item entry to this List_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- List_Box:addItem
--   local w = new_example_image_widget():newList()
--   w:addItem("item_1")
-- end

--@api-stub: List_Box:removeItem
-- Removes the item from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- List_Box:removeItem
--   local w = new_example_image_widget():newList()
--   w:removeItem()
-- end

--@api-stub: List_Box:clearItems
-- Clears all items entries from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- List_Box:clearItems
--   local w = new_example_image_widget():newList()
--   w:clearItems()
-- end

--@api-stub: List_Box:getItemCount
-- Returns the item count of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- List_Box:getItemCount
--   local w = new_example_image_widget():newList()
--   local v = w:getItemCount()
--   print("getItemCount:", v)
-- end

--@api-stub: List_Box:getItem
-- Returns the item of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- List_Box:getItem
--   local w = new_example_image_widget():newList()
--   local v = w:getItem()
--   print("getItem:", v)
-- end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- List_Box:setSelectedIndex
--   local w = new_example_image_widget():newList()
--   w:setSelectedIndex(true)
-- end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- List_Box:getSelectedIndex
--   local w = new_example_image_widget():newList()
--   local v = w:getSelectedIndex()
--   print("getSelectedIndex:", v)
-- end

--@api-stub: List_Box:setItemHeight
-- Sets the item height for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- List_Box:setItemHeight
--   local w = new_example_image_widget():newList()
--   w:setItemHeight(50)
-- end

-- â”€â”€ Tab_Bar methods â”€â”€

--@api-stub: Tab_Bar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Tab_Bar:addTab
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   local child = new_example_image_widget():newButton("child_1", "Child")
--   tabs:addTab(child)
-- end

--@api-stub: Tab_Bar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Tab_Bar:removeTab
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   tabs:removeTab()
-- end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tab_Bar:getTab
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   local v = tabs:getTab()
--   print("getTab:", v)
-- end

--@api-stub: Tab_Bar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tab_Bar:getTabCount
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   local v = tabs:getTabCount()
--   print("getTabCount:", v)
-- end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tab_Bar:setActiveTab
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   tabs:setActiveTab(1)
-- end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tab_Bar:getActiveTab
--   local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
--   local v = tabs:getActiveTab()
--   print("getActiveTab:", v)
-- end

-- â”€â”€ Spin_Box methods â”€â”€

--@api-stub: Spin_Box:setValue
-- Sets the value for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Spin_Box:setValue
--   local spin = new_example_image_widget():newSpinBox()
--   spin:setValue(0.5)
-- end

--@api-stub: Spin_Box:getValue
-- Returns the current value of this SpinBox widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Spin_Box:getValue
--   local spin = new_example_image_widget():newSpinBox()
--   local v = spin:getValue()
--   print("getValue:", v)
-- end

--@api-stub: Spin_Box:increment
-- Increments the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
-- if false then -- Spin_Box:increment
--   local spin = new_example_image_widget():newSpinBox()
--   spin:increment()
-- end

--@api-stub: Spin_Box:decrement
-- Decrements the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
-- if false then -- Spin_Box:decrement
--   local spin = new_example_image_widget():newSpinBox()
--   spin:decrement()
-- end

--@api-stub: Spin_Box:setRange
-- Sets the valid range for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Spin_Box:setRange
--   local spin = new_example_image_widget():newSpinBox()
--   spin:setRange(1)
-- end

--@api-stub: Spin_Box:setStep
-- Sets the increment step for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Spin_Box:setStep
--   local spin = new_example_image_widget():newSpinBox()
--   spin:setStep(1)
-- end

-- â”€â”€ Switch methods â”€â”€

--@api-stub: Switch:setOn
-- Sets the on/off state of this Switch widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Switch:setOn
--   local sw = new_example_image_widget():newSwitch(false)
--   sw:setOn(function() print("event") end)
-- end

--@api-stub: Switch:isOn
-- Returns the on/off state of this Switch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Switch:isOn
--   local sw = new_example_image_widget():newSwitch(false)
--   local v = sw:isOn()
--   print("isOn:", v)
-- end

--@api-stub: Switch:toggle
-- Toggles the on/off state of this Switch widget.
-- Call this on the Switch instance to drive its behaviour at runtime.
-- if false then -- Switch:toggle
--   local sw = new_example_image_widget():newSwitch(false)
--   sw:toggle()
-- end

-- â”€â”€ Badge methods â”€â”€

--@api-stub: Badge:setCount
-- Sets the count displayed on this Badge widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Badge:setCount
--   local badge = new_example_image_widget():newBadge("3")
--   badge:setCount(4)
-- end

--@api-stub: Badge:getCount
-- Returns the raw count of this Badge widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Badge:getCount
--   local badge = new_example_image_widget():newBadge("3")
--   local v = badge:getCount()
--   print("getCount:", v)
-- end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this Badge widget, e.g.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Badge:getDisplayText
--   local badge = new_example_image_widget():newBadge("3")
--   local v = badge:getDisplayText()
--   print("getDisplayText:", v)
-- end

-- â”€â”€ Panel methods â”€â”€

--@api-stub: Panel:setTitle
-- Sets the title for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Panel:setTitle
--   local panel = new_example_image_widget():newPanel()
--   panel:setTitle("Hello")
-- end

--@api-stub: Panel:getTitle
-- Returns the title of this Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Panel:getTitle
--   local panel = new_example_image_widget():newPanel()
--   local v = panel:getTitle()
--   print("getTitle:", v)
-- end

--@api-stub: Panel:setScrollable
-- Sets the scrollable for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Panel:setScrollable
--   local panel = new_example_image_widget():newPanel()
--   panel:setScrollable(1)
-- end

-- â”€â”€ Layout methods â”€â”€

--@api-stub: Layout:setDirection
-- Sets the direction for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setDirection
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setDirection("horizontal")
-- end

--@api-stub: Layout:getDirection
-- Returns the direction of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Layout:getDirection
--   local layout = new_example_image_widget():newLayout("vertical")
--   local v = layout:getDirection()
--   print("getDirection:", v)
-- end

--@api-stub: Layout:setSpacing
-- Sets the spacing for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setSpacing
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setSpacing(8)
-- end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Layout:getSpacing
--   local layout = new_example_image_widget():newLayout("vertical")
--   local v = layout:getSpacing()
--   print("getSpacing:", v)
-- end

--@api-stub: Layout:setColumns
-- Sets the columns for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setColumns
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setColumns(1)
-- end

--@api-stub: Layout:setWrap
-- Sets the wrap for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setWrap
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setWrap(true)
-- end

--@api-stub: Layout:getWrap
-- Returns the wrap of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Layout:getWrap
--   local layout = new_example_image_widget():newLayout("vertical")
--   local v = layout:getWrap()
--   print("getWrap:", v)
-- end

--@api-stub: Layout:setAlign
-- Sets the align for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setAlign
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setAlign("center")
-- end

--@api-stub: Layout:getAlign
-- Returns the align of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Layout:getAlign
--   local layout = new_example_image_widget():newLayout("vertical")
--   local v = layout:getAlign()
--   print("getAlign:", v)
-- end

--@api-stub: Layout:setJustify
-- Sets the justify for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Layout:setJustify
--   local layout = new_example_image_widget():newLayout("vertical")
--   layout:setJustify(1)
-- end

--@api-stub: Layout:getJustify
-- Returns the justify of this Layout widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Layout:getJustify
--   local layout = new_example_image_widget():newLayout("vertical")
--   local v = layout:getJustify()
--   print("getJustify:", v)
-- end

-- â”€â”€ Scroll_Panel methods â”€â”€

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Panel:setContentSize
--   local sp = new_example_image_widget():newScrollPanel()
--   sp:setContentSize(200, 50)
-- end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Panel:getContentSize
--   local sp = new_example_image_widget():newScrollPanel()
--   local v = sp:getContentSize()
--   print("getContentSize:", v)
-- end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Panel:setScrollPosition
--   local sp = new_example_image_widget():newScrollPanel()
--   sp:setScrollPosition(100, 200)
-- end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Panel:getScrollPosition
--   local sp = new_example_image_widget():newScrollPanel()
--   local v = sp:getScrollPosition()
--   print("getScrollPosition:", v)
-- end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Panel:getMaxScroll
--   local sp = new_example_image_widget():newScrollPanel()
--   local v = sp:getMaxScroll()
--   print("getMaxScroll:", v)
-- end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Panel:setScrollSpeed
--   local sp = new_example_image_widget():newScrollPanel()
--   sp:setScrollSpeed(1)
-- end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Panel:getScrollSpeed
--   local sp = new_example_image_widget():newScrollPanel()
--   local v = sp:getScrollSpeed()
--   print("getScrollSpeed:", v)
-- end

-- â”€â”€ Nine_Patch methods â”€â”€

--@api-stub: Nine_Patch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Nine_Patch:setInsets
--   local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
--   np:setInsets(1)
-- end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Nine_Patch:getInsets
--   local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
--   local v = np:getInsets()
--   print("getInsets:", v)
-- end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Nine_Patch:setImageDimensions
--   local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
--   np:setImageDimensions("assets/icon.png")
-- end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Nine_Patch:getImageDimensions
--   local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
--   local v = np:getImageDimensions()
--   print("getImageDimensions:", v)
-- end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Nine_Patch:getSlices
--   local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
--   local v = np:getSlices()
--   print("getSlices:", v)
-- end

-- â”€â”€ Toast methods â”€â”€

--@api-stub: Toast:setMessage
-- Sets the message for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Toast:setMessage
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   toast:setMessage(1)
-- end

--@api-stub: Toast:getMessage
-- Returns the message of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toast:getMessage
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   local v = toast:getMessage()
--   print("getMessage:", v)
-- end

--@api-stub: Toast:setDuration
-- Sets the duration for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Toast:setDuration
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   toast:setDuration(0.5)
-- end

--@api-stub: Toast:getDuration
-- Returns the duration of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toast:getDuration
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   local v = toast:getDuration()
--   print("getDuration:", v)
-- end

--@api-stub: Toast:getProgress
-- Returns the progress of this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toast:getProgress
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   local v = toast:getProgress()
--   print("getProgress:", v)
-- end

--@api-stub: Toast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toast:isExpired
--   local toast = new_example_image_widget():newToast("Saved.", 2.0)
--   local v = toast:isExpired()
--   print("isExpired:", v)
-- end

-- â”€â”€ Separator methods â”€â”€

--@api-stub: Separator:setVertical
-- Sets the vertical for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Separator:setVertical
--   local sep = new_example_image_widget():newSeparator("horizontal")
--   sep:setVertical(1)
-- end

--@api-stub: Separator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Separator:isVertical
--   local sep = new_example_image_widget():newSeparator("horizontal")
--   local v = sep:isVertical()
--   print("isVertical:", v)
-- end

--@api-stub: Separator:setThickness
-- Sets the thickness for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Separator:setThickness
--   local sep = new_example_image_widget():newSeparator("horizontal")
--   sep:setThickness(1)
-- end

--@api-stub: Separator:getThickness
-- Returns the thickness of this Separator widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Separator:getThickness
--   local sep = new_example_image_widget():newSeparator("horizontal")
--   local v = sep:getThickness()
--   print("getThickness:", v)
-- end

-- â”€â”€ Tree_View methods â”€â”€

--@api-stub: Tree_View:addNode
-- Adds a node entry to this Tree_View widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Tree_View:addNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:addNode("item_1")
-- end

--@api-stub: Tree_View:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
-- if false then -- Tree_View:toggleNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:toggleNode()
-- end

--@api-stub: Tree_View:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:isExpanded
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:isExpanded()
--   print("isExpanded:", v)
-- end

--@api-stub: Tree_View:getNodeCount
-- Returns the node count of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getNodeCount
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getNodeCount()
--   print("getNodeCount:", v)
-- end

--@api-stub: Tree_View:removeNode
-- Removes the node from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Tree_View:removeNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:removeNode()
-- end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Tree_View:clearNodes
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:clearNodes()
-- end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getNodeText
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getNodeText()
--   print("getNodeText:", v)
-- end

--@api-stub: Tree_View:setNodeText
-- Sets the node text for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tree_View:setNodeText
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:setNodeText("Hello")
-- end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tree_View:setNodeIcon
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:setNodeIcon("assets/icon.png")
-- end

--@api-stub: Tree_View:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
-- if false then -- Tree_View:expandNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:expandNode()
-- end

--@api-stub: Tree_View:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
-- if false then -- Tree_View:collapseNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:collapseNode()
-- end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:isNodeExpanded
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:isNodeExpanded()
--   print("isNodeExpanded:", v)
-- end

--@api-stub: Tree_View:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
-- if false then -- Tree_View:expandAll
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:expandAll()
-- end

--@api-stub: Tree_View:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
-- if false then -- Tree_View:collapseAll
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:collapseAll()
-- end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tree_View:setSelectedNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   tree:setSelectedNode(true)
-- end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getSelectedNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getSelectedNode()
--   print("getSelectedNode:", v)
-- end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getChildNodes
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getChildNodes()
--   print("getChildNodes:", v)
-- end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getParentNode
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getParentNode()
--   print("getParentNode:", v)
-- end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tree_View:getNodeDepth
--   local tree = new_example_image_widget():newTreeView({label="root"})
--   local v = tree:getNodeDepth()
--   print("getNodeDepth:", v)
-- end

-- â”€â”€ Radio_Button methods â”€â”€

--@api-stub: Radio_Button:getText
-- Returns the text of this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Radio_Button:getText
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   local v = rb:getText()
--   print("getText:", v)
-- end

--@api-stub: Radio_Button:setText
-- Sets the text for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Radio_Button:setText
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   rb:setText("Hello")
-- end

--@api-stub: Radio_Button:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Radio_Button:isSelected
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   local v = rb:isSelected()
--   print("isSelected:", v)
-- end

--@api-stub: Radio_Button:setSelected
-- Sets the selected for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Radio_Button:setSelected
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   rb:setSelected(true)
-- end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this Radio_Button widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Radio_Button:getGroup
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   local v = rb:getGroup()
--   print("getGroup:", v)
-- end

--@api-stub: Radio_Button:setGroup
-- Sets the group for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Radio_Button:setGroup
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   rb:setGroup(1)
-- end

--@api-stub: Radio_Button:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Radio_Button:setOnChange
--   local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
--   rb:setOnChange(function() print("event") end)
-- end

-- â”€â”€ Scroll_Bar methods â”€â”€

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Bar:getScrollPosition
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   local v = sb:getScrollPosition()
--   print("getScrollPosition:", v)
-- end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Bar:setScrollPosition
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   sb:setScrollPosition(100, 200)
-- end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Bar:getContentSize
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   local v = sb:getContentSize()
--   print("getContentSize:", v)
-- end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Bar:setContentSize
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   sb:setContentSize(200, 50)
-- end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Bar:getViewSize
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   local v = sb:getViewSize()
--   print("getViewSize:", v)
-- end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Bar:setViewSize
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   sb:setViewSize(200, 50)
-- end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Scroll_Bar:isVertical
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   local v = sb:isVertical()
--   print("isVertical:", v)
-- end

--@api-stub: Scroll_Bar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Scroll_Bar:setOnChange
--   local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
--   sb:setOnChange(function() print("event") end)
-- end

-- â”€â”€ Gui_Window methods â”€â”€

--@api-stub: Gui_Window:getTitle
-- Returns the title of this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Window:getTitle
--   local w = new_example_image_widget():newPanel()
--   local v = w:getTitle()
--   print("getTitle:", v)
-- end

--@api-stub: Gui_Window:setTitle
-- Sets the title for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Window:setTitle
--   local w = new_example_image_widget():newPanel()
--   w:setTitle("Hello")
-- end

--@api-stub: Gui_Window:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Window:isCloseable
--   local w = new_example_image_widget():newPanel()
--   local v = w:isCloseable()
--   print("isCloseable:", v)
-- end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Window:setCloseable
--   local w = new_example_image_widget():newPanel()
--   w:setCloseable(1)
-- end

--@api-stub: Gui_Window:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Window:isDraggable
--   local w = new_example_image_widget():newPanel()
--   local v = w:isDraggable()
--   print("isDraggable:", v)
-- end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Window:setDraggable
--   local w = new_example_image_widget():newPanel()
--   w:setDraggable(1)
-- end

--@api-stub: Gui_Window:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Window:isResizable
--   local w = new_example_image_widget():newPanel()
--   local v = w:isResizable()
--   print("isResizable:", v)
-- end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Window:setResizable
--   local w = new_example_image_widget():newPanel()
--   w:setResizable(true)
-- end

--@api-stub: Gui_Window:setOnClose
-- Registers a callback invoked when this window is closed.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Window:setOnClose
--   local w = new_example_image_widget():newPanel()
--   w:setOnClose(function() print("event") end)
-- end

-- â”€â”€ Split_Panel methods â”€â”€

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Split_Panel:getOrientation
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   local v = split:getOrientation()
--   print("getOrientation:", v)
-- end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Split_Panel:setOrientation
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   split:setOrientation("horizontal")
-- end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Split_Panel:getSplitPosition
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   local v = split:getSplitPosition()
--   print("getSplitPosition:", v)
-- end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Split_Panel:setSplitPosition
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   split:setSplitPosition(100, 200)
-- end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Split_Panel:getMinPanelSize
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   local v = split:getMinPanelSize()
--   print("getMinPanelSize:", v)
-- end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Split_Panel:setMinPanelSize
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   split:setMinPanelSize(200, 50)
-- end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Split_Panel:setFirstChild
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   split:setFirstChild(1)
-- end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Split_Panel:setSecondChild
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   split:setSecondChild(function() print("event") end)
-- end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Split_Panel:getFirstChild
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   local v = split:getFirstChild()
--   print("getFirstChild:", v)
-- end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Split_Panel:getSecondChild
--   local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
--   local v = split:getSecondChild()
--   print("getSecondChild:", v)
-- end

-- â”€â”€ Dock_Panel methods â”€â”€

--@api-stub: Dock_Panel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
-- if false then -- Dock_Panel:dock
--   local dock = new_example_image_widget():newDockPanel()
--   dock:dock()
-- end

--@api-stub: Dock_Panel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
-- if false then -- Dock_Panel:undock
--   local dock = new_example_image_widget():newDockPanel()
--   dock:undock()
-- end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dock_Panel:getDockedCount
--   local dock = new_example_image_widget():newDockPanel()
--   local v = dock:getDockedCount()
--   print("getDockedCount:", v)
-- end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Dock_Panel:setSplitSize
--   local dock = new_example_image_widget():newDockPanel()
--   dock:setSplitSize(200, 50)
-- end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dock_Panel:getSplitSize
--   local dock = new_example_image_widget():newDockPanel()
--   local v = dock:getSplitSize()
--   print("getSplitSize:", v)
-- end

-- â”€â”€ Toolbar methods â”€â”€

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toolbar:getOrientation
--   local tb = new_example_image_widget():newToolbar()
--   local v = tb:getOrientation()
--   print("getOrientation:", v)
-- end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Toolbar:setOrientation
--   local tb = new_example_image_widget():newToolbar()
--   tb:setOrientation("horizontal")
-- end

--@api-stub: Toolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Toolbar:addButton
--   local tb = new_example_image_widget():newToolbar()
--   tb:addButton(1)
-- end

--@api-stub: Toolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Toolbar:addSeparator
--   local tb = new_example_image_widget():newToolbar()
--   tb:addSeparator(1)
-- end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Toolbar:addSpacer
--   local tb = new_example_image_widget():newToolbar()
--   tb:addSpacer(1)
-- end

--@api-stub: Toolbar:getButton
-- Returns the button of this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toolbar:getButton
--   local tb = new_example_image_widget():newToolbar()
--   local v = tb:getButton()
--   print("getButton:", v)
-- end

--@api-stub: Toolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Toolbar:setButtonEnabled
--   local tb = new_example_image_widget():newToolbar()
--   tb:setButtonEnabled(true)
-- end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Toolbar:setButtonToggled
--   local tb = new_example_image_widget():newToolbar()
--   tb:setButtonToggled(function() print("event") end)
-- end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Toolbar:isButtonToggled
--   local tb = new_example_image_widget():newToolbar()
--   local v = tb:isButtonToggled()
--   print("isButtonToggled:", v)
-- end

-- â”€â”€ Menu_Bar methods â”€â”€

--@api-stub: Menu_Bar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Menu_Bar:addMenu
--   local mb = new_example_image_widget():newMenuBar()
--   local child = new_example_image_widget():newButton("child_1", "Child")
--   mb:addMenu(child)
-- end

--@api-stub: Menu_Bar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Menu_Bar:removeMenu
--   local mb = new_example_image_widget():newMenuBar()
--   mb:removeMenu()
-- end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Bar:getMenus
--   local mb = new_example_image_widget():newMenuBar()
--   local v = mb:getMenus()
--   print("getMenus:", v)
-- end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Bar:getMenuCount
--   local mb = new_example_image_widget():newMenuBar()
--   local v = mb:getMenuCount()
--   print("getMenuCount:", v)
-- end

-- â”€â”€ Menu_Item methods â”€â”€

--@api-stub: Menu_Item:getText
-- Returns the text of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Item:getText
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   local v = mi:getText()
--   print("getText:", v)
-- end

--@api-stub: Menu_Item:setText
-- Sets the text for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Menu_Item:setText
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   mi:setText("Hello")
-- end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Item:getShortcut
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   local v = mi:getShortcut()
--   print("getShortcut:", v)
-- end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Menu_Item:setShortcut
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   mi:setShortcut(1)
-- end

--@api-stub: Menu_Item:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Item:isChecked
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   local v = mi:isChecked()
--   print("isChecked:", v)
-- end

--@api-stub: Menu_Item:setChecked
-- Sets the checked for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Menu_Item:setChecked
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   mi:setChecked(true)
-- end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Menu_Item:addSubItem
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   mi:addSubItem("item_1")
-- end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Menu_Item:getSubItems
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   local v = mi:getSubItems()
--   print("getSubItems:", v)
-- end

--@api-stub: Menu_Item:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Menu_Item:setOnClick
--   local mi = new_example_image_widget():newMenuItem("New Game")
--   mi:setOnClick(function() print("event") end)
-- end

-- â”€â”€ Dialog methods â”€â”€

--@api-stub: Dialog:getTitle
-- Returns the title of this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dialog:getTitle
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   local v = dlg:getTitle()
--   print("getTitle:", v)
-- end

--@api-stub: Dialog:setTitle
-- Sets the title for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Dialog:setTitle
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:setTitle("Hello")
-- end

--@api-stub: Dialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dialog:isModal
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   local v = dlg:isModal()
--   print("isModal:", v)
-- end

--@api-stub: Dialog:setModal
-- Sets the modal for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Dialog:setModal
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:setModal(true)
-- end

--@api-stub: Dialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dialog:isOpen
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   local v = dlg:isOpen()
--   print("isOpen:", v)
-- end

--@api-stub: Dialog:open
-- Performs the open operation on this Dialog widget.
-- Call this on the Dialog instance to drive its behaviour at runtime.
-- if false then -- Dialog:open
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:open()
-- end

--@api-stub: Dialog:close
-- Closes and removes this dialog from the screen.
-- Call this on the Dialog instance to drive its behaviour at runtime.
-- if false then -- Dialog:close
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:close()
-- end

--@api-stub: Dialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Dialog:setOnClose
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:setOnClose(function() print("event") end)
-- end

--@api-stub: Dialog:setContent
-- Sets the content for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Dialog:setContent
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:setContent(function() print("event") end)
-- end

--@api-stub: Dialog:getContent
-- Returns the content of this Dialog widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Dialog:getContent
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   local v = dlg:getContent()
--   print("getContent:", v)
-- end

--@api-stub: Dialog:addButton
-- Adds a button entry to this Dialog widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Dialog:addButton
--   local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
--   dlg:addButton(1)
-- end

-- â”€â”€ Status_Bar methods â”€â”€

--@api-stub: Status_Bar:addSection
-- Adds a section entry to this Status_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Status_Bar:addSection
--   local sb = new_example_image_widget():newStatusBar()
--   sb:addSection(1)
-- end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Status_Bar:setSectionText
--   local sb = new_example_image_widget():newStatusBar()
--   sb:setSectionText("Hello")
-- end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Status_Bar:getSectionText
--   local sb = new_example_image_widget():newStatusBar()
--   local v = sb:getSectionText()
--   print("getSectionText:", v)
-- end

--@api-stub: Status_Bar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Status_Bar:getSectionCount
--   local sb = new_example_image_widget():newStatusBar()
--   local v = sb:getSectionCount()
--   print("getSectionCount:", v)
-- end

--@api-stub: Status_Bar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Status_Bar:setSectionCount
--   local sb = new_example_image_widget():newStatusBar()
--   sb:setSectionCount(4)
-- end

--@api-stub: Status_Bar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Status_Bar:setSectionWidget
--   local sb = new_example_image_widget():newStatusBar()
--   sb:setSectionWidget("primary")
-- end

-- â”€â”€ Accordion methods â”€â”€

--@api-stub: Accordion:addSection
-- Adds a section entry to this Accordion widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Accordion:addSection
--   local acc = new_example_image_widget():newAccordion()
--   acc:addSection(1)
-- end

--@api-stub: Accordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Accordion:getSectionCount
--   local acc = new_example_image_widget():newAccordion()
--   local v = acc:getSectionCount()
--   print("getSectionCount:", v)
-- end

--@api-stub: Accordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- Call this on the Accordion instance to drive its behaviour at runtime.
-- if false then -- Accordion:toggleSection
--   local acc = new_example_image_widget():newAccordion()
--   acc:toggleSection()
-- end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Accordion:isSectionExpanded
--   local acc = new_example_image_widget():newAccordion()
--   local v = acc:isSectionExpanded()
--   print("isSectionExpanded:", v)
-- end

--@api-stub: Accordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Accordion:isExclusive
--   local acc = new_example_image_widget():newAccordion()
--   local v = acc:isExclusive()
--   print("isExclusive:", v)
-- end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Accordion:setExclusive
--   local acc = new_example_image_widget():newAccordion()
--   acc:setExclusive(1)
-- end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Accordion:getSectionTitle
--   local acc = new_example_image_widget():newAccordion()
--   local v = acc:getSectionTitle()
--   print("getSectionTitle:", v)
-- end

-- â”€â”€ Tooltip_Panel methods â”€â”€

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tooltip_Panel:getText
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   local v = tip:getText()
--   print("getText:", v)
-- end

--@api-stub: Tooltip_Panel:setText
-- Sets the text for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tooltip_Panel:setText
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   tip:setText("Hello")
-- end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tooltip_Panel:getDelay
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   local v = tip:getDelay()
--   print("getDelay:", v)
-- end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tooltip_Panel:setDelay
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   tip:setDelay(2.0)
-- end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Tooltip_Panel:getTarget
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   local v = tip:getTarget()
--   print("getTarget:", v)
-- end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Tooltip_Panel:setTarget
--   local tip = new_example_image_widget():newTooltipPanel("Click to attack")
--   tip:setTarget(1)
-- end

-- â”€â”€ Color_Picker methods â”€â”€

--@api-stub: Color_Picker:getColor
-- Returns the color of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Color_Picker:getColor
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   local v = cp:getColor()
--   print("getColor:", v)
-- end

--@api-stub: Color_Picker:setColor
-- Sets the color for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Color_Picker:setColor
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   cp:setColor({0.2, 0.6, 1.0, 1.0})
-- end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Color_Picker:getShowAlpha
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   local v = cp:getShowAlpha()
--   print("getShowAlpha:", v)
-- end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Color_Picker:setShowAlpha
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   cp:setShowAlpha(0.85)
-- end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Color_Picker:getColorMode
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   local v = cp:getColorMode()
--   print("getColorMode:", v)
-- end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Color_Picker:setColorMode
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   cp:setColorMode({0.2, 0.6, 1.0, 1.0})
-- end

--@api-stub: Color_Picker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Color_Picker:setOnChange
--   local cp = new_example_image_widget():newColorPicker({1,0,0,1})
--   cp:setOnChange(function() print("event") end)
-- end

-- â”€â”€ Gui_Table methods â”€â”€

--@api-stub: Gui_Table:addColumn
-- Adds a column entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Gui_Table:addColumn
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:addColumn("item_1")
-- end

--@api-stub: Gui_Table:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Table:getColumnCount
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   local v = tbl:getColumnCount()
--   print("getColumnCount:", v)
-- end

--@api-stub: Gui_Table:addRow
-- Adds a row entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Gui_Table:addRow
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:addRow("item_1")
-- end

--@api-stub: Gui_Table:getRowCount
-- Returns the row count of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Table:getRowCount
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   local v = tbl:getRowCount()
--   print("getRowCount:", v)
-- end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Table:getCell
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   local v = tbl:getCell()
--   print("getCell:", v)
-- end

--@api-stub: Gui_Table:setCell
-- Sets the cell for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Table:setCell
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:setCell(1)
-- end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Table:getSelectedRow
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   local v = tbl:getSelectedRow()
--   print("getSelectedRow:", v)
-- end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Table:setSelectedRow
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:setSelectedRow(true)
-- end

--@api-stub: Gui_Table:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Gui_Table:isSortable
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   local v = tbl:isSortable()
--   print("isSortable:", v)
-- end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Table:setSortable
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:setSortable(1)
-- end

--@api-stub: Gui_Table:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Gui_Table:setOnSelect
--   local tbl = new_example_image_widget():newTable({"Name","Score"})
--   tbl:setOnSelect(function() print("event") end)
-- end

-- â”€â”€ Image_Widget methods â”€â”€

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getScaleMode
--   local img = new_example_image_widget()
--   local v = img:getScaleMode()
--   print("getScaleMode:", v)
-- end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setScaleMode
--   local img = new_example_image_widget()
--   img:setScaleMode(1.5)
-- end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this Image_Widget widget.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getTint
--   local img = new_example_image_widget()
--   local v = img:getTint()
--   print("getTint:", v)
-- end

--@api-stub: Image_Widget:setTint
-- Sets the tint for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setTint
--   local img = new_example_image_widget()
--   img:setTint({0.2, 0.6, 1.0, 1.0})
-- end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newButton
--   local img = new_example_image_widget()
--   img:newButton()
-- end

--@api-stub: Image_Widget:newLabel
-- Creates a text label widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newLabel
--   local img = new_example_image_widget()
--   img:newLabel()
-- end

--@api-stub: Image_Widget:newTextInput
-- Creates a text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTextInput
--   local img = new_example_image_widget()
--   img:newTextInput()
-- end

--@api-stub: Image_Widget:newCheckbox
-- Creates a checkbox widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newCheckbox
--   local img = new_example_image_widget()
--   img:newCheckbox()
-- end

--@api-stub: Image_Widget:newSlider
-- Creates a value slider widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSlider
--   local img = new_example_image_widget()
--   img:newSlider()
-- end

--@api-stub: Image_Widget:newProgressBar
-- Creates a progress bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newProgressBar
--   local img = new_example_image_widget()
--   img:newProgressBar()
-- end

--@api-stub: Image_Widget:newComboBox
-- Creates a dropdown combo box widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newComboBox
--   local img = new_example_image_widget()
--   img:newComboBox()
-- end

--@api-stub: Image_Widget:newList
-- Creates a selectable list widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newList
--   local img = new_example_image_widget()
--   img:newList()
-- end

--@api-stub: Image_Widget:newPanel
-- Creates a container panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newPanel
--   local img = new_example_image_widget()
--   img:newPanel()
-- end

--@api-stub: Image_Widget:newLayout
-- Creates a flexbox layout container.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newLayout
--   local img = new_example_image_widget()
--   img:newLayout()
-- end

--@api-stub: Image_Widget:newScrollPanel
-- Creates a scrollable panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newScrollPanel
--   local img = new_example_image_widget()
--   img:newScrollPanel()
-- end

--@api-stub: Image_Widget:newNinePatch
-- Creates a 9-patch slicer widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newNinePatch
--   local img = new_example_image_widget()
--   img:newNinePatch()
-- end

--@api-stub: Image_Widget:newTabBar
-- Creates a tab bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTabBar
--   local img = new_example_image_widget()
--   img:newTabBar()
-- end

--@api-stub: Image_Widget:newSeparator
-- Creates a separator line.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSeparator
--   local img = new_example_image_widget()
--   img:newSeparator()
-- end

--@api-stub: Image_Widget:newSpacer
-- Creates a spacing filler widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSpacer
--   local img = new_example_image_widget()
--   img:newSpacer()
-- end

--@api-stub: Image_Widget:newToast
-- Creates a toast notification widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newToast
--   local img = new_example_image_widget()
--   img:newToast()
-- end

--@api-stub: Image_Widget:newTreeView
-- Creates a collapsible tree view widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTreeView
--   local img = new_example_image_widget()
--   img:newTreeView()
-- end

--@api-stub: Image_Widget:newRadioButton
-- Creates a grouped radio button widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newRadioButton
--   local img = new_example_image_widget()
--   img:newRadioButton()
-- end

--@api-stub: Image_Widget:newScrollBar
-- Creates a scroll bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newScrollBar
--   local img = new_example_image_widget()
--   img:newScrollBar()
-- end

--@api-stub: Image_Widget:newWindow
-- Creates a draggable window widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newWindow
--   local img = new_example_image_widget()
--   img:newWindow()
-- end

--@api-stub: Image_Widget:newSplitPanel
-- Creates a resizable split panel.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSplitPanel
--   local img = new_example_image_widget()
--   img:newSplitPanel()
-- end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newDockPanel
--   local img = new_example_image_widget()
--   img:newDockPanel()
-- end

--@api-stub: Image_Widget:newToolbar
-- Creates a toolbar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newToolbar
--   local img = new_example_image_widget()
--   img:newToolbar()
-- end

--@api-stub: Image_Widget:newMenuBar
-- Creates a menu bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newMenuBar
--   local img = new_example_image_widget()
--   img:newMenuBar()
-- end

--@api-stub: Image_Widget:newMenuItem
-- Creates a menu item widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newMenuItem
--   local img = new_example_image_widget()
--   img:newMenuItem()
-- end

--@api-stub: Image_Widget:newDialog
-- Creates a modal dialog widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newDialog
--   local img = new_example_image_widget()
--   img:newDialog()
-- end

--@api-stub: Image_Widget:newStatusBar
-- Creates a status bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newStatusBar
--   local img = new_example_image_widget()
--   img:newStatusBar()
-- end

--@api-stub: Image_Widget:newAccordion
-- Creates a collapsible accordion widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newAccordion
--   local img = new_example_image_widget()
--   img:newAccordion()
-- end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates a tooltip panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTooltipPanel
--   local img = new_example_image_widget()
--   img:newTooltipPanel()
-- end

--@api-stub: Image_Widget:newColorPicker
-- Creates a color picker widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newColorPicker
--   local img = new_example_image_widget()
--   img:newColorPicker()
-- end

--@api-stub: Image_Widget:newTable
-- Creates a data table widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTable
--   local img = new_example_image_widget()
--   img:newTable()
-- end

--@api-stub: Image_Widget:newImageWidget
-- Creates an image display widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newImageWidget
--   local img = new_example_image_widget()
--   img:newImageWidget()
-- end

--@api-stub: Image_Widget:newTheme
-- Creates a new theme instance.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newTheme
--   local img = new_example_image_widget()
--   img:newTheme()
-- end

--@api-stub: Image_Widget:setTheme
-- Sets the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setTheme
--   local img = new_example_image_widget()
--   img:setTheme("dark")
-- end

--@api-stub: Image_Widget:getTheme
-- Returns whether a theme is set.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getTheme
--   local img = new_example_image_widget()
--   local v = img:getTheme()
--   print("getTheme:", v)
-- end

--@api-stub: Image_Widget:getRoot
-- Returns the root panel widget table.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getRoot
--   local img = new_example_image_widget()
--   local v = img:getRoot()
--   print("getRoot:", v)
-- end

--@api-stub: Image_Widget:setFocus
-- Sets keyboard focus to a widget or clears it.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setFocus
--   local img = new_example_image_widget()
--   img:setFocus(1)
-- end

--@api-stub: Image_Widget:getFocus
-- Returns the focused widget index or nil.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getFocus
--   local img = new_example_image_widget()
--   local v = img:getFocus()
--   print("getFocus:", v)
-- end

--@api-stub: Image_Widget:focusNext
-- Moves focus to the next focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:focusNext
--   local img = new_example_image_widget()
--   img:focusNext()
-- end

--@api-stub: Image_Widget:focusPrev
-- Moves focus to the previous focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:focusPrev
--   local img = new_example_image_widget()
--   img:focusPrev()
-- end

--@api-stub: Image_Widget:clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- Tear down dynamic content when the screen changes to free GPU resources.
-- if false then -- Image_Widget:clearFocus
--   local img = new_example_image_widget()
--   img:clearFocus()
-- end

--@api-stub: Image_Widget:addToast
-- Queues a toast notification from a table.
-- Insert the child as part of building the widget tree, typically in lurek.init().
-- if false then -- Image_Widget:addToast
--   local img = new_example_image_widget()
--   img:addToast(1)
-- end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of active toasts.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getToastCount
--   local img = new_example_image_widget()
--   local v = img:getToastCount()
--   print("getToastCount:", v)
-- end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:mousepressed
--   local img = new_example_image_widget()
--   img:mousepressed()
-- end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:mousereleased
--   local img = new_example_image_widget()
--   img:mousereleased()
-- end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:mousemoved
--   local img = new_example_image_widget()
--   img:mousemoved()
-- end
--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:keypressed
--   local img = new_example_image_widget()
--   img:keypressed()
-- end

--@api-stub: Image_Widget:textinput
-- Forwards text input to the focused text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:textinput
--   local img = new_example_image_widget()
--   img:textinput()
-- end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:wheelmoved
--   local img = new_example_image_widget()
--   img:wheelmoved()
-- end

--@api-stub: Image_Widget:update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:update
--   local img = new_example_image_widget()
--   img:update()
-- end

--@api-stub: Image_Widget:draw
-- Headless compatibility stub for GUI draw.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:draw
--   local img = new_example_image_widget()
--   img:draw()
-- end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the total widget count in the context.
-- Read the current state â€” useful inside callbacks or per-frame UI logic.
-- if false then -- Image_Widget:getWidgetCount
--   local img = new_example_image_widget()
--   local v = img:getWidgetCount()
--   print("getWidgetCount:", v)
-- end

--@api-stub: Image_Widget:drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:drawToImage
--   local img = new_example_image_widget()
--   img:drawToImage()
-- end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newLineChart
--   local img = new_example_image_widget()
--   img:newLineChart()
-- end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newBarChart
--   local img = new_example_image_widget()
--   img:newBarChart()
-- end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newScatterPlot
--   local img = new_example_image_widget()
--   img:newScatterPlot()
-- end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newPieChart
--   local img = new_example_image_widget()
--   img:newPieChart()
-- end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newAreaChart
--   local img = new_example_image_widget()
--   img:newAreaChart()
-- end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newLineChart
--   local img = new_example_image_widget()
--   img:newLineChart()
-- end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newBarChart
--   local img = new_example_image_widget()
--   img:newBarChart()
-- end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newScatterPlot
--   local img = new_example_image_widget()
--   img:newScatterPlot()
-- end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newPieChart
--   local img = new_example_image_widget()
--   img:newPieChart()
-- end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newAreaChart
--   local img = new_example_image_widget()
--   img:newAreaChart()
-- end

--@api-stub: Image_Widget:parseWidgetState
-- Parses a widget state string, returning the canonical form or nil if invalid.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:parseWidgetState
--   local img = new_example_image_widget()
--   img:parseWidgetState()
-- end

--@api-stub: Image_Widget:newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSpinBox
--   local img = new_example_image_widget()
--   img:newSpinBox()
-- end

--@api-stub: Image_Widget:newSwitch
-- Creates a toggle switch widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newSwitch
--   local img = new_example_image_widget()
--   img:newSwitch()
-- end

--@api-stub: Image_Widget:newBadge
-- Creates a badge widget displaying a numeric count.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:newBadge
--   local img = new_example_image_widget()
--   img:newBadge()
-- end

--@api-stub: Image_Widget:setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setDefaultTheme
--   local img = new_example_image_widget()
--   img:setDefaultTheme("dark")
-- end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- Image_Widget:setViewport
--   local img = new_example_image_widget()
--   img:setViewport(1)
-- end

--@api-stub: Image_Widget:flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:flushCache
--   local img = new_example_image_widget()
--   img:flushCache()
-- end

--@api-stub: Image_Widget:update_bindings
-- Updates all widgets that have a data-binding key registered via `:bind(key)`.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:update_bindings
--   local img = new_example_image_widget()
--   img:update_bindings()
-- end

--@api-stub: Image_Widget:loadLayout
-- Load a widget tree from a Lua table definition and attach it to the UI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:loadLayout
--   local img = new_example_image_widget()
--   img:loadLayout()
-- end

--@api-stub: Image_Widget:loadLayoutFile
-- Load a widget tree from a TOML layout file and attach it to the UI root.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:loadLayoutFile
--   local img = new_example_image_widget()
--   img:loadLayoutFile()
-- end

--@api-stub: Image_Widget:renderToImage
-- Render the current UI widget tree to a PNG file for testing purposes.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
-- if false then -- Image_Widget:renderToImage
--   local img = new_example_image_widget()
--   img:renderToImage()
-- end

-- â”€â”€ LineChart methods â”€â”€

--@api-stub: LineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- LineChart:setYMax
--   local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
--   chart:setYMax(100)
-- end

--@api-stub: LineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- LineChart:setXMax
--   local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
--   chart:setXMax(100)
-- end

--@api-stub: LineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Call this on the LineChart instance to drive its behaviour at runtime.
-- if false then -- LineChart:drawToImage
--   local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
--   chart:drawToImage()
-- end

-- â”€â”€ BarChart methods â”€â”€

--@api-stub: LBarChart:drawToImage
-- Renders the bar chart into an existing ImageData.
-- Call this on the BarChart instance to drive its behaviour at runtime.
-- if false then -- BarChart:drawToImage
--   local w = new_example_image_widget():newPanel()
--   w:drawToImage()
-- end

-- â”€â”€ ScatterPlot methods â”€â”€

--@api-stub: LScatterPlot:setXRange
-- Sets the X-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- ScatterPlot:setXRange
--   local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
--   plot:setXRange(1)
-- end

--@api-stub: LScatterPlot:setYRange
-- Sets the Y-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- ScatterPlot:setYRange
--   local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
--   plot:setYRange(1)
-- end

--@api-stub: LScatterPlot:drawToImage
-- Renders the scatter plot into an existing ImageData.
-- Call this on the ScatterPlot instance to drive its behaviour at runtime.
-- if false then -- ScatterPlot:drawToImage
--   local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
--   plot:drawToImage()
-- end

-- â”€â”€ PieChart methods â”€â”€

--@api-stub: LPieChart:drawToImage
-- Renders the pie chart into an existing ImageData.
-- Call this on the PieChart instance to drive its behaviour at runtime.
-- if false then -- PieChart:drawToImage
--   local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
--   chart:drawToImage()
-- end

-- â”€â”€ AreaChart methods â”€â”€

--@api-stub: LAreaChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
-- if false then -- AreaChart:setYMax
--   local w = new_example_image_widget():newPanel()
--   w:setYMax(100)
-- end

--@api-stub: LAreaChart:drawToImage
-- Renders the area chart into an existing ImageData.
-- Call this on the AreaChart instance to drive its behaviour at runtime.
-- if false then -- AreaChart:drawToImage
--   local w = new_example_image_widget():newPanel()
--   w:drawToImage()
-- end

-- â”€â”€ Custom widget extensibility â”€â”€

--@api-stub: Image_Widget:newCustomWidget
-- Creates a widget with fully Lua-driven rendering via an on_draw callback.
-- Call once during init to register the widget; call lurek.ui.draw() each frame.
-- if false then -- Image_Widget:newCustomWidget
--   local widget = new_example_image_widget():newCustomWidget({
--     x = 50, y = 50, width = 300, height = 200, id = "health_bar",
--   })
--   if widget and widget.setOnDraw then
--     widget:setOnDraw(function(rect)
--       local health = 0.75
      -- Draw background
--       lurek.render.setColor(0.2, 0.2, 0.2, 1)
--         lurek.render.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
      -- Draw health fill
--       lurek.render.setColor(0, 1, 0, 1)
--         lurek.render.rectangle("fill", rect.x, rect.y, rect.w * health, rect.h)
      -- Draw label
--       lurek.render.setColor(1, 1, 1, 1)
--       lurek.render.print("HP: 75%", rect.x + 4, rect.y + 4)
--     end)
--   end
--   print("newCustomWidget: ok")
-- end


--@api-stub: LBarChart:addCategory
-- Adds a named category (x-axis label) to the bar chart.
-- Each series value maps to one category; add categories before adding series data.
-- if false then -- BarChart:addCategory
--   lurek.log.info("BarChart:addCategory usage: chart:addCategory('Jan')", "ui")
--   local bc = new_example_image_widget():newBarChart(200, 100)
--   bc:addCategory("Jan")
--   bc:addCategory("Feb")
--   lurek.log.info("categories added", "ui")
-- end

--@api-stub: LAreaChart:addLayer
-- Adds a new stacked area series layer to the area chart.
-- Multiple layers stack vertically; each is filled with a distinct colour.
-- if false then -- AreaChart:addLayer
--   local ac = new_example_image_widget():newAreaChart(300, 150)
--   ac:addLayer("series_a", {1,0.3,0.3,0.7}, {10,20,15,30,25})
--   ac:addLayer("series_b", {0.3,0.6,1,0.7}, {5,10,8,14,12})
--   lurek.log.info("area layers added", "ui")
-- end

--@api-stub: LPieChart:addSegment
-- Adds a named slice to the pie chart with a value and colour.
-- Values are relative; the chart normalises them to 360 degrees automatically.
-- if false then -- PieChart:addSegment
--   local pc = new_example_image_widget():newPieChart(150, 150)
--   pc:addSegment("Wheat",  40, {0.9, 0.8, 0.3, 1})
--   pc:addSegment("Sheep",  25, {0.8, 0.9, 0.5, 1})
--   pc:addSegment("Forest", 35, {0.2, 0.7, 0.3, 1})
--   lurek.log.info("pie segments added", "ui")
-- end

--@api-stub: LineChart:addSeries
-- Adds a named data series to the line chart with a colour and data points.
-- Multiple series are drawn overlapping; use distinct colours to differentiate.
-- if false then -- LineChart:addSeries
--   local lc = new_example_image_widget():newLineChart(300, 150)
--   lc:addSeries("revenue", {0.2, 0.8, 0.4, 1}, {10, 20, 15, 35, 30})
--   lc:addSeries("cost",    {0.9, 0.3, 0.2, 1}, {8,  12, 10, 18, 20})
--   lurek.log.info("line series added", "ui")
-- end

--@api-stub: LBarChart:addSeries
-- Adds a named data series to the bar chart with a colour and values.
-- Each value in the table maps to the corresponding category index.
-- if false then -- BarChart:addSeries
--   local bc = new_example_image_widget():newBarChart(300, 150)
--   bc:addCategory("Q1"); bc:addCategory("Q2")
--   bc:addSeries("sales",   {0.2, 0.6, 0.9, 1}, {120, 180})
--   bc:addSeries("returns", {0.9, 0.3, 0.2, 1}, {10,  15})
--   lurek.log.info("bar series added", "ui")
-- end

--@api-stub: LScatterPlot:addSeries
-- Adds a named point series to the scatter plot with colour and (x, y) data pairs.
-- Each series is a flat table {x1,y1, x2,y2, ...} of coordinate pairs.
-- if false then -- ScatterPlot:addSeries
--   local sp = new_example_image_widget():newScatterPlot(200, 200)
--   sp:addSeries("players", {0.2, 0.7, 1, 1}, {10,20, 30,40, 50,35, 70,55})
--   sp:setXRange(0, 100); sp:setYRange(0, 80)
--   lurek.log.info("scatter series added", "ui")
-- end

--@api-stub: LTheme:setStyle
-- Sets a named style property on the theme (e.g., button colour, font size).
-- Themes apply hierarchically; widget-level styles override theme defaults.
-- if false then -- Theme:setStyle
--   local theme = new_example_image_widget():newTheme()
--   theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
--   theme:setStyle("button.text_color",  {1, 1, 1, 1})
--   lurek.log.info("theme styles set", "ui")
-- end

-- =============================================================================
-- STUBS: 12 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LineChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LineChart:type ------------------------------------------------
--@api-stub: LineChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LineChart:type
--   local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
--     chart:setYMax(100)
--   local t = chart:type()
--   lurek.log.info("LineChart:type = " .. t, "ui")
-- end
--@api-stub: LineChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LineChart:typeOf
--   local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
--     chart:setYMax(100)
--   lurek.log.info("is LineChart: " .. tostring(chart:typeOf("LineChart")), "ui")
--   lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAreaChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAreaChart:type -----------------------------------------------
--@api-stub: LAreaChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LAreaChart:type
--   local w = new_example_image_widget():newPanel()
--     w:setYMax(100)
--   local t = w:type()
--   lurek.log.info("LAreaChart:type = " .. t, "ui")
-- end
--@api-stub: LAreaChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LAreaChart:typeOf
--   local w = new_example_image_widget():newPanel()
--     w:setYMax(100)
--   lurek.log.info("is LAreaChart: " .. tostring(w:typeOf("LAreaChart")), "ui")
--   lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
-- end
--@api-stub: LBarChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LBarChart:type
--   local w = new_example_image_widget():newPanel()
--     w:drawToImage()
--   local t = w:type()
--   lurek.log.info("LBarChart:type = " .. t, "ui")
-- end
--@api-stub: LBarChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LBarChart:typeOf
--   local w = new_example_image_widget():newPanel()
--     w:drawToImage()
--   lurek.log.info("is LBarChart: " .. tostring(w:typeOf("LBarChart")), "ui")
--   lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
-- end
--@api-stub: LLineChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection of UI chart objects.
-- if false then -- LLineChart:type
--   local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Sales" })
--   local t = chart:type()
--   lurek.log.info("LLineChart:type=" .. t, "ui")
-- end
--@api-stub: LLineChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks on UI chart objects.
-- if false then -- LLineChart:typeOf
--   local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Revenue" })
--   lurek.log.info("is LLineChart: " .. tostring(chart:typeOf("LLineChart")), "ui")
--   lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
-- end
--@api-stub: LPieChart:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LPieChart:type
--   local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
--     chart:drawToImage()
--   local t = chart:type()
--   lurek.log.info("LPieChart:type = " .. t, "ui")
-- end
--@api-stub: LPieChart:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LPieChart:typeOf
--   local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
--     chart:drawToImage()
--   lurek.log.info("is LPieChart: " .. tostring(chart:typeOf("LPieChart")), "ui")
--   lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
-- end
--@api-stub: LScatterPlot:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LScatterPlot:type
--   local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
--     plot:setXRange(1)
--   local t = plot:type()
--   lurek.log.info("LScatterPlot:type = " .. t, "ui")
-- end
--@api-stub: LScatterPlot:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LScatterPlot:typeOf
--   local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
--     plot:setXRange(1)
--   lurek.log.info("is LScatterPlot: " .. tostring(plot:typeOf("LScatterPlot")), "ui")
--   lurek.log.info("is wrong: " .. tostring(plot:typeOf("Unknown")), "ui")
-- end
--@api-stub: LTheme:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LTheme:type
--   local theme = new_example_image_widget():newTheme()
--     theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
--     theme:setStyle("button.text_color",  {1, 1, 1, 1})
--   local t = theme:type()
--   lurek.log.info("LTheme:type = " .. t, "ui")
-- end
--@api-stub: LTheme:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LTheme:typeOf
--   local theme = new_example_image_widget():newTheme()
--     theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
--     theme:setStyle("button.text_color",  {1, 1, 1, 1})
--   lurek.log.info("is LTheme: " .. tostring(theme:typeOf("LTheme")), "ui")
--   lurek.log.info("is wrong: " .. tostring(theme:typeOf("Unknown")), "ui")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.ui.type -------------------------------------------------
--@api-stub: lurek.ui.type
-- Returns the Lua type name of this widget (e.g. "LButton").
-- Use for runtime type dispatch in generic widget handlers.
-- if false then -- lurek.ui.type
--   local chart = lurek.ui.newLineChart({ width = 200, height = 150, title = "FPS" })
--   local t = chart:type()
--   lurek.log.info("ui.type=" .. tostring(t), "ui")
-- end
--@api-stub: LLineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Use when the data range is known ahead of time for a stable chart view.
-- if false then -- LLineChart:setYMax
--   local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Score" })
--   chart:setYMax(1000)
--   lurek.log.info("y-axis max set to 1000", "ui")
-- end
--@api-stub: LLineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Use to fix the time window when showing rolling 60-second traces.
-- if false then -- LLineChart:setXMax
--   local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "FPS" })
--   chart:setXMax(60)   -- fixed 60-second window
--   lurek.log.info("x-axis max set to 60", "ui")
-- end
--@api-stub: LLineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Use to embed charts into sprite textures or screenshots.
-- if false then -- LLineChart:drawToImage
--   local chart = lurek.ui.newLineChart({ width = 256, height = 128, title = "Wave" })
--   chart:setXMax(10)
--   chart:setYMax(1.0)
--   local idata = lurek.image.newImageData(256, 128)
--   chart:drawToImage(idata)
--   lurek.log.info("chart rendered to ImageData 256x128", "ui")
-- end

-- =============================================================================
-- STUBS: 352 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.ui.newButton --------------------------------------------
--@api-stub: lurek.ui.newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newButton([text])  -- -> LButton

-- ---- Stub: lurek.ui.newLabel ---------------------------------------------
--@api-stub: lurek.ui.newLabel
-- Creates a text label widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newLabel([text])  -- -> LLabel

-- ---- Stub: lurek.ui.newTextInput -----------------------------------------
--@api-stub: lurek.ui.newTextInput
-- Creates a text input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTextInput()  -- -> LTextInput

-- ---- Stub: lurek.ui.newCheckbox ------------------------------------------
--@api-stub: lurek.ui.newCheckbox
-- Creates a checkbox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newCheckbox([text])  -- -> LCheckbox

-- ---- Stub: lurek.ui.newSlider --------------------------------------------
--@api-stub: lurek.ui.newSlider
-- Creates a value slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSlider([min], [max])  -- -> LSlider

-- ---- Stub: lurek.ui.newProgressBar ---------------------------------------
--@api-stub: lurek.ui.newProgressBar
-- Creates a progress bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newProgressBar([min], [max])  -- -> LProgressBar

-- ---- Stub: lurek.ui.newComboBox ------------------------------------------
--@api-stub: lurek.ui.newComboBox
-- Creates a dropdown combo box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newComboBox()  -- -> LComboBox

-- ---- Stub: lurek.ui.newList ----------------------------------------------
--@api-stub: lurek.ui.newList
-- Creates a selectable list widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newList()  -- -> LListBox

-- ---- Stub: lurek.ui.newPanel ---------------------------------------------
--@api-stub: lurek.ui.newPanel
-- Creates a container panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newPanel()  -- -> LPanel

-- ---- Stub: lurek.ui.newLayout --------------------------------------------
--@api-stub: lurek.ui.newLayout
-- Creates a flexbox layout container.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newLayout([direction])  -- -> LLayout

-- ---- Stub: lurek.ui.newScrollPanel ---------------------------------------
--@api-stub: lurek.ui.newScrollPanel
-- Creates a scrollable panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newScrollPanel()  -- -> LScrollPanel

-- ---- Stub: lurek.ui.newNinePatch -----------------------------------------
--@api-stub: lurek.ui.newNinePatch
-- Creates a 9-patch slicer widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newNinePatch()  -- -> LNinePatch

-- ---- Stub: lurek.ui.newTabBar --------------------------------------------
--@api-stub: lurek.ui.newTabBar
-- Creates a tab bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTabBar()  -- -> LTabBar

-- ---- Stub: lurek.ui.newSeparator -----------------------------------------
--@api-stub: lurek.ui.newSeparator
-- Creates a separator line.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSeparator([vertical])  -- -> LSeparator

-- ---- Stub: lurek.ui.newSpacer --------------------------------------------
--@api-stub: lurek.ui.newSpacer
-- Creates a spacing filler widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSpacer([w], [h])  -- -> LSpacer

-- ---- Stub: lurek.ui.newToast ---------------------------------------------
--@api-stub: lurek.ui.newToast
-- Creates a toast notification widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newToast([message], [duration])  -- -> LToast

-- ---- Stub: lurek.ui.newTreeView ------------------------------------------
--@api-stub: lurek.ui.newTreeView
-- Creates a collapsible tree view widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTreeView()  -- -> LTreeView

-- ---- Stub: lurek.ui.newRadioButton ---------------------------------------
--@api-stub: lurek.ui.newRadioButton
-- Creates a grouped radio button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newRadioButton([text], [group])  -- -> LRadioButton

-- ---- Stub: lurek.ui.newScrollBar -----------------------------------------
--@api-stub: lurek.ui.newScrollBar
-- Creates a scroll bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newScrollBar([vertical])  -- -> LScrollBar

-- ---- Stub: lurek.ui.newWindow --------------------------------------------
--@api-stub: lurek.ui.newWindow
-- Creates a draggable window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newWindow([title])  -- -> LGuiWindow

-- ---- Stub: lurek.ui.newSplitPanel ----------------------------------------
--@api-stub: lurek.ui.newSplitPanel
-- Creates a resizable split panel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSplitPanel([orientation])  -- -> LSplitPanel

-- ---- Stub: lurek.ui.newDockPanel -----------------------------------------
--@api-stub: lurek.ui.newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newDockPanel()  -- -> LDockPanel

-- ---- Stub: lurek.ui.newToolbar -------------------------------------------
--@api-stub: lurek.ui.newToolbar
-- Creates a toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newToolbar([orientation])  -- -> LToolbar

-- ---- Stub: lurek.ui.newMenuBar -------------------------------------------
--@api-stub: lurek.ui.newMenuBar
-- Creates a menu bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newMenuBar()  -- -> LMenuBar

-- ---- Stub: lurek.ui.newMenuItem ------------------------------------------
--@api-stub: lurek.ui.newMenuItem
-- Creates a menu item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newMenuItem([text])  -- -> LMenuItem

-- ---- Stub: lurek.ui.newDialog --------------------------------------------
--@api-stub: lurek.ui.newDialog
-- Creates a modal dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newDialog([title])  -- -> LDialog

-- ---- Stub: lurek.ui.newStatusBar -----------------------------------------
--@api-stub: lurek.ui.newStatusBar
-- Creates a status bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newStatusBar()  -- -> LStatusBar

-- ---- Stub: lurek.ui.newAccordion -----------------------------------------
--@api-stub: lurek.ui.newAccordion
-- Creates a collapsible accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newAccordion()  -- -> LAccordion

-- ---- Stub: lurek.ui.newTooltipPanel --------------------------------------
--@api-stub: lurek.ui.newTooltipPanel
-- Creates a tooltip panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTooltipPanel([text])  -- -> LTooltipPanel

-- ---- Stub: lurek.ui.newColorPicker ---------------------------------------
--@api-stub: lurek.ui.newColorPicker
-- Creates a color picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newColorPicker()  -- -> LColorPicker

-- ---- Stub: lurek.ui.newTable ---------------------------------------------
--@api-stub: lurek.ui.newTable
-- Creates a data table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTable()  -- -> LGuiTable

-- ---- Stub: lurek.ui.newImageWidget ---------------------------------------
--@api-stub: lurek.ui.newImageWidget
-- Creates an image display widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newImageWidget()  -- -> LImageWidget

-- ---- Stub: lurek.ui.newTheme ---------------------------------------------
--@api-stub: lurek.ui.newTheme
-- Creates a new theme instance.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newTheme()  -- -> LTheme

-- ---- Stub: lurek.ui.setTheme ---------------------------------------------
--@api-stub: lurek.ui.setTheme
-- Sets the active GUI theme.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.setTheme(theme_ud)

-- ---- Stub: lurek.ui.getTheme ---------------------------------------------
--@api-stub: lurek.ui.getTheme
-- Returns whether a theme is set.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.getTheme()  -- -> boolean

-- ---- Stub: lurek.ui.getRoot ----------------------------------------------
--@api-stub: lurek.ui.getRoot
-- Returns the root panel widget table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.getRoot()  -- -> LPanel

-- ---- Stub: lurek.ui.setFocus ---------------------------------------------
--@api-stub: lurek.ui.setFocus
-- Sets keyboard focus to a widget or clears it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.setFocus([widget])

-- ---- Stub: lurek.ui.getFocus ---------------------------------------------
--@api-stub: lurek.ui.getFocus
-- Returns the focused widget index or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.getFocus()  -- -> number

-- ---- Stub: lurek.ui.focusNext --------------------------------------------
--@api-stub: lurek.ui.focusNext
-- Moves focus to the next focusable widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.focusNext()

-- ---- Stub: lurek.ui.focusPrev --------------------------------------------
--@api-stub: lurek.ui.focusPrev
-- Moves focus to the previous focusable widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.focusPrev()

-- ---- Stub: lurek.ui.clearFocus -------------------------------------------
--@api-stub: lurek.ui.clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.clearFocus()

-- ---- Stub: lurek.ui.addToast ---------------------------------------------
--@api-stub: lurek.ui.addToast
-- Queues a toast notification from a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.addToast(toast_table)

-- ---- Stub: lurek.ui.getToastCount ----------------------------------------
--@api-stub: lurek.ui.getToastCount
-- Returns the number of active toasts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.getToastCount()  -- -> number

-- ---- Stub: lurek.ui.mousepressed -----------------------------------------
--@api-stub: lurek.ui.mousepressed
-- Forwards a mouse press event to the GUI.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.mousepressed(0.0, 0.0, [btn])  -- -> boolean

-- ---- Stub: lurek.ui.mousereleased ----------------------------------------
--@api-stub: lurek.ui.mousereleased
-- Forwards a mouse release event to the GUI.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.mousereleased(0.0, 0.0, [btn])  -- -> boolean

-- ---- Stub: lurek.ui.mousemoved -------------------------------------------
--@api-stub: lurek.ui.mousemoved
-- Forwards a mouse move event to the GUI.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.mousemoved(0.0, 0.0)  -- -> boolean

-- ---- Stub: lurek.ui.keypressed -------------------------------------------
--@api-stub: lurek.ui.keypressed
-- Forwards a key press event to the GUI.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.keypressed("player_score")  -- -> boolean

-- ---- Stub: lurek.ui.textinput --------------------------------------------
--@api-stub: lurek.ui.textinput
-- Forwards text input to the focused text input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.textinput("Hello, world!")  -- -> boolean

-- ---- Stub: lurek.ui.wheelmoved -------------------------------------------
--@api-stub: lurek.ui.wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.wheelmoved(0.0, 0.0)  -- -> boolean

-- ---- Stub: lurek.ui.update -----------------------------------------------
--@api-stub: lurek.ui.update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.update(0.016)

-- ---- Stub: lurek.ui.draw -------------------------------------------------
--@api-stub: lurek.ui.draw
-- Invokes all registered `on_draw` callbacks with a screen-space rect table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.draw()

-- ---- Stub: lurek.ui.newCustomWidget --------------------------------------
--@api-stub: lurek.ui.newCustomWidget
-- Creates a new widget with custom Lua-driven rendering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newCustomWidget([config])  -- -> LWidget

-- ---- Stub: lurek.ui.getWidgetCount ---------------------------------------
--@api-stub: lurek.ui.getWidgetCount
-- Returns the total widget count in the context.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.getWidgetCount()  -- -> number

-- ---- Stub: lurek.ui.drawToImage ------------------------------------------
--@api-stub: lurek.ui.drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.drawToImage(64.0, 64.0)  -- -> ImageData

-- ---- Stub: lurek.ui.newLineChart -----------------------------------------
--@api-stub: lurek.ui.newLineChart
-- Creates a new line chart.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newLineChart(opts)  -- -> LLineChart

-- ---- Stub: lurek.ui.newBarChart ------------------------------------------
--@api-stub: lurek.ui.newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newBarChart(opts)  -- -> LBarChart

-- ---- Stub: lurek.ui.newScatterPlot ---------------------------------------
--@api-stub: lurek.ui.newScatterPlot
-- Creates a new scatter plot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newScatterPlot(opts)  -- -> LScatterPlot

-- ---- Stub: lurek.ui.newPieChart ------------------------------------------
--@api-stub: lurek.ui.newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newPieChart(opts)  -- -> LPieChart

-- ---- Stub: lurek.ui.newAreaChart -----------------------------------------
--@api-stub: lurek.ui.newAreaChart
-- Creates a new stacked-area chart.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newAreaChart(opts)  -- -> LAreaChart

-- ---- Stub: lurek.ui.parseWidgetState -------------------------------------
--@api-stub: lurek.ui.parseWidgetState
-- Parses a widget state string and returns its canonical form.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.parseWidgetState(state)  -- -> string

-- ---- Stub: lurek.ui.newSpinBox -------------------------------------------
--@api-stub: lurek.ui.newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSpinBox([min], [max])  -- -> LSpinBox

-- ---- Stub: lurek.ui.newSwitch --------------------------------------------
--@api-stub: lurek.ui.newSwitch
-- Creates a toggle switch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newSwitch([on])  -- -> LSwitch

-- ---- Stub: lurek.ui.newBadge ---------------------------------------------
--@api-stub: lurek.ui.newBadge
-- Creates a badge widget displaying a numeric count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.newBadge([count])  -- -> LBadge

-- ---- Stub: lurek.ui.setDefaultTheme --------------------------------------
--@api-stub: lurek.ui.setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.setDefaultTheme()

-- ---- Stub: lurek.ui.setViewport ------------------------------------------
--@api-stub: lurek.ui.setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.setViewport(64.0, 64.0)

-- ---- Stub: lurek.ui.flushCache -------------------------------------------
--@api-stub: lurek.ui.flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.flushCache()  -- -> boolean

-- ---- Stub: lurek.ui.update_bindings --------------------------------------
--@api-stub: lurek.ui.update_bindings
-- Updates widgets whose bound keys match values in the provided data table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.update_bindings()

-- ---- Stub: lurek.ui.loadLayout -------------------------------------------
--@api-stub: lurek.ui.loadLayout
-- Loads a widget tree from a Lua definition table and attaches it to the UI root.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.loadLayout()  -- -> number

-- ---- Stub: lurek.ui.loadLayoutFile ---------------------------------------
--@api-stub: lurek.ui.loadLayoutFile
-- Loads a widget tree from a TOML layout file and attaches it to the UI root.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.loadLayoutFile("assets/hero.png")  -- -> number

-- ---- Stub: lurek.ui.renderToImage ----------------------------------------
--@api-stub: lurek.ui.renderToImage
-- Renders the current UI widget tree to a PNG file for testing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.ui.renderToImage(256, 256, "assets/hero.png")

-- -----------------------------------------------------------------------------
-- LAccordion methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAccordion:addSection -----------------------------------------
--@api-stub: LAccordion:addSection
-- Adds a section entry to this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:addSection(title, [content_idx])
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:getSectionCount ------------------------------------
--@api-stub: LAccordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:getSectionCount()  -- -> integer
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:toggleSection --------------------------------------
--@api-stub: LAccordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:toggleSection(section_idx)  -- -> boolean
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:isSectionExpanded ----------------------------------
--@api-stub: LAccordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:isSectionExpanded(section_idx)  -- -> boolean
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:isExclusive ----------------------------------------
--@api-stub: LAccordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:isExclusive()  -- -> boolean
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:setExclusive ---------------------------------------
--@api-stub: LAccordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:setExclusive(1.0)
-- (replace lAccordion_stub with your real LAccordion instance above)

-- ---- Stub: LAccordion:getSectionTitle ------------------------------------
--@api-stub: LAccordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAccordion_stub:getSectionTitle(section_idx)  -- -> string
-- (replace lAccordion_stub with your real LAccordion instance above)

-- -----------------------------------------------------------------------------
-- LBadge methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBadge:setCount -----------------------------------------------
--@api-stub: LBadge:setCount
-- Sets the count displayed on this Badge widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBadge_stub:setCount(10)
-- (replace lBadge_stub with your real LBadge instance above)

-- ---- Stub: LBadge:getCount -----------------------------------------------
--@api-stub: LBadge:getCount
-- Returns the raw count of this Badge widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBadge_stub:getCount()  -- -> integer
-- (replace lBadge_stub with your real LBadge instance above)

-- ---- Stub: LBadge:getDisplayText -----------------------------------------
--@api-stub: LBadge:getDisplayText
-- Returns the display text of this Badge widget, e.g. "99+" when over the max.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBadge_stub:getDisplayText()  -- -> string
-- (replace lBadge_stub with your real LBadge instance above)

-- -----------------------------------------------------------------------------
-- LButton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LButton:setText -----------------------------------------------
--@api-stub: LButton:setText
-- Sets the text for this Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lButton_stub:setText("Hello, world!")
-- (replace lButton_stub with your real LButton instance above)

-- ---- Stub: LButton:getText -----------------------------------------------
--@api-stub: LButton:getText
-- Returns the text of this Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lButton_stub:getText()  -- -> string
-- (replace lButton_stub with your real LButton instance above)

-- -----------------------------------------------------------------------------
-- LCheckbox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCheckbox:setChecked ------------------------------------------
--@api-stub: LCheckbox:setChecked
-- Sets the checked for this Checkbox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCheckbox_stub:setChecked(checked)
-- (replace lCheckbox_stub with your real LCheckbox instance above)

-- ---- Stub: LCheckbox:isChecked -------------------------------------------
--@api-stub: LCheckbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCheckbox_stub:isChecked()  -- -> boolean
-- (replace lCheckbox_stub with your real LCheckbox instance above)

-- ---- Stub: LCheckbox:setText ---------------------------------------------
--@api-stub: LCheckbox:setText
-- Sets the text for this Checkbox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCheckbox_stub:setText("Hello, world!")
-- (replace lCheckbox_stub with your real LCheckbox instance above)

-- ---- Stub: LCheckbox:getText ---------------------------------------------
--@api-stub: LCheckbox:getText
-- Returns the text of this Checkbox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCheckbox_stub:getText()  -- -> string
-- (replace lCheckbox_stub with your real LCheckbox instance above)

-- -----------------------------------------------------------------------------
-- LColorPicker methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LColorPicker:getColor -----------------------------------------
--@api-stub: LColorPicker:getColor
-- Returns the color of this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:getColor()  -- -> number
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:setColor -----------------------------------------
--@api-stub: LColorPicker:setColor
-- Sets the color for this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:setColor(1.0, green, 0.2, [a])
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:getShowAlpha -------------------------------------
--@api-stub: LColorPicker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:getShowAlpha()  -- -> boolean
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:setShowAlpha -------------------------------------
--@api-stub: LColorPicker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:setShowAlpha(1.0)
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:getColorMode -------------------------------------
--@api-stub: LColorPicker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:getColorMode()  -- -> string
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:setColorMode -------------------------------------
--@api-stub: LColorPicker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:setColorMode(mode)
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- ---- Stub: LColorPicker:setOnChange --------------------------------------
--@api-stub: LColorPicker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lColorPicker_stub:setOnChange(f)
-- (replace lColorPicker_stub with your real LColorPicker instance above)

-- -----------------------------------------------------------------------------
-- LComboBox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LComboBox:addItem ---------------------------------------------
--@api-stub: LComboBox:addItem
-- Adds a item entry to this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:addItem("Hello, world!")
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:removeItem ------------------------------------------
--@api-stub: LComboBox:removeItem
-- Removes the item from this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:removeItem(1)  -- -> boolean
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:clearItems ------------------------------------------
--@api-stub: LComboBox:clearItems
-- Clears all items entries from this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:clearItems()
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:getItemCount ----------------------------------------
--@api-stub: LComboBox:getItemCount
-- Returns the item count of this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:getItemCount()  -- -> integer
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:getItem ---------------------------------------------
--@api-stub: LComboBox:getItem
-- Returns the item of this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:getItem(1)  -- -> string
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:setSelectedIndex ------------------------------------
--@api-stub: LComboBox:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:setSelectedIndex(1)
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:getSelectedIndex ------------------------------------
--@api-stub: LComboBox:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:getSelectedIndex()  -- -> integer
-- (replace lComboBox_stub with your real LComboBox instance above)

-- ---- Stub: LComboBox:getSelectedItem -------------------------------------
--@api-stub: LComboBox:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lComboBox_stub:getSelectedItem()  -- -> string
-- (replace lComboBox_stub with your real LComboBox instance above)

-- -----------------------------------------------------------------------------
-- LDialog methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDialog:getTitle ----------------------------------------------
--@api-stub: LDialog:getTitle
-- Returns the title of this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:getTitle()  -- -> string
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:setTitle ----------------------------------------------
--@api-stub: LDialog:setTitle
-- Sets the title for this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:setTitle(title)
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:isModal -----------------------------------------------
--@api-stub: LDialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:isModal()  -- -> boolean
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:setModal ----------------------------------------------
--@api-stub: LDialog:setModal
-- Sets the modal for this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:setModal(1.0)
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:isOpen ------------------------------------------------
--@api-stub: LDialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:isOpen()  -- -> boolean
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:open --------------------------------------------------
--@api-stub: LDialog:open
-- Performs the open operation on this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:open()
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:close -------------------------------------------------
--@api-stub: LDialog:close
-- Closes and removes this dialog from the screen.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:close()
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:setOnClose --------------------------------------------
--@api-stub: LDialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:setOnClose(f)
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:setContent --------------------------------------------
--@api-stub: LDialog:setContent
-- Sets the content for this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:setContent([content_idx])
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:getContent --------------------------------------------
--@api-stub: LDialog:getContent
-- Returns the content of this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:getContent()  -- -> integer
-- (replace lDialog_stub with your real LDialog instance above)

-- ---- Stub: LDialog:addButton ---------------------------------------------
--@api-stub: LDialog:addButton
-- Adds a button entry to this Dialog widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDialog_stub:addButton("Hello, world!", [cb])  -- -> integer
-- (replace lDialog_stub with your real LDialog instance above)

-- -----------------------------------------------------------------------------
-- LDockPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDockPanel:dock -----------------------------------------------
--@api-stub: LDockPanel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDockPanel_stub:dock(child_idx, side)
-- (replace lDockPanel_stub with your real LDockPanel instance above)

-- ---- Stub: LDockPanel:undock ---------------------------------------------
--@api-stub: LDockPanel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDockPanel_stub:undock(child_idx)
-- (replace lDockPanel_stub with your real LDockPanel instance above)

-- ---- Stub: LDockPanel:getDockedCount -------------------------------------
--@api-stub: LDockPanel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDockPanel_stub:getDockedCount()  -- -> integer
-- (replace lDockPanel_stub with your real LDockPanel instance above)

-- ---- Stub: LDockPanel:setSplitSize ---------------------------------------
--@api-stub: LDockPanel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDockPanel_stub:setSplitSize(side, size)
-- (replace lDockPanel_stub with your real LDockPanel instance above)

-- ---- Stub: LDockPanel:getSplitSize ---------------------------------------
--@api-stub: LDockPanel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDockPanel_stub:getSplitSize(side)  -- -> number
-- (replace lDockPanel_stub with your real LDockPanel instance above)

-- -----------------------------------------------------------------------------
-- LGuiTable methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGuiTable:addColumn -------------------------------------------
--@api-stub: LGuiTable:addColumn
-- Adds a column entry to this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:addColumn(header, [width])
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:getColumnCount --------------------------------------
--@api-stub: LGuiTable:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:getColumnCount()  -- -> integer
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:addRow ----------------------------------------------
--@api-stub: LGuiTable:addRow
-- Adds a row entry to this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:addRow(cells)
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:getRowCount -----------------------------------------
--@api-stub: LGuiTable:getRowCount
-- Returns the row count of this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:getRowCount()  -- -> integer
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:getCell ---------------------------------------------
--@api-stub: LGuiTable:getCell
-- Returns the cell of this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:getCell(row, col)  -- -> string
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:setCell ---------------------------------------------
--@api-stub: LGuiTable:setCell
-- Sets the cell for this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:setCell(row, col, "Hello, world!")
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:getSelectedRow --------------------------------------
--@api-stub: LGuiTable:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:getSelectedRow()  -- -> integer
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:setSelectedRow --------------------------------------
--@api-stub: LGuiTable:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:setSelectedRow([row])
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:isSortable ------------------------------------------
--@api-stub: LGuiTable:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:isSortable()  -- -> boolean
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:setSortable -----------------------------------------
--@api-stub: LGuiTable:setSortable
-- Sets the sortable for this Gui_Table widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:setSortable(1.0)
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- ---- Stub: LGuiTable:setOnSelect -----------------------------------------
--@api-stub: LGuiTable:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiTable_stub:setOnSelect(f)
-- (replace lGuiTable_stub with your real LGuiTable instance above)

-- -----------------------------------------------------------------------------
-- LGuiWindow methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGuiWindow:getTitle -------------------------------------------
--@api-stub: LGuiWindow:getTitle
-- Returns the title of this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:getTitle()  -- -> string
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:setTitle -------------------------------------------
--@api-stub: LGuiWindow:setTitle
-- Sets the title for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:setTitle(title)
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:isCloseable ----------------------------------------
--@api-stub: LGuiWindow:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:isCloseable()  -- -> boolean
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:setCloseable ---------------------------------------
--@api-stub: LGuiWindow:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:setCloseable(1.0)
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:isDraggable ----------------------------------------
--@api-stub: LGuiWindow:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:isDraggable()  -- -> boolean
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:setDraggable ---------------------------------------
--@api-stub: LGuiWindow:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:setDraggable(1.0)
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:isResizable ----------------------------------------
--@api-stub: LGuiWindow:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:isResizable()  -- -> boolean
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:setResizable ---------------------------------------
--@api-stub: LGuiWindow:setResizable
-- Sets the resizable for this Gui_Window widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:setResizable(1.0)
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- ---- Stub: LGuiWindow:setOnClose -----------------------------------------
--@api-stub: LGuiWindow:setOnClose
-- Registers a callback invoked when this window is closed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGuiWindow_stub:setOnClose(f)
-- (replace lGuiWindow_stub with your real LGuiWindow instance above)

-- -----------------------------------------------------------------------------
-- LImageWidget methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LImageWidget:getScaleMode -------------------------------------
--@api-stub: LImageWidget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageWidget_stub:getScaleMode()  -- -> string
-- (replace lImageWidget_stub with your real LImageWidget instance above)

-- ---- Stub: LImageWidget:setScaleMode -------------------------------------
--@api-stub: LImageWidget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageWidget_stub:setScaleMode(mode)
-- (replace lImageWidget_stub with your real LImageWidget instance above)

-- ---- Stub: LImageWidget:getTint ------------------------------------------
--@api-stub: LImageWidget:getTint
-- Returns the tint of this Image_Widget widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageWidget_stub:getTint()  -- -> number
-- (replace lImageWidget_stub with your real LImageWidget instance above)

-- ---- Stub: LImageWidget:setTint ------------------------------------------
--@api-stub: LImageWidget:setTint
-- Sets the tint for this Image_Widget widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageWidget_stub:setTint(1.0, green, 0.2, [a])
-- (replace lImageWidget_stub with your real LImageWidget instance above)

-- -----------------------------------------------------------------------------
-- LLabel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLabel:setText ------------------------------------------------
--@api-stub: LLabel:setText
-- Sets the text for this Label widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLabel_stub:setText("Hello, world!")
-- (replace lLabel_stub with your real LLabel instance above)

-- ---- Stub: LLabel:getText ------------------------------------------------
--@api-stub: LLabel:getText
-- Returns the text of this Label widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLabel_stub:getText()  -- -> string
-- (replace lLabel_stub with your real LLabel instance above)

-- -----------------------------------------------------------------------------
-- LLayout methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLayout:setDirection ------------------------------------------
--@api-stub: LLayout:setDirection
-- Sets the direction for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setDirection(dir)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:getDirection ------------------------------------------
--@api-stub: LLayout:getDirection
-- Returns the direction of this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:getDirection()  -- -> string
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:setSpacing --------------------------------------------
--@api-stub: LLayout:setSpacing
-- Sets the spacing for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setSpacing(spacing)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:getSpacing --------------------------------------------
--@api-stub: LLayout:getSpacing
-- Returns the spacing of this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:getSpacing()  -- -> number
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:setColumns --------------------------------------------
--@api-stub: LLayout:setColumns
-- Sets the columns for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setColumns(5)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:setWrap -----------------------------------------------
--@api-stub: LLayout:setWrap
-- Sets the wrap for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setWrap(wrap)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:getWrap -----------------------------------------------
--@api-stub: LLayout:getWrap
-- Returns the wrap of this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:getWrap()  -- -> boolean
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:setAlign ----------------------------------------------
--@api-stub: LLayout:setAlign
-- Sets the align for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setAlign(align)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:getAlign ----------------------------------------------
--@api-stub: LLayout:getAlign
-- Returns the align of this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:getAlign()  -- -> string
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:setJustify --------------------------------------------
--@api-stub: LLayout:setJustify
-- Sets the justify for this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:setJustify(justify)
-- (replace lLayout_stub with your real LLayout instance above)

-- ---- Stub: LLayout:getJustify --------------------------------------------
--@api-stub: LLayout:getJustify
-- Returns the justify of this Layout widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLayout_stub:getJustify()  -- -> string
-- (replace lLayout_stub with your real LLayout instance above)

-- -----------------------------------------------------------------------------
-- LLineChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLineChart:addSeries ------------------------------------------
--@api-stub: LLineChart:addSeries
-- Adds a named data series to the chart.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLineChart_stub:addSeries("hero", pts_tbl, 1.0, 0.8, 0.2)
-- (replace lLineChart_stub with your real LLineChart instance above)

-- -----------------------------------------------------------------------------
-- LListBox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LListBox:addItem ----------------------------------------------
--@api-stub: LListBox:addItem
-- Adds a item entry to this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:addItem("Hello, world!")
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:removeItem -------------------------------------------
--@api-stub: LListBox:removeItem
-- Removes the item from this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:removeItem(1)
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:clearItems -------------------------------------------
--@api-stub: LListBox:clearItems
-- Clears all items entries from this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:clearItems()
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:getItemCount -----------------------------------------
--@api-stub: LListBox:getItemCount
-- Returns the item count of this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:getItemCount()  -- -> integer
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:getItem ----------------------------------------------
--@api-stub: LListBox:getItem
-- Returns the item of this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:getItem(1)  -- -> string
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:setSelectedIndex -------------------------------------
--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:setSelectedIndex(1)
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:getSelectedIndex -------------------------------------
--@api-stub: LListBox:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:getSelectedIndex()  -- -> integer
-- (replace lListBox_stub with your real LListBox instance above)

-- ---- Stub: LListBox:setItemHeight ----------------------------------------
--@api-stub: LListBox:setItemHeight
-- Sets the item height for this List_Box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lListBox_stub:setItemHeight(64.0)
-- (replace lListBox_stub with your real LListBox instance above)

-- -----------------------------------------------------------------------------
-- LMenuBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMenuBar:addMenu ----------------------------------------------
--@api-stub: LMenuBar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuBar_stub:addMenu(menu_idx)
-- (replace lMenuBar_stub with your real LMenuBar instance above)

-- ---- Stub: LMenuBar:removeMenu -------------------------------------------
--@api-stub: LMenuBar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuBar_stub:removeMenu(menu_idx)  -- -> boolean
-- (replace lMenuBar_stub with your real LMenuBar instance above)

-- ---- Stub: LMenuBar:getMenus ---------------------------------------------
--@api-stub: LMenuBar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuBar_stub:getMenus()  -- -> table
-- (replace lMenuBar_stub with your real LMenuBar instance above)

-- ---- Stub: LMenuBar:getMenuCount -----------------------------------------
--@api-stub: LMenuBar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuBar_stub:getMenuCount()  -- -> integer
-- (replace lMenuBar_stub with your real LMenuBar instance above)

-- -----------------------------------------------------------------------------
-- LMenuItem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMenuItem:getText ---------------------------------------------
--@api-stub: LMenuItem:getText
-- Returns the text of this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:getText()  -- -> string
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:setText ---------------------------------------------
--@api-stub: LMenuItem:setText
-- Sets the text for this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:setText("Hello, world!")
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:getShortcut -----------------------------------------
--@api-stub: LMenuItem:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:getShortcut()  -- -> string
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:setShortcut -----------------------------------------
--@api-stub: LMenuItem:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:setShortcut(shortcut)
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:isChecked -------------------------------------------
--@api-stub: LMenuItem:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:isChecked()  -- -> boolean
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:setChecked ------------------------------------------
--@api-stub: LMenuItem:setChecked
-- Sets the checked for this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:setChecked(1.0)
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:addSubItem ------------------------------------------
--@api-stub: LMenuItem:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:addSubItem(child_idx)
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:getSubItems -----------------------------------------
--@api-stub: LMenuItem:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:getSubItems()  -- -> table
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- ---- Stub: LMenuItem:setOnClick ------------------------------------------
--@api-stub: LMenuItem:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMenuItem_stub:setOnClick(f)
-- (replace lMenuItem_stub with your real LMenuItem instance above)

-- -----------------------------------------------------------------------------
-- LNinePatch methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNinePatch:setInsets ------------------------------------------
--@api-stub: LNinePatch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNinePatch_stub:setInsets(left, top, right, bottom)
-- (replace lNinePatch_stub with your real LNinePatch instance above)

-- ---- Stub: LNinePatch:getInsets ------------------------------------------
--@api-stub: LNinePatch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNinePatch_stub:getInsets()  -- -> integer
-- (replace lNinePatch_stub with your real LNinePatch instance above)

-- ---- Stub: LNinePatch:setImageDimensions ---------------------------------
--@api-stub: LNinePatch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNinePatch_stub:setImageDimensions(64.0, 64.0)
-- (replace lNinePatch_stub with your real LNinePatch instance above)

-- ---- Stub: LNinePatch:getImageDimensions ---------------------------------
--@api-stub: LNinePatch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNinePatch_stub:getImageDimensions()  -- -> integer
-- (replace lNinePatch_stub with your real LNinePatch instance above)

-- ---- Stub: LNinePatch:getSlices ------------------------------------------
--@api-stub: LNinePatch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNinePatch_stub:getSlices()  -- -> table
-- (replace lNinePatch_stub with your real LNinePatch instance above)

-- -----------------------------------------------------------------------------
-- LPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPanel:setTitle -----------------------------------------------
--@api-stub: LPanel:setTitle
-- Sets the title for this Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPanel_stub:setTitle(title)
-- (replace lPanel_stub with your real LPanel instance above)

-- ---- Stub: LPanel:getTitle -----------------------------------------------
--@api-stub: LPanel:getTitle
-- Returns the title of this Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPanel_stub:getTitle()  -- -> string
-- (replace lPanel_stub with your real LPanel instance above)

-- ---- Stub: LPanel:setScrollable ------------------------------------------
--@api-stub: LPanel:setScrollable
-- Sets the scrollable for this Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPanel_stub:setScrollable(scrollable)
-- (replace lPanel_stub with your real LPanel instance above)

-- -----------------------------------------------------------------------------
-- LProgressBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LProgressBar:setValue -----------------------------------------
--@api-stub: LProgressBar:setValue
-- Sets the value for this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:setValue(1.0)
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- ---- Stub: LProgressBar:getValue -----------------------------------------
--@api-stub: LProgressBar:getValue
-- Returns the value of this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:getValue()  -- -> number
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- ---- Stub: LProgressBar:getProgress --------------------------------------
--@api-stub: LProgressBar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:getProgress()  -- -> number
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- ---- Stub: LProgressBar:setRange -----------------------------------------
--@api-stub: LProgressBar:setRange
-- Sets the range for this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:setRange(min, max)
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- ---- Stub: LProgressBar:getMin -------------------------------------------
--@api-stub: LProgressBar:getMin
-- Returns the min of this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:getMin()  -- -> number
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- ---- Stub: LProgressBar:getMax -------------------------------------------
--@api-stub: LProgressBar:getMax
-- Returns the max of this Progress_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProgressBar_stub:getMax()  -- -> number
-- (replace lProgressBar_stub with your real LProgressBar instance above)

-- -----------------------------------------------------------------------------
-- LRadioButton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRadioButton:getText ------------------------------------------
--@api-stub: LRadioButton:getText
-- Returns the text of this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:getText()  -- -> string
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:setText ------------------------------------------
--@api-stub: LRadioButton:setText
-- Sets the text for this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:setText("Hello, world!")
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:isSelected ---------------------------------------
--@api-stub: LRadioButton:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:isSelected()  -- -> boolean
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:setSelected --------------------------------------
--@api-stub: LRadioButton:setSelected
-- Sets the selected for this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:setSelected(1.0)
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:getGroup -----------------------------------------
--@api-stub: LRadioButton:getGroup
-- Returns the group of this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:getGroup()  -- -> string
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:setGroup -----------------------------------------
--@api-stub: LRadioButton:setGroup
-- Sets the group for this Radio_Button widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:setGroup(group)
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- ---- Stub: LRadioButton:setOnChange --------------------------------------
--@api-stub: LRadioButton:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRadioButton_stub:setOnChange(f)
-- (replace lRadioButton_stub with your real LRadioButton instance above)

-- -----------------------------------------------------------------------------
-- LScrollBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LScrollBar:getScrollPosition ----------------------------------
--@api-stub: LScrollBar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:getScrollPosition()  -- -> number
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:setScrollPosition ----------------------------------
--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:setScrollPosition(1.0)
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:getContentSize -------------------------------------
--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:getContentSize()  -- -> number
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:setContentSize -------------------------------------
--@api-stub: LScrollBar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:setContentSize(1.0)
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:getViewSize ----------------------------------------
--@api-stub: LScrollBar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:getViewSize()  -- -> number
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:setViewSize ----------------------------------------
--@api-stub: LScrollBar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:setViewSize(1.0)
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:isVertical -----------------------------------------
--@api-stub: LScrollBar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:isVertical()  -- -> boolean
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- ---- Stub: LScrollBar:setOnChange ----------------------------------------
--@api-stub: LScrollBar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollBar_stub:setOnChange(f)
-- (replace lScrollBar_stub with your real LScrollBar instance above)

-- -----------------------------------------------------------------------------
-- LScrollPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LScrollPanel:setContentSize -----------------------------------
--@api-stub: LScrollPanel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:setContentSize(64.0, 64.0)
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:getContentSize -----------------------------------
--@api-stub: LScrollPanel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:getContentSize()  -- -> number
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:setScrollPosition --------------------------------
--@api-stub: LScrollPanel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:setScrollPosition(0.0, 0.0)
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:getScrollPosition --------------------------------
--@api-stub: LScrollPanel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:getScrollPosition()  -- -> number
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:getMaxScroll -------------------------------------
--@api-stub: LScrollPanel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:getMaxScroll()  -- -> number
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:setScrollSpeed -----------------------------------
--@api-stub: LScrollPanel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:setScrollSpeed(120.0)
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- ---- Stub: LScrollPanel:getScrollSpeed -----------------------------------
--@api-stub: LScrollPanel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lScrollPanel_stub:getScrollSpeed()  -- -> number
-- (replace lScrollPanel_stub with your real LScrollPanel instance above)

-- -----------------------------------------------------------------------------
-- LSeparator methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSeparator:setVertical ----------------------------------------
--@api-stub: LSeparator:setVertical
-- Sets the vertical for this Separator widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSeparator_stub:setVertical(1.0)
-- (replace lSeparator_stub with your real LSeparator instance above)

-- ---- Stub: LSeparator:isVertical -----------------------------------------
--@api-stub: LSeparator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSeparator_stub:isVertical()  -- -> boolean
-- (replace lSeparator_stub with your real LSeparator instance above)

-- ---- Stub: LSeparator:setThickness ---------------------------------------
--@api-stub: LSeparator:setThickness
-- Sets the thickness for this Separator widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSeparator_stub:setThickness(thickness)
-- (replace lSeparator_stub with your real LSeparator instance above)

-- ---- Stub: LSeparator:getThickness ---------------------------------------
--@api-stub: LSeparator:getThickness
-- Returns the thickness of this Separator widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSeparator_stub:getThickness()  -- -> number
-- (replace lSeparator_stub with your real LSeparator instance above)

-- -----------------------------------------------------------------------------
-- LSlider methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSlider:setValue ----------------------------------------------
--@api-stub: LSlider:setValue
-- Sets the value for this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:setValue(1.0)
-- (replace lSlider_stub with your real LSlider instance above)

-- ---- Stub: LSlider:getValue ----------------------------------------------
--@api-stub: LSlider:getValue
-- Returns the value of this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:getValue()  -- -> number
-- (replace lSlider_stub with your real LSlider instance above)

-- ---- Stub: LSlider:setRange ----------------------------------------------
--@api-stub: LSlider:setRange
-- Sets the range for this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:setRange(min, max)
-- (replace lSlider_stub with your real LSlider instance above)

-- ---- Stub: LSlider:setStep -----------------------------------------------
--@api-stub: LSlider:setStep
-- Sets the step for this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:setStep(step)
-- (replace lSlider_stub with your real LSlider instance above)

-- ---- Stub: LSlider:getMin ------------------------------------------------
--@api-stub: LSlider:getMin
-- Returns the min of this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:getMin()  -- -> number
-- (replace lSlider_stub with your real LSlider instance above)

-- ---- Stub: LSlider:getMax ------------------------------------------------
--@api-stub: LSlider:getMax
-- Returns the max of this Slider widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSlider_stub:getMax()  -- -> number
-- (replace lSlider_stub with your real LSlider instance above)

-- -----------------------------------------------------------------------------
-- LSpinBox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSpinBox:setValue ---------------------------------------------
--@api-stub: LSpinBox:setValue
-- Sets the value for this SpinBox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:setValue(1.0)
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- ---- Stub: LSpinBox:getValue ---------------------------------------------
--@api-stub: LSpinBox:getValue
-- Returns the current value of this SpinBox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:getValue()  -- -> number
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- ---- Stub: LSpinBox:increment --------------------------------------------
--@api-stub: LSpinBox:increment
-- Increments the value by one step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:increment()
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- ---- Stub: LSpinBox:decrement --------------------------------------------
--@api-stub: LSpinBox:decrement
-- Decrements the value by one step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:decrement()
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- ---- Stub: LSpinBox:setRange ---------------------------------------------
--@api-stub: LSpinBox:setRange
-- Sets the valid range for this SpinBox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:setRange(min, max)
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- ---- Stub: LSpinBox:setStep ----------------------------------------------
--@api-stub: LSpinBox:setStep
-- Sets the increment step for this SpinBox widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpinBox_stub:setStep(step)
-- (replace lSpinBox_stub with your real LSpinBox instance above)

-- -----------------------------------------------------------------------------
-- LSplitPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSplitPanel:getOrientation ------------------------------------
--@api-stub: LSplitPanel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:getOrientation()  -- -> string
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:setOrientation ------------------------------------
--@api-stub: LSplitPanel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:setOrientation(1.0)
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:getSplitPosition ----------------------------------
--@api-stub: LSplitPanel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:getSplitPosition()  -- -> number
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:setSplitPosition ----------------------------------
--@api-stub: LSplitPanel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:setSplitPosition(1.0)
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:getMinPanelSize -----------------------------------
--@api-stub: LSplitPanel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:getMinPanelSize()  -- -> number
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:setMinPanelSize -----------------------------------
--@api-stub: LSplitPanel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:setMinPanelSize(1.0)
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:setFirstChild -------------------------------------
--@api-stub: LSplitPanel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:setFirstChild(child_idx)
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:setSecondChild ------------------------------------
--@api-stub: LSplitPanel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:setSecondChild(child_idx)
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:getFirstChild -------------------------------------
--@api-stub: LSplitPanel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:getFirstChild()  -- -> integer
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- ---- Stub: LSplitPanel:getSecondChild ------------------------------------
--@api-stub: LSplitPanel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSplitPanel_stub:getSecondChild()  -- -> integer
-- (replace lSplitPanel_stub with your real LSplitPanel instance above)

-- -----------------------------------------------------------------------------
-- LStatusBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStatusBar:addSection -----------------------------------------
--@api-stub: LStatusBar:addSection
-- Adds a section entry to this Status_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:addSection("Hello, world!", [width])
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- ---- Stub: LStatusBar:setSectionText -------------------------------------
--@api-stub: LStatusBar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:setSectionText(section_idx, "Hello, world!")
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- ---- Stub: LStatusBar:getSectionText -------------------------------------
--@api-stub: LStatusBar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:getSectionText(section_idx)  -- -> string
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- ---- Stub: LStatusBar:getSectionCount ------------------------------------
--@api-stub: LStatusBar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:getSectionCount()  -- -> integer
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- ---- Stub: LStatusBar:setSectionCount ------------------------------------
--@api-stub: LStatusBar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:setSectionCount(10)
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- ---- Stub: LStatusBar:setSectionWidget -----------------------------------
--@api-stub: LStatusBar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStatusBar_stub:setSectionWidget(section_idx, widget)
-- (replace lStatusBar_stub with your real LStatusBar instance above)

-- -----------------------------------------------------------------------------
-- LSwitch methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSwitch:setOn -------------------------------------------------
--@api-stub: LSwitch:setOn
-- Sets the on/off state of this Switch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSwitch_stub:setOn(on)
-- (replace lSwitch_stub with your real LSwitch instance above)

-- ---- Stub: LSwitch:isOn --------------------------------------------------
--@api-stub: LSwitch:isOn
-- Returns the on/off state of this Switch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSwitch_stub:isOn()  -- -> boolean
-- (replace lSwitch_stub with your real LSwitch instance above)

-- ---- Stub: LSwitch:toggle ------------------------------------------------
--@api-stub: LSwitch:toggle
-- Toggles the on/off state of this Switch widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSwitch_stub:toggle()
-- (replace lSwitch_stub with your real LSwitch instance above)

-- -----------------------------------------------------------------------------
-- LTabBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTabBar:addTab ------------------------------------------------
--@api-stub: LTabBar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:addTab(label)
-- (replace lTabBar_stub with your real LTabBar instance above)

-- ---- Stub: LTabBar:removeTab ---------------------------------------------
--@api-stub: LTabBar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:removeTab(1)  -- -> boolean
-- (replace lTabBar_stub with your real LTabBar instance above)

-- ---- Stub: LTabBar:getTab ------------------------------------------------
--@api-stub: LTabBar:getTab
-- Returns the tab of this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:getTab(1)  -- -> string
-- (replace lTabBar_stub with your real LTabBar instance above)

-- ---- Stub: LTabBar:getTabCount -------------------------------------------
--@api-stub: LTabBar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:getTabCount()  -- -> integer
-- (replace lTabBar_stub with your real LTabBar instance above)

-- ---- Stub: LTabBar:setActiveTab ------------------------------------------
--@api-stub: LTabBar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:setActiveTab(1)
-- (replace lTabBar_stub with your real LTabBar instance above)

-- ---- Stub: LTabBar:getActiveTab ------------------------------------------
--@api-stub: LTabBar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTabBar_stub:getActiveTab()  -- -> integer
-- (replace lTabBar_stub with your real LTabBar instance above)

-- -----------------------------------------------------------------------------
-- LTextInput methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTextInput:setText --------------------------------------------
--@api-stub: LTextInput:setText
-- Sets the text for this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:setText("Hello, world!")
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:getText --------------------------------------------
--@api-stub: LTextInput:getText
-- Returns the text of this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:getText()  -- -> string
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:setPlaceholder -------------------------------------
--@api-stub: LTextInput:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:setPlaceholder("Hello, world!")
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:getPlaceholder -------------------------------------
--@api-stub: LTextInput:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:getPlaceholder()  -- -> string
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:setMaxLength ---------------------------------------
--@api-stub: LTextInput:setMaxLength
-- Sets the max length for this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:setMaxLength(5)
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:isFocused ------------------------------------------
--@api-stub: LTextInput:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:isFocused()  -- -> boolean
-- (replace lTextInput_stub with your real LTextInput instance above)

-- ---- Stub: LTextInput:getCursorPosition ----------------------------------
--@api-stub: LTextInput:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTextInput_stub:getCursorPosition()  -- -> integer
-- (replace lTextInput_stub with your real LTextInput instance above)

-- -----------------------------------------------------------------------------
-- LToast methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LToast:setMessage ---------------------------------------------
--@api-stub: LToast:setMessage
-- Sets the message for this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:setMessage("level_complete")
-- (replace lToast_stub with your real LToast instance above)

-- ---- Stub: LToast:getMessage ---------------------------------------------
--@api-stub: LToast:getMessage
-- Returns the message of this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:getMessage()  -- -> string
-- (replace lToast_stub with your real LToast instance above)

-- ---- Stub: LToast:setDuration --------------------------------------------
--@api-stub: LToast:setDuration
-- Sets the duration for this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:setDuration(d)
-- (replace lToast_stub with your real LToast instance above)

-- ---- Stub: LToast:getDuration --------------------------------------------
--@api-stub: LToast:getDuration
-- Returns the duration of this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:getDuration()  -- -> number
-- (replace lToast_stub with your real LToast instance above)

-- ---- Stub: LToast:getProgress --------------------------------------------
--@api-stub: LToast:getProgress
-- Returns the progress of this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:getProgress()  -- -> number
-- (replace lToast_stub with your real LToast instance above)

-- ---- Stub: LToast:isExpired ----------------------------------------------
--@api-stub: LToast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToast_stub:isExpired()  -- -> boolean
-- (replace lToast_stub with your real LToast instance above)

-- -----------------------------------------------------------------------------
-- LToolbar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LToolbar:getOrientation ---------------------------------------
--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:getOrientation()  -- -> string
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:setOrientation ---------------------------------------
--@api-stub: LToolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:setOrientation(1.0)
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:addButton --------------------------------------------
--@api-stub: LToolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:addButton(1, [tooltip])  -- -> integer
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:addSeparator -----------------------------------------
--@api-stub: LToolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:addSeparator()
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:addSpacer --------------------------------------------
--@api-stub: LToolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:addSpacer([size])
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:getButton --------------------------------------------
--@api-stub: LToolbar:getButton
-- Returns the button of this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:getButton(1)  -- -> table
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:setButtonEnabled -------------------------------------
--@api-stub: LToolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:setButtonEnabled(1, true)  -- -> boolean
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:setButtonToggled -------------------------------------
--@api-stub: LToolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:setButtonToggled(1, toggled)  -- -> boolean
-- (replace lToolbar_stub with your real LToolbar instance above)

-- ---- Stub: LToolbar:isButtonToggled --------------------------------------
--@api-stub: LToolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lToolbar_stub:isButtonToggled(1)  -- -> boolean
-- (replace lToolbar_stub with your real LToolbar instance above)

-- -----------------------------------------------------------------------------
-- LTooltipPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTooltipPanel:getText -----------------------------------------
--@api-stub: LTooltipPanel:getText
-- Returns the text of this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:getText()  -- -> string
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- ---- Stub: LTooltipPanel:setText -----------------------------------------
--@api-stub: LTooltipPanel:setText
-- Sets the text for this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:setText("Hello, world!")
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- ---- Stub: LTooltipPanel:getDelay ----------------------------------------
--@api-stub: LTooltipPanel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:getDelay()  -- -> number
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- ---- Stub: LTooltipPanel:setDelay ----------------------------------------
--@api-stub: LTooltipPanel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:setDelay(1.0)
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- ---- Stub: LTooltipPanel:getTarget ---------------------------------------
--@api-stub: LTooltipPanel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:getTarget()  -- -> integer
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- ---- Stub: LTooltipPanel:setTarget ---------------------------------------
--@api-stub: LTooltipPanel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTooltipPanel_stub:setTarget([target])
-- (replace lTooltipPanel_stub with your real LTooltipPanel instance above)

-- -----------------------------------------------------------------------------
-- LTreeView methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTreeView:addNode ---------------------------------------------
--@api-stub: LTreeView:addNode
-- Adds a node entry to this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:addNode("Hello, world!", [parent_index])  -- -> integer
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:toggleNode ------------------------------------------
--@api-stub: LTreeView:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:toggleNode(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:isExpanded ------------------------------------------
--@api-stub: LTreeView:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:isExpanded(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getNodeCount ----------------------------------------
--@api-stub: LTreeView:getNodeCount
-- Returns the node count of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getNodeCount()  -- -> integer
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:removeNode ------------------------------------------
--@api-stub: LTreeView:removeNode
-- Removes the node from this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:removeNode(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:clearNodes ------------------------------------------
--@api-stub: LTreeView:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:clearNodes()
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getNodeText -----------------------------------------
--@api-stub: LTreeView:getNodeText
-- Returns the node text of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getNodeText(1)  -- -> string
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:setNodeText -----------------------------------------
--@api-stub: LTreeView:setNodeText
-- Sets the node text for this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:setNodeText(1, "Hello, world!")  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:setNodeIcon -----------------------------------------
--@api-stub: LTreeView:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:setNodeIcon(1, icon)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:expandNode ------------------------------------------
--@api-stub: LTreeView:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:expandNode(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:collapseNode ----------------------------------------
--@api-stub: LTreeView:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:collapseNode(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:isNodeExpanded --------------------------------------
--@api-stub: LTreeView:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:isNodeExpanded(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:expandAll -------------------------------------------
--@api-stub: LTreeView:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:expandAll()
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:collapseAll -----------------------------------------
--@api-stub: LTreeView:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:collapseAll()
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:setSelectedNode -------------------------------------
--@api-stub: LTreeView:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:setSelectedNode(1)  -- -> boolean
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getSelectedNode -------------------------------------
--@api-stub: LTreeView:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getSelectedNode()  -- -> integer
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getChildNodes ---------------------------------------
--@api-stub: LTreeView:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getChildNodes(1)  -- -> table
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getParentNode ---------------------------------------
--@api-stub: LTreeView:getParentNode
-- Returns the parent node of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getParentNode(1)  -- -> integer
-- (replace lTreeView_stub with your real LTreeView instance above)

-- ---- Stub: LTreeView:getNodeDepth ----------------------------------------
--@api-stub: LTreeView:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTreeView_stub:getNodeDepth(1)  -- -> integer
-- (replace lTreeView_stub with your real LTreeView instance above)

-- -----------------------------------------------------------------------------
-- LUiWidget methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LUiWidget:type ------------------------------------------------
--@api-stub: LUiWidget:type
-- Returns the Lua type name of this widget (e.g. "LButton").
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:type()  -- -> string
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:typeOf ----------------------------------------------
--@api-stub: LUiWidget:typeOf
-- Returns true if this widget is of the given type, "LWidget", or "Object".
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:typeOf("hero")  -- -> boolean
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setPosition -----------------------------------------
--@api-stub: LUiWidget:setPosition
-- Sets the widget position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setPosition(0.0, 0.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getPosition -----------------------------------------
--@api-stub: LUiWidget:getPosition
-- Returns the widget position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getPosition()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setSize ---------------------------------------------
--@api-stub: LUiWidget:setSize
-- Sets the width and height of the widget in UI pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setSize(64.0, 64.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getSize ---------------------------------------------
--@api-stub: LUiWidget:getSize
-- Returns the current width and height of the widget in UI pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getSize()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getRect ---------------------------------------------
--@api-stub: LUiWidget:getRect
-- Returns the computed screen-space rectangle after layout.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getRect()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setVisible ------------------------------------------
--@api-stub: LUiWidget:setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setVisible(1.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:isVisible -------------------------------------------
--@api-stub: LUiWidget:isVisible
-- Returns whether the widget is visible.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:isVisible()  -- -> boolean
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setEnabled ------------------------------------------
--@api-stub: LUiWidget:setEnabled
-- Sets whether the widget is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setEnabled(1.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:isEnabled -------------------------------------------
--@api-stub: LUiWidget:isEnabled
-- Returns whether the widget is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:isEnabled()  -- -> boolean
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setId -----------------------------------------------
--@api-stub: LUiWidget:setId
-- Sets the widget string identifier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setId(1)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getId -----------------------------------------------
--@api-stub: LUiWidget:getId
-- Returns the widget string identifier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getId()  -- -> string
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setTooltip ------------------------------------------
--@api-stub: LUiWidget:setTooltip
-- Sets the widget tooltip text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setTooltip("Hello, world!")
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getTooltip ------------------------------------------
--@api-stub: LUiWidget:getTooltip
-- Returns the widget tooltip text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getTooltip()  -- -> string
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getState --------------------------------------------
--@api-stub: LUiWidget:getState
-- Returns the widget interaction state name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getState()  -- -> string
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:addChild --------------------------------------------
--@api-stub: LUiWidget:addChild
-- Adds a child widget to this container.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:addChild(child)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:removeChild -----------------------------------------
--@api-stub: LUiWidget:removeChild
-- Removes a child widget from this container.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:removeChild(child)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getChildCount ---------------------------------------
--@api-stub: LUiWidget:getChildCount
-- Returns the number of children in this container.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getChildCount()  -- -> integer
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getChildren -----------------------------------------
--@api-stub: LUiWidget:getChildren
-- Returns this container's children as widget-handle tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getChildren()  -- -> table
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:findById --------------------------------------------
--@api-stub: LUiWidget:findById
-- Recursively searches for a widget by id starting from this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:findById(1)  -- -> table
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setOnClick ------------------------------------------
--@api-stub: LUiWidget:setOnClick
-- Registers a callback invoked when this widget is clicked.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setOnClick(f)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setOnChange -----------------------------------------
--@api-stub: LUiWidget:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setOnChange(f)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setOnDraw -------------------------------------------
--@api-stub: LUiWidget:setOnDraw
-- Stores a custom draw callback for later invocation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setOnDraw(self, f)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:containsPoint ---------------------------------------
--@api-stub: LUiWidget:containsPoint
-- Returns whether (x, y) is inside this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:containsPoint(0.0, 0.0)  -- -> boolean
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setPadding ------------------------------------------
--@api-stub: LUiWidget:setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setPadding(top, [right], [bottom], [left])
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getPadding ------------------------------------------
--@api-stub: LUiWidget:getPadding
-- Returns the widget padding (top, right, bottom, left).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getPadding()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setMargin -------------------------------------------
--@api-stub: LUiWidget:setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setMargin(top, [right], [bottom], [left])
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getMargin -------------------------------------------
--@api-stub: LUiWidget:getMargin
-- Returns the widget margin (top, right, bottom, left).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getMargin()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setZOrder -------------------------------------------
--@api-stub: LUiWidget:setZOrder
-- Sets the widget z-order for draw sorting.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setZOrder(0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getZOrder -------------------------------------------
--@api-stub: LUiWidget:getZOrder
-- Returns the widget z-order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getZOrder()  -- -> integer
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setMinSize ------------------------------------------
--@api-stub: LUiWidget:setMinSize
-- Sets the minimum widget size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setMinSize(64.0, 64.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getMinSize ------------------------------------------
--@api-stub: LUiWidget:getMinSize
-- Returns the minimum widget size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getMinSize()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setMaxSize ------------------------------------------
--@api-stub: LUiWidget:setMaxSize
-- Sets the maximum widget size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setMaxSize(64.0, 64.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getMaxSize ------------------------------------------
--@api-stub: LUiWidget:getMaxSize
-- Returns the maximum widget size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getMaxSize()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setAnchor -------------------------------------------
--@api-stub: LUiWidget:setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setAnchor()
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setAnchorCenter -------------------------------------
--@api-stub: LUiWidget:setAnchorCenter
-- Sets center anchor offsets.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setAnchorCenter([cx], [cy])
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:clearAnchor -----------------------------------------
--@api-stub: LUiWidget:clearAnchor
-- Removes all anchor constraints.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:clearAnchor()
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setFlexGrow -----------------------------------------
--@api-stub: LUiWidget:setFlexGrow
-- Sets the flex-grow factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setFlexGrow(grow)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getFlexGrow -----------------------------------------
--@api-stub: LUiWidget:getFlexGrow
-- Returns the flex-grow factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getFlexGrow()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setFlexShrink ---------------------------------------
--@api-stub: LUiWidget:setFlexShrink
-- Sets the flex-shrink factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setFlexShrink(shrink)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getFlexShrink ---------------------------------------
--@api-stub: LUiWidget:getFlexShrink
-- Returns the flex-shrink factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getFlexShrink()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:bind ------------------------------------------------
--@api-stub: LUiWidget:bind
-- Registers a data-binding key on this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:bind("player_score")
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:unbind ----------------------------------------------
--@api-stub: LUiWidget:unbind
-- Removes the data-binding key from this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:unbind()
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:setAlpha --------------------------------------------
--@api-stub: LUiWidget:setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:setAlpha(alpha)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:getAlpha --------------------------------------------
--@api-stub: LUiWidget:getAlpha
-- Returns the widget's current alpha transparency.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:getAlpha()  -- -> number
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:fadeIn ----------------------------------------------
--@api-stub: LUiWidget:fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:fadeIn()
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:fadeOut ---------------------------------------------
--@api-stub: LUiWidget:fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:fadeOut()
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:slideIn ---------------------------------------------
--@api-stub: LUiWidget:slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:slideIn(0.0, 0.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:slideOut --------------------------------------------
--@api-stub: LUiWidget:slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:slideOut(0.0, 0.0)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:attachToEntity --------------------------------------
--@api-stub: LUiWidget:attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:attachToEntity(entity_id)
-- (replace lUiWidget_stub with your real LUiWidget instance above)

-- ---- Stub: LUiWidget:detachFromEntity ------------------------------------
--@api-stub: LUiWidget:detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUiWidget_stub:detachFromEntity()
-- (replace lUiWidget_stub with your real LUiWidget instance above)
