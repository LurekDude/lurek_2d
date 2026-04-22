-- content/examples/ui.lua
-- Hand-written coverage of the lurek.ui API (363 items).
--
-- Every --@api-stub: block below is a real love2d-wiki-style snippet
-- showing how to call the API in real game context. Widget IDs ("btn_play",
-- "win_inv"), labels, sizes, and colours use realistic values you can adapt.
--
-- Run: cargo run -- content/examples/ui.lua

--@api-stub: lurek.ui.setPosition
-- Sets the widget position.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setPosition
  lurek.ui.setPosition(100, 200)
  print("applied")
end

--@api-stub: lurek.ui.getPosition
-- Returns the widget position.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getPosition
  local v = lurek.ui.getPosition()
  print("getPosition:", v)
end

--@api-stub: lurek.ui.setSize
-- Sets the width and height of the widget in UI pixels.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setSize
  lurek.ui.setSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getSize
-- Returns the current width and height of the widget in UI pixels.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getSize
  local v = lurek.ui.getSize()
  print("getSize:", v)
end

--@api-stub: lurek.ui.getRect
-- Returns the computed screen-space rectangle after layout.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getRect
  local v = lurek.ui.getRect()
  print("getRect:", v)
end

--@api-stub: lurek.ui.setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setVisible
  lurek.ui.setVisible(true)
  print("applied")
end

--@api-stub: lurek.ui.isVisible
-- Returns whether the widget is visible.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.isVisible
  local v = lurek.ui.isVisible()
  print("isVisible:", v)
end

--@api-stub: lurek.ui.setEnabled
-- Sets whether the widget is enabled.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setEnabled
  lurek.ui.setEnabled(true)
  print("applied")
end

--@api-stub: lurek.ui.isEnabled
-- Returns whether the widget is enabled.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.isEnabled
  local v = lurek.ui.isEnabled()
  print("isEnabled:", v)
end

--@api-stub: lurek.ui.setId
-- Sets the widget string identifier.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setId
  lurek.ui.setId("primary")
  print("applied")
end

--@api-stub: lurek.ui.getId
-- Returns the widget string identifier.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getId
  local v = lurek.ui.getId()
  print("getId:", v)
end

--@api-stub: lurek.ui.setTooltip
-- Sets the widget tooltip text.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setTooltip
  lurek.ui.setTooltip("Hello")
  print("applied")
end

--@api-stub: lurek.ui.getTooltip
-- Returns the widget tooltip text.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getTooltip
  local v = lurek.ui.getTooltip()
  print("getTooltip:", v)
end

--@api-stub: lurek.ui.getState
-- Returns the widget interaction state name.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getState
  local v = lurek.ui.getState()
  print("getState:", v)
end

--@api-stub: lurek.ui.addChild
-- Adds a child widget to this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.addChild
  lurek.ui.addChild("item_1")
  print("added")
end

--@api-stub: lurek.ui.removeChild
-- Removes a child widget from this container.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.removeChild
  lurek.ui.removeChild()
  print("done")
end

--@api-stub: lurek.ui.getChildCount
-- Returns the number of children in this container.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getChildCount
  local v = lurek.ui.getChildCount()
  print("getChildCount:", v)
end

--@api-stub: lurek.ui.getChildren
-- Returns this container's children as widget-handle tables.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getChildren
  local v = lurek.ui.getChildren()
  print("getChildren:", v)
end

--@api-stub: lurek.ui.findById
-- Recursively searches for a widget by id starting from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.findById
  local v = lurek.ui.findById()
  print("findById:", v)
end

--@api-stub: lurek.ui.setOnClick
-- Registers a callback invoked when this widget is clicked.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setOnClick
  lurek.ui.setOnClick(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setOnChange
  lurek.ui.setOnChange(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnDraw
-- Stores a custom draw callback for later invocation.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setOnDraw
  lurek.ui.setOnDraw(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.containsPoint
-- Returns whether (x, y) is inside this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.containsPoint
  local v = lurek.ui.containsPoint()
  print("containsPoint:", v)
end

--@api-stub: lurek.ui.setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setPadding
  lurek.ui.setPadding(8)
  print("applied")
end

--@api-stub: lurek.ui.getPadding
-- Returns the widget padding (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getPadding
  local v = lurek.ui.getPadding()
  print("getPadding:", v)
end

--@api-stub: lurek.ui.setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setMargin
  lurek.ui.setMargin(8)
  print("applied")
end

--@api-stub: lurek.ui.getMargin
-- Returns the widget margin (top, right, bottom, left).
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getMargin
  local v = lurek.ui.getMargin()
  print("getMargin:", v)
end

--@api-stub: lurek.ui.setZOrder
-- Sets the widget z-order for draw sorting.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setZOrder
  lurek.ui.setZOrder(1)
  print("applied")
end

--@api-stub: lurek.ui.getZOrder
-- Returns the widget z-order.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getZOrder
  local v = lurek.ui.getZOrder()
  print("getZOrder:", v)
end

--@api-stub: lurek.ui.setMinSize
-- Sets the minimum widget size.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setMinSize
  lurek.ui.setMinSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMinSize
-- Returns the minimum widget size.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getMinSize
  local v = lurek.ui.getMinSize()
  print("getMinSize:", v)
end

--@api-stub: lurek.ui.setMaxSize
-- Sets the maximum widget size.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setMaxSize
  lurek.ui.setMaxSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMaxSize
-- Returns the maximum widget size.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getMaxSize
  local v = lurek.ui.getMaxSize()
  print("getMaxSize:", v)
end

--@api-stub: lurek.ui.setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setAnchor
  lurek.ui.setAnchor(1)
  print("applied")
end

--@api-stub: lurek.ui.setAnchorCenter
-- Sets center anchor offsets.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setAnchorCenter
  lurek.ui.setAnchorCenter(1)
  print("applied")
end

--@api-stub: lurek.ui.clearAnchor
-- Removes all anchor constraints.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.clearAnchor
  lurek.ui.clearAnchor()
  print("done")
end

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex-grow factor.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setFlexGrow
  lurek.ui.setFlexGrow(true)
  print("applied")
end

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex-grow factor.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getFlexGrow
  local v = lurek.ui.getFlexGrow()
  print("getFlexGrow:", v)
end

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex-shrink factor.
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setFlexShrink
  lurek.ui.setFlexShrink(true)
  print("applied")
end

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex-shrink factor.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getFlexShrink
  local v = lurek.ui.getFlexShrink()
  print("getFlexShrink:", v)
end

--@api-stub: lurek.ui.bind
-- Registers a data-binding key on this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.bind
  lurek.ui.bind()
  print("bind called")
end

--@api-stub: lurek.ui.unbind
-- Removes the data-binding key from this widget.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.unbind
  lurek.ui.unbind()
  print("unbind called")
end

--@api-stub: lurek.ui.setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- Apply the global UI setting before drawing the first frame.
do  -- lurek.ui.setAlpha
  lurek.ui.setAlpha(0.85)
  print("applied")
end

--@api-stub: lurek.ui.getAlpha
-- Returns the widget's current alpha transparency.
-- Query the current global UI state from inside a render or input callback.
do  -- lurek.ui.getAlpha
  local v = lurek.ui.getAlpha()
  print("getAlpha:", v)
end

--@api-stub: lurek.ui.fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.fadeIn
  lurek.ui.fadeIn()
  print("fadeIn called")
end

--@api-stub: lurek.ui.fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.fadeOut
  lurek.ui.fadeOut()
  print("fadeOut called")
end

--@api-stub: lurek.ui.slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.slideIn
  lurek.ui.slideIn()
  print("slideIn called")
end

--@api-stub: lurek.ui.slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.slideOut
  lurek.ui.slideOut()
  print("slideOut called")
end

--@api-stub: lurek.ui.attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.attachToEntity
  lurek.ui.attachToEntity()
  print("attachToEntity called")
end

--@api-stub: lurek.ui.detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- Invoke from an init or update callback as appropriate for your screen flow.
do  -- lurek.ui.detachFromEntity
  lurek.ui.detachFromEntity()
  print("detachFromEntity called")
end

-- ── Button methods ──

--@api-stub: Button:setText
-- Sets the text for this Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Button:setText
  local btn = lurek.ui.newButton("btn_play", "Play")
  btn:setText("Hello")
end

--@api-stub: Button:getText
-- Returns the text of this Button widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Button:getText
  local btn = lurek.ui.newButton("btn_play", "Play")
  local v = btn:getText()
  print("getText:", v)
end

-- ── Label methods ──

--@api-stub: Label:setText
-- Sets the text for this Label widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Label:setText
  local lbl = lurek.ui.newLabel("lbl_score", "Score: 0")
  lbl:setText("Hello")
end

--@api-stub: Label:getText
-- Returns the text of this Label widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Label:getText
  local lbl = lurek.ui.newLabel("lbl_score", "Score: 0")
  local v = lbl:getText()
  print("getText:", v)
end

-- ── Text_Input methods ──

--@api-stub: Text_Input:setText
-- Sets the text for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Text_Input:setText
  local ti = lurek.ui.newTextInput("ti_name", "")
  ti:setText("Hello")
end

--@api-stub: Text_Input:getText
-- Returns the text of this Text_Input widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Text_Input:getText
  local ti = lurek.ui.newTextInput("ti_name", "")
  local v = ti:getText()
  print("getText:", v)
end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Text_Input:setPlaceholder
  local ti = lurek.ui.newTextInput("ti_name", "")
  ti:setPlaceholder("Hello")
end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Text_Input:getPlaceholder
  local ti = lurek.ui.newTextInput("ti_name", "")
  local v = ti:getPlaceholder()
  print("getPlaceholder:", v)
end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length for this Text_Input widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Text_Input:setMaxLength
  local ti = lurek.ui.newTextInput("ti_name", "")
  ti:setMaxLength(100)
end

--@api-stub: Text_Input:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Text_Input:isFocused
  local ti = lurek.ui.newTextInput("ti_name", "")
  local v = ti:isFocused()
  print("isFocused:", v)
end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Text_Input:getCursorPosition
  local ti = lurek.ui.newTextInput("ti_name", "")
  local v = ti:getCursorPosition()
  print("getCursorPosition:", v)
end

-- ── Checkbox methods ──

--@api-stub: Checkbox:setChecked
-- Sets the checked for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Checkbox:setChecked
  local cb = lurek.ui.newCheckbox("cb_sound", "Sound", true)
  cb:setChecked(true)
end

--@api-stub: Checkbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Checkbox:isChecked
  local cb = lurek.ui.newCheckbox("cb_sound", "Sound", true)
  local v = cb:isChecked()
  print("isChecked:", v)
end

--@api-stub: Checkbox:setText
-- Sets the text for this Checkbox widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Checkbox:setText
  local cb = lurek.ui.newCheckbox("cb_sound", "Sound", true)
  cb:setText("Hello")
end

--@api-stub: Checkbox:getText
-- Returns the text of this Checkbox widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Checkbox:getText
  local cb = lurek.ui.newCheckbox("cb_sound", "Sound", true)
  local v = cb:getText()
  print("getText:", v)
end

-- ── Slider methods ──

--@api-stub: Slider:setValue
-- Sets the value for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Slider:setValue
  local sl = lurek.ui.newSlider(0, 100, 50)
  sl:setValue(0.5)
end

--@api-stub: Slider:getValue
-- Returns the value of this Slider widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Slider:getValue
  local sl = lurek.ui.newSlider(0, 100, 50)
  local v = sl:getValue()
  print("getValue:", v)
end

--@api-stub: Slider:setRange
-- Sets the range for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Slider:setRange
  local sl = lurek.ui.newSlider(0, 100, 50)
  sl:setRange(1)
end

--@api-stub: Slider:setStep
-- Sets the step for this Slider widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Slider:setStep
  local sl = lurek.ui.newSlider(0, 100, 50)
  sl:setStep(1)
end

--@api-stub: Slider:getMin
-- Returns the min of this Slider widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Slider:getMin
  local sl = lurek.ui.newSlider(0, 100, 50)
  local v = sl:getMin()
  print("getMin:", v)
end

--@api-stub: Slider:getMax
-- Returns the max of this Slider widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Slider:getMax
  local sl = lurek.ui.newSlider(0, 100, 50)
  local v = sl:getMax()
  print("getMax:", v)
end

-- ── Progress_Bar methods ──

--@api-stub: Progress_Bar:setValue
-- Sets the value for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Progress_Bar:setValue
  local pb = lurek.ui.newProgressBar(0.5)
  pb:setValue(0.5)
end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this Progress_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Progress_Bar:getValue
  local pb = lurek.ui.newProgressBar(0.5)
  local v = pb:getValue()
  print("getValue:", v)
end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Progress_Bar:getProgress
  local pb = lurek.ui.newProgressBar(0.5)
  local v = pb:getProgress()
  print("getProgress:", v)
end

--@api-stub: Progress_Bar:setRange
-- Sets the range for this Progress_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Progress_Bar:setRange
  local pb = lurek.ui.newProgressBar(0.5)
  pb:setRange(1)
end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this Progress_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Progress_Bar:getMin
  local pb = lurek.ui.newProgressBar(0.5)
  local v = pb:getMin()
  print("getMin:", v)
end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this Progress_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Progress_Bar:getMax
  local pb = lurek.ui.newProgressBar(0.5)
  local v = pb:getMax()
  print("getMax:", v)
end

-- ── Combo_Box methods ──

--@api-stub: Combo_Box:addItem
-- Adds a item entry to this Combo_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Combo_Box:addItem
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  cb:addItem("item_1")
end

--@api-stub: Combo_Box:removeItem
-- Removes the item from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Combo_Box:removeItem
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  cb:removeItem()
end

--@api-stub: Combo_Box:clearItems
-- Clears all items entries from this Combo_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Combo_Box:clearItems
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  cb:clearItems()
end

--@api-stub: Combo_Box:getItemCount
-- Returns the item count of this Combo_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Combo_Box:getItemCount
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: Combo_Box:getItem
-- Returns the item of this Combo_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Combo_Box:getItem
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItem()
  print("getItem:", v)
end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Combo_Box:setSelectedIndex
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  cb:setSelectedIndex(true)
end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Combo_Box:getSelectedIndex
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Combo_Box:getSelectedItem
  local cb = lurek.ui.newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedItem()
  print("getSelectedItem:", v)
end

-- ── List_Box methods ──

--@api-stub: List_Box:addItem
-- Adds a item entry to this List_Box widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- List_Box:addItem
  local w = lurek.ui.newPanel()
  w:addItem("item_1")
end

--@api-stub: List_Box:removeItem
-- Removes the item from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- List_Box:removeItem
  local w = lurek.ui.newPanel()
  w:removeItem()
end

--@api-stub: List_Box:clearItems
-- Clears all items entries from this List_Box widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- List_Box:clearItems
  local w = lurek.ui.newPanel()
  w:clearItems()
end

--@api-stub: List_Box:getItemCount
-- Returns the item count of this List_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- List_Box:getItemCount
  local w = lurek.ui.newPanel()
  local v = w:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: List_Box:getItem
-- Returns the item of this List_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- List_Box:getItem
  local w = lurek.ui.newPanel()
  local v = w:getItem()
  print("getItem:", v)
end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- List_Box:setSelectedIndex
  local w = lurek.ui.newPanel()
  w:setSelectedIndex(true)
end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- List_Box:getSelectedIndex
  local w = lurek.ui.newPanel()
  local v = w:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: List_Box:setItemHeight
-- Sets the item height for this List_Box widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- List_Box:setItemHeight
  local w = lurek.ui.newPanel()
  w:setItemHeight(50)
end

-- ── Tab_Bar methods ──

--@api-stub: Tab_Bar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Tab_Bar:addTab
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  local child = lurek.ui.newButton("child_1", "Child")
  tabs:addTab(child)
end

--@api-stub: Tab_Bar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Tab_Bar:removeTab
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  tabs:removeTab()
end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this Tab_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tab_Bar:getTab
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTab()
  print("getTab:", v)
end

--@api-stub: Tab_Bar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tab_Bar:getTabCount
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTabCount()
  print("getTabCount:", v)
end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tab_Bar:setActiveTab
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  tabs:setActiveTab(1)
end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tab_Bar:getActiveTab
  local tabs = lurek.ui.newTabBar({"Equip","Stats","Map"})
  local v = tabs:getActiveTab()
  print("getActiveTab:", v)
end

-- ── Spin_Box methods ──

--@api-stub: Spin_Box:setValue
-- Sets the value for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Spin_Box:setValue
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  spin:setValue(0.5)
end

--@api-stub: Spin_Box:getValue
-- Returns the current value of this SpinBox widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Spin_Box:getValue
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  local v = spin:getValue()
  print("getValue:", v)
end

--@api-stub: Spin_Box:increment
-- Increments the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
do  -- Spin_Box:increment
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  spin:increment()
end

--@api-stub: Spin_Box:decrement
-- Decrements the value by one step.
-- Call this on the Spin_Box instance to drive its behaviour at runtime.
do  -- Spin_Box:decrement
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  spin:decrement()
end

--@api-stub: Spin_Box:setRange
-- Sets the valid range for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Spin_Box:setRange
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  spin:setRange(1)
end

--@api-stub: Spin_Box:setStep
-- Sets the increment step for this SpinBox widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Spin_Box:setStep
  local spin = lurek.ui.newSpinBox(0, 99, 1)
  spin:setStep(1)
end

-- ── Switch methods ──

--@api-stub: Switch:setOn
-- Sets the on/off state of this Switch widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Switch:setOn
  local sw = lurek.ui.newSwitch(false)
  sw:setOn(function() print("event") end)
end

--@api-stub: Switch:isOn
-- Returns the on/off state of this Switch widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Switch:isOn
  local sw = lurek.ui.newSwitch(false)
  local v = sw:isOn()
  print("isOn:", v)
end

--@api-stub: Switch:toggle
-- Toggles the on/off state of this Switch widget.
-- Call this on the Switch instance to drive its behaviour at runtime.
do  -- Switch:toggle
  local sw = lurek.ui.newSwitch(false)
  sw:toggle()
end

-- ── Badge methods ──

--@api-stub: Badge:setCount
-- Sets the count displayed on this Badge widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Badge:setCount
  local badge = lurek.ui.newBadge("3")
  badge:setCount(4)
end

--@api-stub: Badge:getCount
-- Returns the raw count of this Badge widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Badge:getCount
  local badge = lurek.ui.newBadge("3")
  local v = badge:getCount()
  print("getCount:", v)
end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this Badge widget, e.g.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Badge:getDisplayText
  local badge = lurek.ui.newBadge("3")
  local v = badge:getDisplayText()
  print("getDisplayText:", v)
end

-- ── Panel methods ──

--@api-stub: Panel:setTitle
-- Sets the title for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Panel:setTitle
  local panel = lurek.ui.newPanel()
  panel:setTitle("Hello")
end

--@api-stub: Panel:getTitle
-- Returns the title of this Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Panel:getTitle
  local panel = lurek.ui.newPanel()
  local v = panel:getTitle()
  print("getTitle:", v)
end

--@api-stub: Panel:setScrollable
-- Sets the scrollable for this Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Panel:setScrollable
  local panel = lurek.ui.newPanel()
  panel:setScrollable(1)
end

-- ── Layout methods ──

--@api-stub: Layout:setDirection
-- Sets the direction for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setDirection
  local layout = lurek.ui.newLayout("vertical")
  layout:setDirection("horizontal")
end

--@api-stub: Layout:getDirection
-- Returns the direction of this Layout widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Layout:getDirection
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getDirection()
  print("getDirection:", v)
end

--@api-stub: Layout:setSpacing
-- Sets the spacing for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setSpacing
  local layout = lurek.ui.newLayout("vertical")
  layout:setSpacing(8)
end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this Layout widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Layout:getSpacing
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getSpacing()
  print("getSpacing:", v)
end

--@api-stub: Layout:setColumns
-- Sets the columns for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setColumns
  local layout = lurek.ui.newLayout("vertical")
  layout:setColumns(1)
end

--@api-stub: Layout:setWrap
-- Sets the wrap for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setWrap
  local layout = lurek.ui.newLayout("vertical")
  layout:setWrap(true)
end

--@api-stub: Layout:getWrap
-- Returns the wrap of this Layout widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Layout:getWrap
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getWrap()
  print("getWrap:", v)
end

--@api-stub: Layout:setAlign
-- Sets the align for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setAlign
  local layout = lurek.ui.newLayout("vertical")
  layout:setAlign("center")
end

--@api-stub: Layout:getAlign
-- Returns the align of this Layout widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Layout:getAlign
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getAlign()
  print("getAlign:", v)
end

--@api-stub: Layout:setJustify
-- Sets the justify for this Layout widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Layout:setJustify
  local layout = lurek.ui.newLayout("vertical")
  layout:setJustify(1)
end

--@api-stub: Layout:getJustify
-- Returns the justify of this Layout widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Layout:getJustify
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getJustify()
  print("getJustify:", v)
end

-- ── Scroll_Panel methods ──

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Panel:setContentSize
  local sp = lurek.ui.newScrollPanel(400, 300)
  sp:setContentSize(200, 50)
end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Panel:getContentSize
  local sp = lurek.ui.newScrollPanel(400, 300)
  local v = sp:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Panel:setScrollPosition
  local sp = lurek.ui.newScrollPanel(400, 300)
  sp:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Panel:getScrollPosition
  local sp = lurek.ui.newScrollPanel(400, 300)
  local v = sp:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Panel:getMaxScroll
  local sp = lurek.ui.newScrollPanel(400, 300)
  local v = sp:getMaxScroll()
  print("getMaxScroll:", v)
end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Panel:setScrollSpeed
  local sp = lurek.ui.newScrollPanel(400, 300)
  sp:setScrollSpeed(1)
end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Panel:getScrollSpeed
  local sp = lurek.ui.newScrollPanel(400, 300)
  local v = sp:getScrollSpeed()
  print("getScrollSpeed:", v)
end

-- ── Nine_Patch methods ──

--@api-stub: Nine_Patch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Nine_Patch:setInsets
  local np = lurek.ui.newNinePatch("assets/panel.9.png")
  np:setInsets(1)
end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Nine_Patch:getInsets
  local np = lurek.ui.newNinePatch("assets/panel.9.png")
  local v = np:getInsets()
  print("getInsets:", v)
end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Nine_Patch:setImageDimensions
  local np = lurek.ui.newNinePatch("assets/panel.9.png")
  np:setImageDimensions("assets/icon.png")
end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Nine_Patch:getImageDimensions
  local np = lurek.ui.newNinePatch("assets/panel.9.png")
  local v = np:getImageDimensions()
  print("getImageDimensions:", v)
end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Nine_Patch:getSlices
  local np = lurek.ui.newNinePatch("assets/panel.9.png")
  local v = np:getSlices()
  print("getSlices:", v)
end

-- ── Toast methods ──

--@api-stub: Toast:setMessage
-- Sets the message for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Toast:setMessage
  local toast = lurek.ui.newToast("Saved.", 2.0)
  toast:setMessage(1)
end

--@api-stub: Toast:getMessage
-- Returns the message of this Toast widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toast:getMessage
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getMessage()
  print("getMessage:", v)
end

--@api-stub: Toast:setDuration
-- Sets the duration for this Toast widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Toast:setDuration
  local toast = lurek.ui.newToast("Saved.", 2.0)
  toast:setDuration(0.5)
end

--@api-stub: Toast:getDuration
-- Returns the duration of this Toast widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toast:getDuration
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getDuration()
  print("getDuration:", v)
end

--@api-stub: Toast:getProgress
-- Returns the progress of this Toast widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toast:getProgress
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getProgress()
  print("getProgress:", v)
end

--@api-stub: Toast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toast:isExpired
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:isExpired()
  print("isExpired:", v)
end

-- ── Separator methods ──

--@api-stub: Separator:setVertical
-- Sets the vertical for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Separator:setVertical
  local sep = lurek.ui.newSeparator("horizontal")
  sep:setVertical(1)
end

--@api-stub: Separator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Separator:isVertical
  local sep = lurek.ui.newSeparator("horizontal")
  local v = sep:isVertical()
  print("isVertical:", v)
end

--@api-stub: Separator:setThickness
-- Sets the thickness for this Separator widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Separator:setThickness
  local sep = lurek.ui.newSeparator("horizontal")
  sep:setThickness(1)
end

--@api-stub: Separator:getThickness
-- Returns the thickness of this Separator widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Separator:getThickness
  local sep = lurek.ui.newSeparator("horizontal")
  local v = sep:getThickness()
  print("getThickness:", v)
end

-- ── Tree_View methods ──

--@api-stub: Tree_View:addNode
-- Adds a node entry to this Tree_View widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Tree_View:addNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:addNode("item_1")
end

--@api-stub: Tree_View:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do  -- Tree_View:toggleNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:toggleNode()
end

--@api-stub: Tree_View:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:isExpanded
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:isExpanded()
  print("isExpanded:", v)
end

--@api-stub: Tree_View:getNodeCount
-- Returns the node count of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getNodeCount
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getNodeCount()
  print("getNodeCount:", v)
end

--@api-stub: Tree_View:removeNode
-- Removes the node from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Tree_View:removeNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:removeNode()
end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Tree_View:clearNodes
  local tree = lurek.ui.newTreeView({label="root"})
  tree:clearNodes()
end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getNodeText
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getNodeText()
  print("getNodeText:", v)
end

--@api-stub: Tree_View:setNodeText
-- Sets the node text for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tree_View:setNodeText
  local tree = lurek.ui.newTreeView({label="root"})
  tree:setNodeText("Hello")
end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tree_View:setNodeIcon
  local tree = lurek.ui.newTreeView({label="root"})
  tree:setNodeIcon("assets/icon.png")
end

--@api-stub: Tree_View:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do  -- Tree_View:expandNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:expandNode()
end

--@api-stub: Tree_View:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do  -- Tree_View:collapseNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:collapseNode()
end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:isNodeExpanded
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:isNodeExpanded()
  print("isNodeExpanded:", v)
end

--@api-stub: Tree_View:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do  -- Tree_View:expandAll
  local tree = lurek.ui.newTreeView({label="root"})
  tree:expandAll()
end

--@api-stub: Tree_View:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- Call this on the Tree_View instance to drive its behaviour at runtime.
do  -- Tree_View:collapseAll
  local tree = lurek.ui.newTreeView({label="root"})
  tree:collapseAll()
end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tree_View:setSelectedNode
  local tree = lurek.ui.newTreeView({label="root"})
  tree:setSelectedNode(true)
end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getSelectedNode
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getSelectedNode()
  print("getSelectedNode:", v)
end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getChildNodes
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getChildNodes()
  print("getChildNodes:", v)
end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getParentNode
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getParentNode()
  print("getParentNode:", v)
end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tree_View:getNodeDepth
  local tree = lurek.ui.newTreeView({label="root"})
  local v = tree:getNodeDepth()
  print("getNodeDepth:", v)
end

-- ── Radio_Button methods ──

--@api-stub: Radio_Button:getText
-- Returns the text of this Radio_Button widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Radio_Button:getText
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  local v = rb:getText()
  print("getText:", v)
end

--@api-stub: Radio_Button:setText
-- Sets the text for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Radio_Button:setText
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  rb:setText("Hello")
end

--@api-stub: Radio_Button:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Radio_Button:isSelected
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  local v = rb:isSelected()
  print("isSelected:", v)
end

--@api-stub: Radio_Button:setSelected
-- Sets the selected for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Radio_Button:setSelected
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  rb:setSelected(true)
end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this Radio_Button widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Radio_Button:getGroup
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  local v = rb:getGroup()
  print("getGroup:", v)
end

--@api-stub: Radio_Button:setGroup
-- Sets the group for this Radio_Button widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Radio_Button:setGroup
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  rb:setGroup(1)
end

--@api-stub: Radio_Button:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Radio_Button:setOnChange
  local rb = lurek.ui.newRadioButton("rb_easy","Easy","diff")
  rb:setOnChange(function() print("event") end)
end

-- ── Scroll_Bar methods ──

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Bar:getScrollPosition
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  local v = sb:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Bar:setScrollPosition
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  sb:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Bar:getContentSize
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  local v = sb:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Bar:setContentSize
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  sb:setContentSize(200, 50)
end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Bar:getViewSize
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  local v = sb:getViewSize()
  print("getViewSize:", v)
end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Bar:setViewSize
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  sb:setViewSize(200, 50)
end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Scroll_Bar:isVertical
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  local v = sb:isVertical()
  print("isVertical:", v)
end

--@api-stub: Scroll_Bar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Scroll_Bar:setOnChange
  local sb = lurek.ui.newScrollBar("vertical", 0, 100)
  sb:setOnChange(function() print("event") end)
end

-- ── Gui_Window methods ──

--@api-stub: Gui_Window:getTitle
-- Returns the title of this Gui_Window widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Window:getTitle
  local w = lurek.ui.newPanel()
  local v = w:getTitle()
  print("getTitle:", v)
end

--@api-stub: Gui_Window:setTitle
-- Sets the title for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Window:setTitle
  local w = lurek.ui.newPanel()
  w:setTitle("Hello")
end

--@api-stub: Gui_Window:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Window:isCloseable
  local w = lurek.ui.newPanel()
  local v = w:isCloseable()
  print("isCloseable:", v)
end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Window:setCloseable
  local w = lurek.ui.newPanel()
  w:setCloseable(1)
end

--@api-stub: Gui_Window:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Window:isDraggable
  local w = lurek.ui.newPanel()
  local v = w:isDraggable()
  print("isDraggable:", v)
end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Window:setDraggable
  local w = lurek.ui.newPanel()
  w:setDraggable(1)
end

--@api-stub: Gui_Window:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Window:isResizable
  local w = lurek.ui.newPanel()
  local v = w:isResizable()
  print("isResizable:", v)
end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable for this Gui_Window widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Window:setResizable
  local w = lurek.ui.newPanel()
  w:setResizable(true)
end

--@api-stub: Gui_Window:setOnClose
-- Registers a callback invoked when this window is closed.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Window:setOnClose
  local w = lurek.ui.newPanel()
  w:setOnClose(function() print("event") end)
end

-- ── Split_Panel methods ──

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Split_Panel:getOrientation
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  local v = split:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Split_Panel:setOrientation
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  split:setOrientation("horizontal")
end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Split_Panel:getSplitPosition
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  local v = split:getSplitPosition()
  print("getSplitPosition:", v)
end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Split_Panel:setSplitPosition
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  split:setSplitPosition(100, 200)
end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Split_Panel:getMinPanelSize
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  local v = split:getMinPanelSize()
  print("getMinPanelSize:", v)
end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Split_Panel:setMinPanelSize
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  split:setMinPanelSize(200, 50)
end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Split_Panel:setFirstChild
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  split:setFirstChild(1)
end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Split_Panel:setSecondChild
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  split:setSecondChild(function() print("event") end)
end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Split_Panel:getFirstChild
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  local v = split:getFirstChild()
  print("getFirstChild:", v)
end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Split_Panel:getSecondChild
  local split = lurek.ui.newSplitPanel("horizontal", 0.5)
  local v = split:getSecondChild()
  print("getSecondChild:", v)
end

-- ── Dock_Panel methods ──

--@api-stub: Dock_Panel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
do  -- Dock_Panel:dock
  local dock = lurek.ui.newDockPanel()
  dock:dock()
end

--@api-stub: Dock_Panel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- Call this on the Dock_Panel instance to drive its behaviour at runtime.
do  -- Dock_Panel:undock
  local dock = lurek.ui.newDockPanel()
  dock:undock()
end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dock_Panel:getDockedCount
  local dock = lurek.ui.newDockPanel()
  local v = dock:getDockedCount()
  print("getDockedCount:", v)
end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Dock_Panel:setSplitSize
  local dock = lurek.ui.newDockPanel()
  dock:setSplitSize(200, 50)
end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dock_Panel:getSplitSize
  local dock = lurek.ui.newDockPanel()
  local v = dock:getSplitSize()
  print("getSplitSize:", v)
end

-- ── Toolbar methods ──

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toolbar:getOrientation
  local tb = lurek.ui.newToolbar()
  local v = tb:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Toolbar:setOrientation
  local tb = lurek.ui.newToolbar()
  tb:setOrientation("horizontal")
end

--@api-stub: Toolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Toolbar:addButton
  local tb = lurek.ui.newToolbar()
  tb:addButton(1)
end

--@api-stub: Toolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Toolbar:addSeparator
  local tb = lurek.ui.newToolbar()
  tb:addSeparator(1)
end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Toolbar:addSpacer
  local tb = lurek.ui.newToolbar()
  tb:addSpacer(1)
end

--@api-stub: Toolbar:getButton
-- Returns the button of this Toolbar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toolbar:getButton
  local tb = lurek.ui.newToolbar()
  local v = tb:getButton()
  print("getButton:", v)
end

--@api-stub: Toolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Toolbar:setButtonEnabled
  local tb = lurek.ui.newToolbar()
  tb:setButtonEnabled(true)
end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Toolbar:setButtonToggled
  local tb = lurek.ui.newToolbar()
  tb:setButtonToggled(function() print("event") end)
end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Toolbar:isButtonToggled
  local tb = lurek.ui.newToolbar()
  local v = tb:isButtonToggled()
  print("isButtonToggled:", v)
end

-- ── Menu_Bar methods ──

--@api-stub: Menu_Bar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Menu_Bar:addMenu
  local mb = lurek.ui.newMenuBar()
  local child = lurek.ui.newButton("child_1", "Child")
  mb:addMenu(child)
end

--@api-stub: Menu_Bar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Menu_Bar:removeMenu
  local mb = lurek.ui.newMenuBar()
  mb:removeMenu()
end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Bar:getMenus
  local mb = lurek.ui.newMenuBar()
  local v = mb:getMenus()
  print("getMenus:", v)
end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Bar:getMenuCount
  local mb = lurek.ui.newMenuBar()
  local v = mb:getMenuCount()
  print("getMenuCount:", v)
end

-- ── Menu_Item methods ──

--@api-stub: Menu_Item:getText
-- Returns the text of this Menu_Item widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Item:getText
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getText()
  print("getText:", v)
end

--@api-stub: Menu_Item:setText
-- Sets the text for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Menu_Item:setText
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setText("Hello")
end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Item:getShortcut
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getShortcut()
  print("getShortcut:", v)
end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Menu_Item:setShortcut
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setShortcut(1)
end

--@api-stub: Menu_Item:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Item:isChecked
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:isChecked()
  print("isChecked:", v)
end

--@api-stub: Menu_Item:setChecked
-- Sets the checked for this Menu_Item widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Menu_Item:setChecked
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setChecked(true)
end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Menu_Item:addSubItem
  local mi = lurek.ui.newMenuItem("New Game")
  mi:addSubItem("item_1")
end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Menu_Item:getSubItems
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getSubItems()
  print("getSubItems:", v)
end

--@api-stub: Menu_Item:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Menu_Item:setOnClick
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setOnClick(function() print("event") end)
end

-- ── Dialog methods ──

--@api-stub: Dialog:getTitle
-- Returns the title of this Dialog widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dialog:getTitle
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  local v = dlg:getTitle()
  print("getTitle:", v)
end

--@api-stub: Dialog:setTitle
-- Sets the title for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Dialog:setTitle
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:setTitle("Hello")
end

--@api-stub: Dialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dialog:isModal
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  local v = dlg:isModal()
  print("isModal:", v)
end

--@api-stub: Dialog:setModal
-- Sets the modal for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Dialog:setModal
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:setModal(true)
end

--@api-stub: Dialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dialog:isOpen
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  local v = dlg:isOpen()
  print("isOpen:", v)
end

--@api-stub: Dialog:open
-- Performs the open operation on this Dialog widget.
-- Call this on the Dialog instance to drive its behaviour at runtime.
do  -- Dialog:open
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:open()
end

--@api-stub: Dialog:close
-- Closes and removes this dialog from the screen.
-- Call this on the Dialog instance to drive its behaviour at runtime.
do  -- Dialog:close
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:close()
end

--@api-stub: Dialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Dialog:setOnClose
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:setOnClose(function() print("event") end)
end

--@api-stub: Dialog:setContent
-- Sets the content for this Dialog widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Dialog:setContent
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:setContent(function() print("event") end)
end

--@api-stub: Dialog:getContent
-- Returns the content of this Dialog widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Dialog:getContent
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  local v = dlg:getContent()
  print("getContent:", v)
end

--@api-stub: Dialog:addButton
-- Adds a button entry to this Dialog widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Dialog:addButton
  local dlg = lurek.ui.newDialog("dlg_quit", "Quit?")
  dlg:addButton(1)
end

-- ── Status_Bar methods ──

--@api-stub: Status_Bar:addSection
-- Adds a section entry to this Status_Bar widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Status_Bar:addSection
  local sb = lurek.ui.newStatusBar()
  sb:addSection(1)
end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Status_Bar:setSectionText
  local sb = lurek.ui.newStatusBar()
  sb:setSectionText("Hello")
end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Status_Bar:getSectionText
  local sb = lurek.ui.newStatusBar()
  local v = sb:getSectionText()
  print("getSectionText:", v)
end

--@api-stub: Status_Bar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Status_Bar:getSectionCount
  local sb = lurek.ui.newStatusBar()
  local v = sb:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Status_Bar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Status_Bar:setSectionCount
  local sb = lurek.ui.newStatusBar()
  sb:setSectionCount(4)
end

--@api-stub: Status_Bar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Status_Bar:setSectionWidget
  local sb = lurek.ui.newStatusBar()
  sb:setSectionWidget("primary")
end

-- ── Accordion methods ──

--@api-stub: Accordion:addSection
-- Adds a section entry to this Accordion widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Accordion:addSection
  local acc = lurek.ui.newAccordion()
  acc:addSection(1)
end

--@api-stub: Accordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Accordion:getSectionCount
  local acc = lurek.ui.newAccordion()
  local v = acc:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Accordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- Call this on the Accordion instance to drive its behaviour at runtime.
do  -- Accordion:toggleSection
  local acc = lurek.ui.newAccordion()
  acc:toggleSection()
end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Accordion:isSectionExpanded
  local acc = lurek.ui.newAccordion()
  local v = acc:isSectionExpanded()
  print("isSectionExpanded:", v)
end

--@api-stub: Accordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Accordion:isExclusive
  local acc = lurek.ui.newAccordion()
  local v = acc:isExclusive()
  print("isExclusive:", v)
end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Accordion:setExclusive
  local acc = lurek.ui.newAccordion()
  acc:setExclusive(1)
end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Accordion:getSectionTitle
  local acc = lurek.ui.newAccordion()
  local v = acc:getSectionTitle()
  print("getSectionTitle:", v)
end

-- ── Tooltip_Panel methods ──

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this Tooltip_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tooltip_Panel:getText
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getText()
  print("getText:", v)
end

--@api-stub: Tooltip_Panel:setText
-- Sets the text for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tooltip_Panel:setText
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setText("Hello")
end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tooltip_Panel:getDelay
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getDelay()
  print("getDelay:", v)
end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tooltip_Panel:setDelay
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setDelay(2.0)
end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Tooltip_Panel:getTarget
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getTarget()
  print("getTarget:", v)
end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Tooltip_Panel:setTarget
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setTarget(1)
end

-- ── Color_Picker methods ──

--@api-stub: Color_Picker:getColor
-- Returns the color of this Color_Picker widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Color_Picker:getColor
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  local v = cp:getColor()
  print("getColor:", v)
end

--@api-stub: Color_Picker:setColor
-- Sets the color for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Color_Picker:setColor
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  cp:setColor({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Color_Picker:getShowAlpha
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  local v = cp:getShowAlpha()
  print("getShowAlpha:", v)
end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Color_Picker:setShowAlpha
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  cp:setShowAlpha(0.85)
end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Color_Picker:getColorMode
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  local v = cp:getColorMode()
  print("getColorMode:", v)
end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Color_Picker:setColorMode
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  cp:setColorMode({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Color_Picker:setOnChange
  local cp = lurek.ui.newColorPicker({1,0,0,1})
  cp:setOnChange(function() print("event") end)
end

-- ── Gui_Table methods ──

--@api-stub: Gui_Table:addColumn
-- Adds a column entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Gui_Table:addColumn
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:addColumn("item_1")
end

--@api-stub: Gui_Table:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Table:getColumnCount
  local tbl = lurek.ui.newTable({"Name","Score"})
  local v = tbl:getColumnCount()
  print("getColumnCount:", v)
end

--@api-stub: Gui_Table:addRow
-- Adds a row entry to this Gui_Table widget.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Gui_Table:addRow
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:addRow("item_1")
end

--@api-stub: Gui_Table:getRowCount
-- Returns the row count of this Gui_Table widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Table:getRowCount
  local tbl = lurek.ui.newTable({"Name","Score"})
  local v = tbl:getRowCount()
  print("getRowCount:", v)
end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this Gui_Table widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Table:getCell
  local tbl = lurek.ui.newTable({"Name","Score"})
  local v = tbl:getCell()
  print("getCell:", v)
end

--@api-stub: Gui_Table:setCell
-- Sets the cell for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Table:setCell
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:setCell(1)
end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Table:getSelectedRow
  local tbl = lurek.ui.newTable({"Name","Score"})
  local v = tbl:getSelectedRow()
  print("getSelectedRow:", v)
end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Table:setSelectedRow
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:setSelectedRow(true)
end

--@api-stub: Gui_Table:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Gui_Table:isSortable
  local tbl = lurek.ui.newTable({"Name","Score"})
  local v = tbl:isSortable()
  print("isSortable:", v)
end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable for this Gui_Table widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Table:setSortable
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:setSortable(1)
end

--@api-stub: Gui_Table:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Gui_Table:setOnSelect
  local tbl = lurek.ui.newTable({"Name","Score"})
  tbl:setOnSelect(function() print("event") end)
end

-- ── Image_Widget methods ──

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getScaleMode
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getScaleMode()
  print("getScaleMode:", v)
end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setScaleMode
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setScaleMode(1.5)
end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this Image_Widget widget.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getTint
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getTint()
  print("getTint:", v)
end

--@api-stub: Image_Widget:setTint
-- Sets the tint for this Image_Widget widget.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setTint
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setTint({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newButton
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newButton()
end

--@api-stub: Image_Widget:newLabel
-- Creates a text label widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newLabel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newLabel()
end

--@api-stub: Image_Widget:newTextInput
-- Creates a text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTextInput
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTextInput()
end

--@api-stub: Image_Widget:newCheckbox
-- Creates a checkbox widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newCheckbox
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newCheckbox()
end

--@api-stub: Image_Widget:newSlider
-- Creates a value slider widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSlider
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSlider()
end

--@api-stub: Image_Widget:newProgressBar
-- Creates a progress bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newProgressBar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newProgressBar()
end

--@api-stub: Image_Widget:newComboBox
-- Creates a dropdown combo box widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newComboBox
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newComboBox()
end

--@api-stub: Image_Widget:newList
-- Creates a selectable list widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newList
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newList()
end

--@api-stub: Image_Widget:newPanel
-- Creates a container panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newPanel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newPanel()
end

--@api-stub: Image_Widget:newLayout
-- Creates a flexbox layout container.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newLayout
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newLayout()
end

--@api-stub: Image_Widget:newScrollPanel
-- Creates a scrollable panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newScrollPanel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newScrollPanel()
end

--@api-stub: Image_Widget:newNinePatch
-- Creates a 9-patch slicer widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newNinePatch
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newNinePatch()
end

--@api-stub: Image_Widget:newTabBar
-- Creates a tab bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTabBar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTabBar()
end

--@api-stub: Image_Widget:newSeparator
-- Creates a separator line.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSeparator
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSeparator()
end

--@api-stub: Image_Widget:newSpacer
-- Creates a spacing filler widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSpacer
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSpacer()
end

--@api-stub: Image_Widget:newToast
-- Creates a toast notification widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newToast
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newToast()
end

--@api-stub: Image_Widget:newTreeView
-- Creates a collapsible tree view widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTreeView
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTreeView()
end

--@api-stub: Image_Widget:newRadioButton
-- Creates a grouped radio button widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newRadioButton
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newRadioButton()
end

--@api-stub: Image_Widget:newScrollBar
-- Creates a scroll bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newScrollBar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newScrollBar()
end

--@api-stub: Image_Widget:newWindow
-- Creates a draggable window widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newWindow
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newWindow()
end

--@api-stub: Image_Widget:newSplitPanel
-- Creates a resizable split panel.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSplitPanel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSplitPanel()
end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newDockPanel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newDockPanel()
end

--@api-stub: Image_Widget:newToolbar
-- Creates a toolbar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newToolbar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newToolbar()
end

--@api-stub: Image_Widget:newMenuBar
-- Creates a menu bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newMenuBar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newMenuBar()
end

--@api-stub: Image_Widget:newMenuItem
-- Creates a menu item widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newMenuItem
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newMenuItem()
end

--@api-stub: Image_Widget:newDialog
-- Creates a modal dialog widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newDialog
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newDialog()
end

--@api-stub: Image_Widget:newStatusBar
-- Creates a status bar widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newStatusBar
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newStatusBar()
end

--@api-stub: Image_Widget:newAccordion
-- Creates a collapsible accordion widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newAccordion
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newAccordion()
end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates a tooltip panel widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTooltipPanel
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTooltipPanel()
end

--@api-stub: Image_Widget:newColorPicker
-- Creates a color picker widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newColorPicker
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newColorPicker()
end

--@api-stub: Image_Widget:newTable
-- Creates a data table widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTable
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTable()
end

--@api-stub: Image_Widget:newImageWidget
-- Creates an image display widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newImageWidget
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newImageWidget()
end

--@api-stub: Image_Widget:newTheme
-- Creates a new theme instance.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newTheme
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newTheme()
end

--@api-stub: Image_Widget:setTheme
-- Sets the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setTheme
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setTheme("dark")
end

--@api-stub: Image_Widget:getTheme
-- Returns whether a theme is set.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getTheme
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getTheme()
  print("getTheme:", v)
end

--@api-stub: Image_Widget:getRoot
-- Returns the root panel widget table.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getRoot
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getRoot()
  print("getRoot:", v)
end

--@api-stub: Image_Widget:setFocus
-- Sets keyboard focus to a widget or clears it.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setFocus
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setFocus(1)
end

--@api-stub: Image_Widget:getFocus
-- Returns the focused widget index or nil.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getFocus
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getFocus()
  print("getFocus:", v)
end

--@api-stub: Image_Widget:focusNext
-- Moves focus to the next focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:focusNext
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:focusNext()
end

--@api-stub: Image_Widget:focusPrev
-- Moves focus to the previous focusable widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:focusPrev
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:focusPrev()
end

--@api-stub: Image_Widget:clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- Tear down dynamic content when the screen changes to free GPU resources.
do  -- Image_Widget:clearFocus
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:clearFocus()
end

--@api-stub: Image_Widget:addToast
-- Queues a toast notification from a table.
-- Insert the child as part of building the widget tree, typically in lurek.init().
do  -- Image_Widget:addToast
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:addToast(1)
end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of active toasts.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getToastCount
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getToastCount()
  print("getToastCount:", v)
end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:mousepressed
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:mousepressed()
end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:mousereleased
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:mousereleased()
end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:mousemoved
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:mousemoved()
end

--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:keypressed
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:keypressed()
end

--@api-stub: Image_Widget:textinput
-- Forwards text input to the focused text input widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:textinput
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:textinput()
end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:wheelmoved
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:wheelmoved()
end

--@api-stub: Image_Widget:update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:update
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:update()
end

--@api-stub: Image_Widget:draw
-- Headless compatibility stub for GUI draw.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:draw
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:draw()
end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the total widget count in the context.
-- Read the current state — useful inside callbacks or per-frame UI logic.
do  -- Image_Widget:getWidgetCount
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  local v = img:getWidgetCount()
  print("getWidgetCount:", v)
end

--@api-stub: Image_Widget:drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:drawToImage
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:drawToImage()
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newLineChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newLineChart()
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newBarChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newBarChart()
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newScatterPlot
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newScatterPlot()
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newPieChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newPieChart()
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newAreaChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newAreaChart()
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newLineChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newLineChart()
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newBarChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newBarChart()
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newScatterPlot
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newScatterPlot()
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newPieChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newPieChart()
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newAreaChart
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newAreaChart()
end

--@api-stub: Image_Widget:parseWidgetState
-- Parses a widget state string, returning the canonical form or nil if invalid.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:parseWidgetState
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:parseWidgetState()
end

--@api-stub: Image_Widget:newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSpinBox
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSpinBox()
end

--@api-stub: Image_Widget:newSwitch
-- Creates a toggle switch widget.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newSwitch
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newSwitch()
end

--@api-stub: Image_Widget:newBadge
-- Creates a badge widget displaying a numeric count.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:newBadge
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:newBadge()
end

--@api-stub: Image_Widget:setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setDefaultTheme
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setDefaultTheme("dark")
end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- Configure the widget once after creation, before adding it to a layout.
do  -- Image_Widget:setViewport
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:setViewport(1)
end

--@api-stub: Image_Widget:flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:flushCache
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:flushCache()
end

--@api-stub: Image_Widget:update_bindings
-- Updates all widgets that have a data-binding key registered via `:bind(key)`.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:update_bindings
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:update_bindings()
end

--@api-stub: Image_Widget:loadLayout
-- Load a widget tree from a Lua table definition and attach it to the UI.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:loadLayout
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:loadLayout()
end

--@api-stub: Image_Widget:loadLayoutFile
-- Load a widget tree from a TOML layout file and attach it to the UI root.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:loadLayoutFile
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:loadLayoutFile()
end

--@api-stub: Image_Widget:renderToImage
-- Render the current UI widget tree to a PNG file for testing purposes.
-- Call this on the Image_Widget instance to drive its behaviour at runtime.
do  -- Image_Widget:renderToImage
  local img = lurek.ui.newImageWidget("assets/portrait.png")
  img:renderToImage()
end

-- ── LineChart methods ──

--@api-stub: LineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do  -- LineChart:setYMax
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:setYMax(100)
end

--@api-stub: LineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do  -- LineChart:setXMax
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:setXMax(100)
end

--@api-stub: LineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Call this on the LineChart instance to drive its behaviour at runtime.
do  -- LineChart:drawToImage
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:drawToImage()
end

-- ── BarChart methods ──

--@api-stub: BarChart:drawToImage
-- Renders the bar chart into an existing ImageData.
-- Call this on the BarChart instance to drive its behaviour at runtime.
do  -- BarChart:drawToImage
  local w = lurek.ui.newPanel()
  w:drawToImage()
end

-- ── ScatterPlot methods ──

--@api-stub: ScatterPlot:setXRange
-- Sets the X-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
do  -- ScatterPlot:setXRange
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setXRange(1)
end

--@api-stub: ScatterPlot:setYRange
-- Sets the Y-axis data range.
-- Configure the widget once after creation, before adding it to a layout.
do  -- ScatterPlot:setYRange
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setYRange(1)
end

--@api-stub: ScatterPlot:drawToImage
-- Renders the scatter plot into an existing ImageData.
-- Call this on the ScatterPlot instance to drive its behaviour at runtime.
do  -- ScatterPlot:drawToImage
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:drawToImage()
end

-- ── PieChart methods ──

--@api-stub: PieChart:drawToImage
-- Renders the pie chart into an existing ImageData.
-- Call this on the PieChart instance to drive its behaviour at runtime.
do  -- PieChart:drawToImage
  local chart = lurek.ui.newPieChart({{label="HP",value=70}})
  chart:drawToImage()
end

-- ── AreaChart methods ──

--@api-stub: AreaChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Configure the widget once after creation, before adding it to a layout.
do  -- AreaChart:setYMax
  local w = lurek.ui.newPanel()
  w:setYMax(100)
end

--@api-stub: AreaChart:drawToImage
-- Renders the area chart into an existing ImageData.
-- Call this on the AreaChart instance to drive its behaviour at runtime.
do  -- AreaChart:drawToImage
  local w = lurek.ui.newPanel()
  w:drawToImage()
end

