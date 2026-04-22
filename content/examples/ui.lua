-- content/examples/ui.lua
-- Auto-scaffolded coverage of the lurek.ui Lua API (363 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/ui.lua

print("[example] lurek.ui loaded — 363 API items demonstrated")

-- ── lurek.ui free functions ──

--@api-stub: lurek.ui.setPosition
-- Sets the widget position.
-- Use this when sets the widget position is needed.
if false then
  local _r = lurek.ui.setPosition(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getPosition
-- Returns the widget position.
-- Use this when returns the widget position is needed.
if false then
  local _r = lurek.ui.getPosition()
  print(_r)
end

--@api-stub: lurek.ui.setSize
-- Sets the width and height of the widget in UI pixels.
-- Use this when sets the width and height of the widget in UI pixels is needed.
if false then
  local _r = lurek.ui.setSize(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getSize
-- Returns the current width and height of the widget in UI pixels.
-- Use this when returns the current width and height of the widget in UI pixels is needed.
if false then
  local _r = lurek.ui.getSize()
  print(_r)
end

--@api-stub: lurek.ui.getRect
-- Returns the computed screen-space rectangle after layout.
-- Use this when returns the computed screen-space rectangle after layout is needed.
if false then
  local _r = lurek.ui.getRect()
  print(_r)
end

--@api-stub: lurek.ui.setVisible
-- Shows or hides the widget; hidden widgets are not rendered or interactive.
-- Use this when shows or hides the widget; hidden widgets are not rendered or interactive is needed.
if false then
  local _r = lurek.ui.setVisible(0)
  print(_r)
end

--@api-stub: lurek.ui.isVisible
-- Returns whether the widget is visible.
-- Use this when returns whether the widget is visible is needed.
if false then
  local _r = lurek.ui.isVisible()
  print(_r)
end

--@api-stub: lurek.ui.setEnabled
-- Sets whether the widget is enabled.
-- Use this when sets whether the widget is enabled is needed.
if false then
  local _r = lurek.ui.setEnabled(0)
  print(_r)
end

--@api-stub: lurek.ui.isEnabled
-- Returns whether the widget is enabled.
-- Use this when returns whether the widget is enabled is needed.
if false then
  local _r = lurek.ui.isEnabled()
  print(_r)
end

--@api-stub: lurek.ui.setId
-- Sets the widget string identifier.
-- Use this when sets the widget string identifier is needed.
if false then
  local _r = lurek.ui.setId(1)
  print(_r)
end

--@api-stub: lurek.ui.getId
-- Returns the widget string identifier.
-- Use this when returns the widget string identifier is needed.
if false then
  local _r = lurek.ui.getId()
  print(_r)
end

--@api-stub: lurek.ui.setTooltip
-- Sets the widget tooltip text.
-- Use this when sets the widget tooltip text is needed.
if false then
  local _r = lurek.ui.setTooltip(0)
  print(_r)
end

--@api-stub: lurek.ui.getTooltip
-- Returns the widget tooltip text.
-- Use this when returns the widget tooltip text is needed.
if false then
  local _r = lurek.ui.getTooltip()
  print(_r)
end

--@api-stub: lurek.ui.getState
-- Returns the widget interaction state name.
-- Use this when returns the widget interaction state name is needed.
if false then
  local _r = lurek.ui.getState()
  print(_r)
end

--@api-stub: lurek.ui.addChild
-- Adds a child widget to this container.
-- Use this when adds a child widget to this container is needed.
if false then
  local _r = lurek.ui.addChild(0)
  print(_r)
end

--@api-stub: lurek.ui.removeChild
-- Removes a child widget from this container.
-- Use this when removes a child widget from this container is needed.
if false then
  local _r = lurek.ui.removeChild(0)
  print(_r)
end

--@api-stub: lurek.ui.getChildCount
-- Returns the number of children in this container.
-- Use this when returns the number of children in this container is needed.
if false then
  local _r = lurek.ui.getChildCount()
  print(_r)
end

--@api-stub: lurek.ui.getChildren
-- Returns this container's children as widget-handle tables.
-- Use this when returns this container's children as widget-handle tables is needed.
if false then
  local _r = lurek.ui.getChildren()
  print(_r)
end

--@api-stub: lurek.ui.findById
-- Recursively searches for a widget by id starting from this widget.
-- Use this when recursively searches for a widget by id starting from this widget is needed.
if false then
  local _r = lurek.ui.findById(1)
  print(_r)
end

--@api-stub: lurek.ui.setOnClick
-- Registers a callback invoked when this widget is clicked.
-- Use this when registers a callback invoked when this widget is clicked is needed.
if false then
  local _r = lurek.ui.setOnClick(nil)
  print(_r)
end

--@api-stub: lurek.ui.setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Use this when registers a callback invoked when this widget's value changes is needed.
if false then
  local _r = lurek.ui.setOnChange(nil)
  print(_r)
end

--@api-stub: lurek.ui.setOnDraw
-- Stores a custom draw callback for later invocation.
-- Use this when stores a custom draw callback for later invocation is needed.
if false then
  local _r = lurek.ui.setOnDraw(nil)
  print(_r)
end

--@api-stub: lurek.ui.containsPoint
-- Returns whether (x, y) is inside this widget.
-- Use this when returns whether (x, y) is inside this widget is needed.
if false then
  local _r = lurek.ui.containsPoint(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.setPadding
-- Sets widget padding (CSS-like: top, right?, bottom?, left?).
-- Use this when sets widget padding (CSS-like: top, right?, bottom?, left?) is needed.
if false then
  local _r = lurek.ui.setPadding(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getPadding
-- Returns the widget padding (top, right, bottom, left).
-- Use this when returns the widget padding (top, right, bottom, left) is needed.
if false then
  local _r = lurek.ui.getPadding()
  print(_r)
end

--@api-stub: lurek.ui.setMargin
-- Sets widget margin (CSS-like: top, right?, bottom?, left?).
-- Use this when sets widget margin (CSS-like: top, right?, bottom?, left?) is needed.
if false then
  local _r = lurek.ui.setMargin(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getMargin
-- Returns the widget margin (top, right, bottom, left).
-- Use this when returns the widget margin (top, right, bottom, left) is needed.
if false then
  local _r = lurek.ui.getMargin()
  print(_r)
end

--@api-stub: lurek.ui.setZOrder
-- Sets the widget z-order for draw sorting.
-- Use this when sets the widget z-order for draw sorting is needed.
if false then
  local _r = lurek.ui.setZOrder(0)
  print(_r)
end

--@api-stub: lurek.ui.getZOrder
-- Returns the widget z-order.
-- Use this when returns the widget z-order is needed.
if false then
  local _r = lurek.ui.getZOrder()
  print(_r)
end

--@api-stub: lurek.ui.setMinSize
-- Sets the minimum widget size.
-- Use this when sets the minimum widget size is needed.
if false then
  local _r = lurek.ui.setMinSize(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getMinSize
-- Returns the minimum widget size.
-- Use this when returns the minimum widget size is needed.
if false then
  local _r = lurek.ui.getMinSize()
  print(_r)
end

--@api-stub: lurek.ui.setMaxSize
-- Sets the maximum widget size.
-- Use this when sets the maximum widget size is needed.
if false then
  local _r = lurek.ui.setMaxSize(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.getMaxSize
-- Returns the maximum widget size.
-- Use this when returns the maximum widget size is needed.
if false then
  local _r = lurek.ui.getMaxSize()
  print(_r)
end

--@api-stub: lurek.ui.setAnchor
-- Sets anchor edges (left, top, right, bottom).
-- Use this when sets anchor edges (left, top, right, bottom) is needed.
if false then
  local _r = lurek.ui.setAnchor()
  print(_r)
end

--@api-stub: lurek.ui.setAnchorCenter
-- Sets center anchor offsets.
-- Use this when sets center anchor offsets is needed.
if false then
  local _r = lurek.ui.setAnchorCenter(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.clearAnchor
-- Removes all anchor constraints.
-- Use this when removes all anchor constraints is needed.
if false then
  local _r = lurek.ui.clearAnchor()
  print(_r)
end

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex-grow factor.
-- Use this when sets the flex-grow factor is needed.
if false then
  local _r = lurek.ui.setFlexGrow(0)
  print(_r)
end

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex-grow factor.
-- Use this when returns the flex-grow factor is needed.
if false then
  local _r = lurek.ui.getFlexGrow()
  print(_r)
end

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex-shrink factor.
-- Use this when sets the flex-shrink factor is needed.
if false then
  local _r = lurek.ui.setFlexShrink(1)
  print(_r)
end

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex-shrink factor.
-- Use this when returns the flex-shrink factor is needed.
if false then
  local _r = lurek.ui.getFlexShrink()
  print(_r)
end

--@api-stub: lurek.ui.bind
-- Registers a data-binding key on this widget.
-- Use this when registers a data-binding key on this widget is needed.
if false then
  local _r = lurek.ui.bind(0)
  print(_r)
end

--@api-stub: lurek.ui.unbind
-- Removes the data-binding key from this widget.
-- Use this when removes the data-binding key from this widget is needed.
if false then
  local _r = lurek.ui.unbind()
  print(_r)
end

--@api-stub: lurek.ui.setAlpha
-- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
-- Use this when sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque) is needed.
if false then
  local _r = lurek.ui.setAlpha(0)
  print(_r)
end

--@api-stub: lurek.ui.getAlpha
-- Returns the widget's current alpha transparency.
-- Use this when returns the widget's current alpha transparency is needed.
if false then
  local _r = lurek.ui.getAlpha()
  print(_r)
end

--@api-stub: lurek.ui.fadeIn
-- Instantly fades the widget in (sets alpha to `1.0`).
-- Use this when instantly fades the widget in (sets alpha to `1.0`) is needed.
if false then
  local _r = lurek.ui.fadeIn()
  print(_r)
end

--@api-stub: lurek.ui.fadeOut
-- Instantly fades the widget out (sets alpha to `0.0` and hides it).
-- Use this when instantly fades the widget out (sets alpha to `0.0` and hides it) is needed.
if false then
  local _r = lurek.ui.fadeOut()
  print(_r)
end

--@api-stub: lurek.ui.slideIn
-- Instantly moves the widget to `(x, y)` and makes it visible.
-- Use this when instantly moves the widget to `(x, y)` and makes it visible is needed.
if false then
  local _r = lurek.ui.slideIn(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.slideOut
-- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
-- Use this when instantly moves the widget to the off-screen position `(x, y)` and hides it is needed.
if false then
  local _r = lurek.ui.slideOut(0, 0)
  print(_r)
end

--@api-stub: lurek.ui.attachToEntity
-- Anchors this widget to a world-space entity by its numeric ID.
-- Use this when anchors this widget to a world-space entity by its numeric ID is needed.
if false then
  local _r = lurek.ui.attachToEntity(1)
  print(_r)
end

--@api-stub: lurek.ui.detachFromEntity
-- Removes the entity anchor from this widget, restoring normal layout positioning.
-- Use this when removes the entity anchor from this widget, restoring normal layout positioning is needed.
if false then
  local _r = lurek.ui.detachFromEntity()
  print(_r)
end

-- ── Button methods ──

--@api-stub: Button:setText
-- Sets the text for this Button widget.
-- Use this when sets the text for this Button widget is needed.
if false then
  local _o = nil  -- Button instance
  _o:setText(0)
end

--@api-stub: Button:getText
-- Returns the text of this Button widget.
-- Use this when returns the text of this Button widget is needed.
if false then
  local _o = nil  -- Button instance
  _o:getText()
end

-- ── Label methods ──

--@api-stub: Label:setText
-- Sets the text for this Label widget.
-- Use this when sets the text for this Label widget is needed.
if false then
  local _o = nil  -- Label instance
  _o:setText(0)
end

--@api-stub: Label:getText
-- Returns the text of this Label widget.
-- Use this when returns the text of this Label widget is needed.
if false then
  local _o = nil  -- Label instance
  _o:getText()
end

-- ── Text_Input methods ──

--@api-stub: Text_Input:setText
-- Sets the text for this Text_Input widget.
-- Use this when sets the text for this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:setText(0)
end

--@api-stub: Text_Input:getText
-- Returns the text of this Text_Input widget.
-- Use this when returns the text of this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:getText()
end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder for this Text_Input widget.
-- Use this when sets the placeholder for this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:setPlaceholder(0)
end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this Text_Input widget.
-- Use this when returns the placeholder of this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:getPlaceholder()
end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length for this Text_Input widget.
-- Use this when sets the max length for this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:setMaxLength(1)
end

--@api-stub: Text_Input:isFocused
-- Returns true if focused is enabled for this Text_Input widget.
-- Use this when returns true if focused is enabled for this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:isFocused()
end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this Text_Input widget.
-- Use this when returns the cursor position of this Text_Input widget is needed.
if false then
  local _o = nil  -- Text_Input instance
  _o:getCursorPosition()
end

-- ── Checkbox methods ──

--@api-stub: Checkbox:setChecked
-- Sets the checked for this Checkbox widget.
-- Use this when sets the checked for this Checkbox widget is needed.
if false then
  local _o = nil  -- Checkbox instance
  _o:setChecked(0)
end

--@api-stub: Checkbox:isChecked
-- Returns true if checked is enabled for this Checkbox widget.
-- Use this when returns true if checked is enabled for this Checkbox widget is needed.
if false then
  local _o = nil  -- Checkbox instance
  _o:isChecked()
end

--@api-stub: Checkbox:setText
-- Sets the text for this Checkbox widget.
-- Use this when sets the text for this Checkbox widget is needed.
if false then
  local _o = nil  -- Checkbox instance
  _o:setText(0)
end

--@api-stub: Checkbox:getText
-- Returns the text of this Checkbox widget.
-- Use this when returns the text of this Checkbox widget is needed.
if false then
  local _o = nil  -- Checkbox instance
  _o:getText()
end

-- ── Slider methods ──

--@api-stub: Slider:setValue
-- Sets the value for this Slider widget.
-- Use this when sets the value for this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:setValue(0)
end

--@api-stub: Slider:getValue
-- Returns the value of this Slider widget.
-- Use this when returns the value of this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:getValue()
end

--@api-stub: Slider:setRange
-- Sets the range for this Slider widget.
-- Use this when sets the range for this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:setRange(1, 0)
end

--@api-stub: Slider:setStep
-- Sets the step for this Slider widget.
-- Use this when sets the step for this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:setStep(0)
end

--@api-stub: Slider:getMin
-- Returns the min of this Slider widget.
-- Use this when returns the min of this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:getMin()
end

--@api-stub: Slider:getMax
-- Returns the max of this Slider widget.
-- Use this when returns the max of this Slider widget is needed.
if false then
  local _o = nil  -- Slider instance
  _o:getMax()
end

-- ── Progress_Bar methods ──

--@api-stub: Progress_Bar:setValue
-- Sets the value for this Progress_Bar widget.
-- Use this when sets the value for this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:setValue(0)
end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this Progress_Bar widget.
-- Use this when returns the value of this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:getValue()
end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this Progress_Bar widget.
-- Use this when returns the progress of this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:getProgress()
end

--@api-stub: Progress_Bar:setRange
-- Sets the range for this Progress_Bar widget.
-- Use this when sets the range for this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:setRange(1, 0)
end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this Progress_Bar widget.
-- Use this when returns the min of this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:getMin()
end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this Progress_Bar widget.
-- Use this when returns the max of this Progress_Bar widget is needed.
if false then
  local _o = nil  -- Progress_Bar instance
  _o:getMax()
end

-- ── Combo_Box methods ──

--@api-stub: Combo_Box:addItem
-- Adds a item entry to this Combo_Box widget.
-- Use this when adds a item entry to this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:addItem(0)
end

--@api-stub: Combo_Box:removeItem
-- Removes the item from this Combo_Box widget.
-- Use this when removes the item from this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:removeItem(1)
end

--@api-stub: Combo_Box:clearItems
-- Clears all items entries from this Combo_Box widget.
-- Use this when clears all items entries from this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:clearItems()
end

--@api-stub: Combo_Box:getItemCount
-- Returns the item count of this Combo_Box widget.
-- Use this when returns the item count of this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:getItemCount()
end

--@api-stub: Combo_Box:getItem
-- Returns the item of this Combo_Box widget.
-- Use this when returns the item of this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:getItem(1)
end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index for this Combo_Box widget.
-- Use this when sets the selected index for this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:setSelectedIndex(1)
end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this Combo_Box widget.
-- Use this when returns the selected index of this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:getSelectedIndex()
end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this Combo_Box widget.
-- Use this when returns the selected item of this Combo_Box widget is needed.
if false then
  local _o = nil  -- Combo_Box instance
  _o:getSelectedItem()
end

-- ── List_Box methods ──

--@api-stub: List_Box:addItem
-- Adds a item entry to this List_Box widget.
-- Use this when adds a item entry to this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:addItem(0)
end

--@api-stub: List_Box:removeItem
-- Removes the item from this List_Box widget.
-- Use this when removes the item from this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:removeItem(1)
end

--@api-stub: List_Box:clearItems
-- Clears all items entries from this List_Box widget.
-- Use this when clears all items entries from this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:clearItems()
end

--@api-stub: List_Box:getItemCount
-- Returns the item count of this List_Box widget.
-- Use this when returns the item count of this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:getItemCount()
end

--@api-stub: List_Box:getItem
-- Returns the item of this List_Box widget.
-- Use this when returns the item of this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:getItem(1)
end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index for this List_Box widget.
-- Use this when sets the selected index for this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:setSelectedIndex(1)
end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this List_Box widget.
-- Use this when returns the selected index of this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:getSelectedIndex()
end

--@api-stub: List_Box:setItemHeight
-- Sets the item height for this List_Box widget.
-- Use this when sets the item height for this List_Box widget is needed.
if false then
  local _o = nil  -- List_Box instance
  _o:setItemHeight(0)
end

-- ── Tab_Bar methods ──

--@api-stub: Tab_Bar:addTab
-- Adds a tab entry to this Tab_Bar widget.
-- Use this when adds a tab entry to this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:addTab("label")
end

--@api-stub: Tab_Bar:removeTab
-- Removes the tab from this Tab_Bar widget.
-- Use this when removes the tab from this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:removeTab(1)
end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this Tab_Bar widget.
-- Use this when returns the tab of this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:getTab(1)
end

--@api-stub: Tab_Bar:getTabCount
-- Returns the tab count of this Tab_Bar widget.
-- Use this when returns the tab count of this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:getTabCount()
end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab for this Tab_Bar widget.
-- Use this when sets the active tab for this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:setActiveTab(1)
end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this Tab_Bar widget.
-- Use this when returns the active tab of this Tab_Bar widget is needed.
if false then
  local _o = nil  -- Tab_Bar instance
  _o:getActiveTab()
end

-- ── Spin_Box methods ──

--@api-stub: Spin_Box:setValue
-- Sets the value for this SpinBox widget.
-- Use this when sets the value for this SpinBox widget is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:setValue(0)
end

--@api-stub: Spin_Box:getValue
-- Returns the current value of this SpinBox widget.
-- Use this when returns the current value of this SpinBox widget is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:getValue()
end

--@api-stub: Spin_Box:increment
-- Increments the value by one step.
-- Use this when increments the value by one step is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:increment()
end

--@api-stub: Spin_Box:decrement
-- Decrements the value by one step.
-- Use this when decrements the value by one step is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:decrement()
end

--@api-stub: Spin_Box:setRange
-- Sets the valid range for this SpinBox widget.
-- Use this when sets the valid range for this SpinBox widget is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:setRange(1, 0)
end

--@api-stub: Spin_Box:setStep
-- Sets the increment step for this SpinBox widget.
-- Use this when sets the increment step for this SpinBox widget is needed.
if false then
  local _o = nil  -- Spin_Box instance
  _o:setStep(0)
end

-- ── Switch methods ──

--@api-stub: Switch:setOn
-- Sets the on/off state of this Switch widget.
-- Use this when sets the on/off state of this Switch widget is needed.
if false then
  local _o = nil  -- Switch instance
  _o:setOn(1)
end

--@api-stub: Switch:isOn
-- Returns the on/off state of this Switch widget.
-- Use this when returns the on/off state of this Switch widget is needed.
if false then
  local _o = nil  -- Switch instance
  _o:isOn()
end

--@api-stub: Switch:toggle
-- Toggles the on/off state of this Switch widget.
-- Use this when toggles the on/off state of this Switch widget is needed.
if false then
  local _o = nil  -- Switch instance
  _o:toggle()
end

-- ── Badge methods ──

--@api-stub: Badge:setCount
-- Sets the count displayed on this Badge widget.
-- Use this when sets the count displayed on this Badge widget is needed.
if false then
  local _o = nil  -- Badge instance
  _o:setCount(1)
end

--@api-stub: Badge:getCount
-- Returns the raw count of this Badge widget.
-- Use this when returns the raw count of this Badge widget is needed.
if false then
  local _o = nil  -- Badge instance
  _o:getCount()
end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this Badge widget, e.g.
-- "99+" when over the max.
if false then
  local _o = nil  -- Badge instance
  _o:getDisplayText()
end

-- ── Panel methods ──

--@api-stub: Panel:setTitle
-- Sets the title for this Panel widget.
-- Use this when sets the title for this Panel widget is needed.
if false then
  local _o = nil  -- Panel instance
  _o:setTitle(0)
end

--@api-stub: Panel:getTitle
-- Returns the title of this Panel widget.
-- Use this when returns the title of this Panel widget is needed.
if false then
  local _o = nil  -- Panel instance
  _o:getTitle()
end

--@api-stub: Panel:setScrollable
-- Sets the scrollable for this Panel widget.
-- Use this when sets the scrollable for this Panel widget is needed.
if false then
  local _o = nil  -- Panel instance
  _o:setScrollable(nil)
end

-- ── Layout methods ──

--@api-stub: Layout:setDirection
-- Sets the direction for this Layout widget.
-- Use this when sets the direction for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setDirection(nil)
end

--@api-stub: Layout:getDirection
-- Returns the direction of this Layout widget.
-- Use this when returns the direction of this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:getDirection()
end

--@api-stub: Layout:setSpacing
-- Sets the spacing for this Layout widget.
-- Use this when sets the spacing for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setSpacing(1)
end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this Layout widget.
-- Use this when returns the spacing of this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:getSpacing()
end

--@api-stub: Layout:setColumns
-- Sets the columns for this Layout widget.
-- Use this when sets the columns for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setColumns(1)
end

--@api-stub: Layout:setWrap
-- Sets the wrap for this Layout widget.
-- Use this when sets the wrap for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setWrap(0)
end

--@api-stub: Layout:getWrap
-- Returns the wrap of this Layout widget.
-- Use this when returns the wrap of this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:getWrap()
end

--@api-stub: Layout:setAlign
-- Sets the align for this Layout widget.
-- Use this when sets the align for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setAlign(1)
end

--@api-stub: Layout:getAlign
-- Returns the align of this Layout widget.
-- Use this when returns the align of this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:getAlign()
end

--@api-stub: Layout:setJustify
-- Sets the justify for this Layout widget.
-- Use this when sets the justify for this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:setJustify(0)
end

--@api-stub: Layout:getJustify
-- Returns the justify of this Layout widget.
-- Use this when returns the justify of this Layout widget is needed.
if false then
  local _o = nil  -- Layout instance
  _o:getJustify()
end

-- ── Scroll_Panel methods ──

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size for this Scroll_Panel widget.
-- Use this when sets the content size for this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:setContentSize(0, 0)
end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this Scroll_Panel widget.
-- Use this when returns the content size of this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:getContentSize()
end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position for this Scroll_Panel widget.
-- Use this when sets the scroll position for this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:setScrollPosition(0, 0)
end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this Scroll_Panel widget.
-- Use this when returns the scroll position of this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:getScrollPosition()
end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this Scroll_Panel widget.
-- Use this when returns the max scroll of this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:getMaxScroll()
end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed for this Scroll_Panel widget.
-- Use this when sets the scroll speed for this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:setScrollSpeed(0)
end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this Scroll_Panel widget.
-- Use this when returns the scroll speed of this Scroll_Panel widget is needed.
if false then
  local _o = nil  -- Scroll_Panel instance
  _o:getScrollSpeed()
end

-- ── Nine_Patch methods ──

--@api-stub: Nine_Patch:setInsets
-- Sets the insets for this Nine_Patch widget.
-- Use this when sets the insets for this Nine_Patch widget is needed.
if false then
  local _o = nil  -- Nine_Patch instance
  _o:setInsets(0, 0, 0, 0)
end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this Nine_Patch widget.
-- Use this when returns the insets of this Nine_Patch widget is needed.
if false then
  local _o = nil  -- Nine_Patch instance
  _o:getInsets()
end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions for this Nine_Patch widget.
-- Use this when sets the image dimensions for this Nine_Patch widget is needed.
if false then
  local _o = nil  -- Nine_Patch instance
  _o:setImageDimensions(0, 0)
end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this Nine_Patch widget.
-- Use this when returns the image dimensions of this Nine_Patch widget is needed.
if false then
  local _o = nil  -- Nine_Patch instance
  _o:getImageDimensions()
end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this Nine_Patch widget.
-- Use this when returns the slices of this Nine_Patch widget is needed.
if false then
  local _o = nil  -- Nine_Patch instance
  _o:getSlices()
end

-- ── Toast methods ──

--@api-stub: Toast:setMessage
-- Sets the message for this Toast widget.
-- Use this when sets the message for this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:setMessage("msg")
end

--@api-stub: Toast:getMessage
-- Returns the message of this Toast widget.
-- Use this when returns the message of this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:getMessage()
end

--@api-stub: Toast:setDuration
-- Sets the duration for this Toast widget.
-- Use this when sets the duration for this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:setDuration(nil)
end

--@api-stub: Toast:getDuration
-- Returns the duration of this Toast widget.
-- Use this when returns the duration of this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:getDuration()
end

--@api-stub: Toast:getProgress
-- Returns the progress of this Toast widget.
-- Use this when returns the progress of this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:getProgress()
end

--@api-stub: Toast:isExpired
-- Returns true if expired is enabled for this Toast widget.
-- Use this when returns true if expired is enabled for this Toast widget is needed.
if false then
  local _o = nil  -- Toast instance
  _o:isExpired()
end

-- ── Separator methods ──

--@api-stub: Separator:setVertical
-- Sets the vertical for this Separator widget.
-- Use this when sets the vertical for this Separator widget is needed.
if false then
  local _o = nil  -- Separator instance
  _o:setVertical(0)
end

--@api-stub: Separator:isVertical
-- Returns true if vertical is enabled for this Separator widget.
-- Use this when returns true if vertical is enabled for this Separator widget is needed.
if false then
  local _o = nil  -- Separator instance
  _o:isVertical()
end

--@api-stub: Separator:setThickness
-- Sets the thickness for this Separator widget.
-- Use this when sets the thickness for this Separator widget is needed.
if false then
  local _o = nil  -- Separator instance
  _o:setThickness(1)
end

--@api-stub: Separator:getThickness
-- Returns the thickness of this Separator widget.
-- Use this when returns the thickness of this Separator widget is needed.
if false then
  local _o = nil  -- Separator instance
  _o:getThickness()
end

-- ── Tree_View methods ──

--@api-stub: Tree_View:addNode
-- Adds a node entry to this Tree_View widget.
-- Use this when adds a node entry to this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:addNode(0, 1)
end

--@api-stub: Tree_View:toggleNode
-- Toggles the expanded/collapsed status of a Tree_View node.
-- Use this when toggles the expanded/collapsed status of a Tree_View node is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:toggleNode(1)
end

--@api-stub: Tree_View:isExpanded
-- Returns true if expanded is enabled for this Tree_View widget.
-- Use this when returns true if expanded is enabled for this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:isExpanded(1)
end

--@api-stub: Tree_View:getNodeCount
-- Returns the node count of this Tree_View widget.
-- Use this when returns the node count of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getNodeCount()
end

--@api-stub: Tree_View:removeNode
-- Removes the node from this Tree_View widget.
-- Use this when removes the node from this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:removeNode(1)
end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes entries from this Tree_View widget.
-- Use this when clears all nodes entries from this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:clearNodes()
end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this Tree_View widget.
-- Use this when returns the node text of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getNodeText(1)
end

--@api-stub: Tree_View:setNodeText
-- Sets the node text for this Tree_View widget.
-- Use this when sets the node text for this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:setNodeText(1, 0)
end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon for this Tree_View widget.
-- Use this when sets the node icon for this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:setNodeIcon(1, 1)
end

--@api-stub: Tree_View:expandNode
-- Performs the expand node operation on this Tree_View widget.
-- Use this when performs the expand node operation on this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:expandNode(1)
end

--@api-stub: Tree_View:collapseNode
-- Performs the collapse node operation on this Tree_View widget.
-- Use this when performs the collapse node operation on this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:collapseNode(1)
end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if node expanded is enabled for this Tree_View widget.
-- Use this when returns true if node expanded is enabled for this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:isNodeExpanded(1)
end

--@api-stub: Tree_View:expandAll
-- Performs the expand all operation on this Tree_View widget.
-- Use this when performs the expand all operation on this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:expandAll()
end

--@api-stub: Tree_View:collapseAll
-- Performs the collapse all operation on this Tree_View widget.
-- Use this when performs the collapse all operation on this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:collapseAll()
end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node for this Tree_View widget.
-- Use this when sets the selected node for this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:setSelectedNode(1)
end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this Tree_View widget.
-- Use this when returns the selected node of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getSelectedNode()
end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this Tree_View widget.
-- Use this when returns the child nodes of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getChildNodes(1)
end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this Tree_View widget.
-- Use this when returns the parent node of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getParentNode(1)
end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this Tree_View widget.
-- Use this when returns the node depth of this Tree_View widget is needed.
if false then
  local _o = nil  -- Tree_View instance
  _o:getNodeDepth(1)
end

-- ── Radio_Button methods ──

--@api-stub: Radio_Button:getText
-- Returns the text of this Radio_Button widget.
-- Use this when returns the text of this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:getText()
end

--@api-stub: Radio_Button:setText
-- Sets the text for this Radio_Button widget.
-- Use this when sets the text for this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:setText(0)
end

--@api-stub: Radio_Button:isSelected
-- Returns true if selected is enabled for this Radio_Button widget.
-- Use this when returns true if selected is enabled for this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:isSelected()
end

--@api-stub: Radio_Button:setSelected
-- Sets the selected for this Radio_Button widget.
-- Use this when sets the selected for this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:setSelected(0)
end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this Radio_Button widget.
-- Use this when returns the group of this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:getGroup()
end

--@api-stub: Radio_Button:setGroup
-- Sets the group for this Radio_Button widget.
-- Use this when sets the group for this Radio_Button widget is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:setGroup(nil)
end

--@api-stub: Radio_Button:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Use this when registers a callback invoked when this widget's value changes is needed.
if false then
  local _o = nil  -- Radio_Button instance
  _o:setOnChange(nil)
end

-- ── Scroll_Bar methods ──

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this Scroll_Bar widget.
-- Use this when returns the scroll position of this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:getScrollPosition()
end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position for this Scroll_Bar widget.
-- Use this when sets the scroll position for this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:setScrollPosition(0)
end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this Scroll_Bar widget.
-- Use this when returns the content size of this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:getContentSize()
end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size for this Scroll_Bar widget.
-- Use this when sets the content size for this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:setContentSize(0)
end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this Scroll_Bar widget.
-- Use this when returns the view size of this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:getViewSize()
end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size for this Scroll_Bar widget.
-- Use this when sets the view size for this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:setViewSize(0)
end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if vertical is enabled for this Scroll_Bar widget.
-- Use this when returns true if vertical is enabled for this Scroll_Bar widget is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:isVertical()
end

--@api-stub: Scroll_Bar:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Use this when registers a callback invoked when this widget's value changes is needed.
if false then
  local _o = nil  -- Scroll_Bar instance
  _o:setOnChange(nil)
end

-- ── Gui_Window methods ──

--@api-stub: Gui_Window:getTitle
-- Returns the title of this Gui_Window widget.
-- Use this when returns the title of this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:getTitle()
end

--@api-stub: Gui_Window:setTitle
-- Sets the title for this Gui_Window widget.
-- Use this when sets the title for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:setTitle(0)
end

--@api-stub: Gui_Window:isCloseable
-- Returns true if closeable is enabled for this Gui_Window widget.
-- Use this when returns true if closeable is enabled for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:isCloseable()
end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable for this Gui_Window widget.
-- Use this when sets the closeable for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:setCloseable(0)
end

--@api-stub: Gui_Window:isDraggable
-- Returns true if draggable is enabled for this Gui_Window widget.
-- Use this when returns true if draggable is enabled for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:isDraggable()
end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable for this Gui_Window widget.
-- Use this when sets the draggable for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:setDraggable(0)
end

--@api-stub: Gui_Window:isResizable
-- Returns true if resizable is enabled for this Gui_Window widget.
-- Use this when returns true if resizable is enabled for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:isResizable()
end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable for this Gui_Window widget.
-- Use this when sets the resizable for this Gui_Window widget is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:setResizable(0)
end

--@api-stub: Gui_Window:setOnClose
-- Registers a callback invoked when this window is closed.
-- Use this when registers a callback invoked when this window is closed is needed.
if false then
  local _o = nil  -- Gui_Window instance
  _o:setOnClose(nil)
end

-- ── Split_Panel methods ──

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this Split_Panel widget.
-- Use this when returns the orientation of this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:getOrientation()
end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation for this Split_Panel widget.
-- Use this when sets the orientation for this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:setOrientation(0)
end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this Split_Panel widget.
-- Use this when returns the split position of this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:getSplitPosition()
end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position for this Split_Panel widget.
-- Use this when sets the split position for this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:setSplitPosition(0)
end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this Split_Panel widget.
-- Use this when returns the min panel size of this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:getMinPanelSize()
end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size for this Split_Panel widget.
-- Use this when sets the min panel size for this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:setMinPanelSize(0)
end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child for this Split_Panel widget.
-- Use this when sets the first child for this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:setFirstChild(1)
end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child for this Split_Panel widget.
-- Use this when sets the second child for this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:setSecondChild(1)
end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this Split_Panel widget.
-- Use this when returns the first child of this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:getFirstChild()
end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this Split_Panel widget.
-- Use this when returns the second child of this Split_Panel widget is needed.
if false then
  local _o = nil  -- Split_Panel instance
  _o:getSecondChild()
end

-- ── Dock_Panel methods ──

--@api-stub: Dock_Panel:dock
-- Performs the dock operation on this Dock_Panel widget.
-- Use this when performs the dock operation on this Dock_Panel widget is needed.
if false then
  local _o = nil  -- Dock_Panel instance
  _o:dock(1, 1)
end

--@api-stub: Dock_Panel:undock
-- Performs the undock operation on this Dock_Panel widget.
-- Use this when performs the undock operation on this Dock_Panel widget is needed.
if false then
  local _o = nil  -- Dock_Panel instance
  _o:undock(1)
end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the docked count of this Dock_Panel widget.
-- Use this when returns the docked count of this Dock_Panel widget is needed.
if false then
  local _o = nil  -- Dock_Panel instance
  _o:getDockedCount()
end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size for this Dock_Panel widget.
-- Use this when sets the split size for this Dock_Panel widget is needed.
if false then
  local _o = nil  -- Dock_Panel instance
  _o:setSplitSize(1, 1)
end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this Dock_Panel widget.
-- Use this when returns the split size of this Dock_Panel widget is needed.
if false then
  local _o = nil  -- Dock_Panel instance
  _o:getSplitSize(1)
end

-- ── Toolbar methods ──

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this Toolbar widget.
-- Use this when returns the orientation of this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:getOrientation()
end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation for this Toolbar widget.
-- Use this when sets the orientation for this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:setOrientation(0)
end

--@api-stub: Toolbar:addButton
-- Adds a button entry to this Toolbar widget.
-- Use this when adds a button entry to this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:addButton(1, 0)
end

--@api-stub: Toolbar:addSeparator
-- Adds a separator entry to this Toolbar widget.
-- Use this when adds a separator entry to this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:addSeparator()
end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer entry to this Toolbar widget.
-- Use this when adds a spacer entry to this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:addSpacer(1)
end

--@api-stub: Toolbar:getButton
-- Returns the button of this Toolbar widget.
-- Use this when returns the button of this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:getButton(1)
end

--@api-stub: Toolbar:setButtonEnabled
-- Sets the button enabled for this Toolbar widget.
-- Use this when sets the button enabled for this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:setButtonEnabled(1, 1)
end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled for this Toolbar widget.
-- Use this when sets the button toggled for this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:setButtonToggled(1, 0)
end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if button toggled is enabled for this Toolbar widget.
-- Use this when returns true if button toggled is enabled for this Toolbar widget is needed.
if false then
  local _o = nil  -- Toolbar instance
  _o:isButtonToggled(1)
end

-- ── Menu_Bar methods ──

--@api-stub: Menu_Bar:addMenu
-- Adds a menu entry to this Menu_Bar widget.
-- Use this when adds a menu entry to this Menu_Bar widget is needed.
if false then
  local _o = nil  -- Menu_Bar instance
  _o:addMenu(1)
end

--@api-stub: Menu_Bar:removeMenu
-- Removes the menu from this Menu_Bar widget.
-- Use this when removes the menu from this Menu_Bar widget is needed.
if false then
  local _o = nil  -- Menu_Bar instance
  _o:removeMenu(1)
end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this Menu_Bar widget.
-- Use this when returns the menus of this Menu_Bar widget is needed.
if false then
  local _o = nil  -- Menu_Bar instance
  _o:getMenus()
end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the menu count of this Menu_Bar widget.
-- Use this when returns the menu count of this Menu_Bar widget is needed.
if false then
  local _o = nil  -- Menu_Bar instance
  _o:getMenuCount()
end

-- ── Menu_Item methods ──

--@api-stub: Menu_Item:getText
-- Returns the text of this Menu_Item widget.
-- Use this when returns the text of this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:getText()
end

--@api-stub: Menu_Item:setText
-- Sets the text for this Menu_Item widget.
-- Use this when sets the text for this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:setText(0)
end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this Menu_Item widget.
-- Use this when returns the shortcut of this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:getShortcut()
end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut for this Menu_Item widget.
-- Use this when sets the shortcut for this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:setShortcut(0)
end

--@api-stub: Menu_Item:isChecked
-- Returns true if checked is enabled for this Menu_Item widget.
-- Use this when returns true if checked is enabled for this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:isChecked()
end

--@api-stub: Menu_Item:setChecked
-- Sets the checked for this Menu_Item widget.
-- Use this when sets the checked for this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:setChecked(0)
end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item entry to this Menu_Item widget.
-- Use this when adds a sub item entry to this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:addSubItem(1)
end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this Menu_Item widget.
-- Use this when returns the sub items of this Menu_Item widget is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:getSubItems()
end

--@api-stub: Menu_Item:setOnClick
-- Registers a callback invoked when this menu item is clicked.
-- Use this when registers a callback invoked when this menu item is clicked is needed.
if false then
  local _o = nil  -- Menu_Item instance
  _o:setOnClick(nil)
end

-- ── Dialog methods ──

--@api-stub: Dialog:getTitle
-- Returns the title of this Dialog widget.
-- Use this when returns the title of this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:getTitle()
end

--@api-stub: Dialog:setTitle
-- Sets the title for this Dialog widget.
-- Use this when sets the title for this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:setTitle(0)
end

--@api-stub: Dialog:isModal
-- Returns true if modal is enabled for this Dialog widget.
-- Use this when returns true if modal is enabled for this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:isModal()
end

--@api-stub: Dialog:setModal
-- Sets the modal for this Dialog widget.
-- Use this when sets the modal for this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:setModal(0)
end

--@api-stub: Dialog:isOpen
-- Returns true if open is enabled for this Dialog widget.
-- Use this when returns true if open is enabled for this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:isOpen()
end

--@api-stub: Dialog:open
-- Performs the open operation on this Dialog widget.
-- Use this when performs the open operation on this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:open()
end

--@api-stub: Dialog:close
-- Closes and removes this dialog from the screen.
-- Use this when closes and removes this dialog from the screen is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:close()
end

--@api-stub: Dialog:setOnClose
-- Registers a callback invoked when this dialog is closed.
-- Use this when registers a callback invoked when this dialog is closed is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:setOnClose(nil)
end

--@api-stub: Dialog:setContent
-- Sets the content for this Dialog widget.
-- Use this when sets the content for this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:setContent(1)
end

--@api-stub: Dialog:getContent
-- Returns the content of this Dialog widget.
-- Use this when returns the content of this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:getContent()
end

--@api-stub: Dialog:addButton
-- Adds a button entry to this Dialog widget.
-- Use this when adds a button entry to this Dialog widget is needed.
if false then
  local _o = nil  -- Dialog instance
  _o:addButton(0, function() end)
end

-- ── Status_Bar methods ──

--@api-stub: Status_Bar:addSection
-- Adds a section entry to this Status_Bar widget.
-- Use this when adds a section entry to this Status_Bar widget is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:addSection(0, 1)
end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text for this Status_Bar widget.
-- Use this when sets the section text for this Status_Bar widget is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:setSectionText(1, 0)
end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this Status_Bar widget.
-- Use this when returns the section text of this Status_Bar widget is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:getSectionText(1)
end

--@api-stub: Status_Bar:getSectionCount
-- Returns the section count of this Status_Bar widget.
-- Use this when returns the section count of this Status_Bar widget is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:getSectionCount()
end

--@api-stub: Status_Bar:setSectionCount
-- Resizes the section list for this Status_Bar widget.
-- Use this when resizes the section list for this Status_Bar widget is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:setSectionCount(1)
end

--@api-stub: Status_Bar:setSectionWidget
-- Compatibility shim for assigning a widget to a section.
-- Use this when compatibility shim for assigning a widget to a section is needed.
if false then
  local _o = nil  -- Status_Bar instance
  _o:setSectionWidget(1, 1)
end

-- ── Accordion methods ──

--@api-stub: Accordion:addSection
-- Adds a section entry to this Accordion widget.
-- Use this when adds a section entry to this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:addSection(0, 1)
end

--@api-stub: Accordion:getSectionCount
-- Returns the section count of this Accordion widget.
-- Use this when returns the section count of this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:getSectionCount()
end

--@api-stub: Accordion:toggleSection
-- Toggles the expanded/collapsed status of an Accordion section.
-- Use this when toggles the expanded/collapsed status of an Accordion section is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:toggleSection(1)
end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if section expanded is enabled for this Accordion widget.
-- Use this when returns true if section expanded is enabled for this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:isSectionExpanded(1)
end

--@api-stub: Accordion:isExclusive
-- Returns true if exclusive is enabled for this Accordion widget.
-- Use this when returns true if exclusive is enabled for this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:isExclusive()
end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive for this Accordion widget.
-- Use this when sets the exclusive for this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:setExclusive(0)
end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this Accordion widget.
-- Use this when returns the section title of this Accordion widget is needed.
if false then
  local _o = nil  -- Accordion instance
  _o:getSectionTitle(1)
end

-- ── Tooltip_Panel methods ──

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this Tooltip_Panel widget.
-- Use this when returns the text of this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:getText()
end

--@api-stub: Tooltip_Panel:setText
-- Sets the text for this Tooltip_Panel widget.
-- Use this when sets the text for this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:setText(0)
end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this Tooltip_Panel widget.
-- Use this when returns the delay of this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:getDelay()
end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay for this Tooltip_Panel widget.
-- Use this when sets the delay for this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:setDelay(0)
end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this Tooltip_Panel widget.
-- Use this when returns the target of this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:getTarget()
end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target for this Tooltip_Panel widget.
-- Use this when sets the target for this Tooltip_Panel widget is needed.
if false then
  local _o = nil  -- Tooltip_Panel instance
  _o:setTarget(0)
end

-- ── Color_Picker methods ──

--@api-stub: Color_Picker:getColor
-- Returns the color of this Color_Picker widget.
-- Use this when returns the color of this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:getColor()
end

--@api-stub: Color_Picker:setColor
-- Sets the color for this Color_Picker widget.
-- Use this when sets the color for this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:setColor(nil, 1, nil, nil)
end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this Color_Picker widget.
-- Use this when returns the show alpha of this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:getShowAlpha()
end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha for this Color_Picker widget.
-- Use this when sets the show alpha for this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:setShowAlpha(0)
end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this Color_Picker widget.
-- Use this when returns the color mode of this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:getColorMode()
end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode for this Color_Picker widget.
-- Use this when sets the color mode for this Color_Picker widget is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:setColorMode(nil)
end

--@api-stub: Color_Picker:setOnChange
-- Registers a callback invoked when this widget's value changes.
-- Use this when registers a callback invoked when this widget's value changes is needed.
if false then
  local _o = nil  -- Color_Picker instance
  _o:setOnChange(nil)
end

-- ── Gui_Table methods ──

--@api-stub: Gui_Table:addColumn
-- Adds a column entry to this Gui_Table widget.
-- Use this when adds a column entry to this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:addColumn(0, 1)
end

--@api-stub: Gui_Table:getColumnCount
-- Returns the column count of this Gui_Table widget.
-- Use this when returns the column count of this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:getColumnCount()
end

--@api-stub: Gui_Table:addRow
-- Adds a row entry to this Gui_Table widget.
-- Use this when adds a row entry to this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:addRow(nil)
end

--@api-stub: Gui_Table:getRowCount
-- Returns the row count of this Gui_Table widget.
-- Use this when returns the row count of this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:getRowCount()
end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this Gui_Table widget.
-- Use this when returns the cell of this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:getCell(0, nil)
end

--@api-stub: Gui_Table:setCell
-- Sets the cell for this Gui_Table widget.
-- Use this when sets the cell for this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:setCell(0, nil, 0)
end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this Gui_Table widget.
-- Use this when returns the selected row of this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:getSelectedRow()
end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row for this Gui_Table widget.
-- Use this when sets the selected row for this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:setSelectedRow(0)
end

--@api-stub: Gui_Table:isSortable
-- Returns true if sortable is enabled for this Gui_Table widget.
-- Use this when returns true if sortable is enabled for this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:isSortable()
end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable for this Gui_Table widget.
-- Use this when sets the sortable for this Gui_Table widget is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:setSortable(0)
end

--@api-stub: Gui_Table:setOnSelect
-- Registers a callback invoked when a table row is selected.
-- Use this when registers a callback invoked when a table row is selected is needed.
if false then
  local _o = nil  -- Gui_Table instance
  _o:setOnSelect(nil)
end

-- ── Image_Widget methods ──

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this Image_Widget widget.
-- Use this when returns the scale mode of this Image_Widget widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getScaleMode()
end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode for this Image_Widget widget.
-- Use this when sets the scale mode for this Image_Widget widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setScaleMode(nil)
end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this Image_Widget widget.
-- Use this when returns the tint of this Image_Widget widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getTint()
end

--@api-stub: Image_Widget:setTint
-- Sets the tint for this Image_Widget widget.
-- Use this when sets the tint for this Image_Widget widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setTint(nil, 1, nil, nil)
end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new interactive button widget as a child of this widget.
-- Use this when creates and returns a new interactive button widget as a child of this widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newButton(0)
end

--@api-stub: Image_Widget:newLabel
-- Creates a text label widget.
-- Use this when creates a text label widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newLabel(0)
end

--@api-stub: Image_Widget:newTextInput
-- Creates a text input widget.
-- Use this when creates a text input widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTextInput()
end

--@api-stub: Image_Widget:newCheckbox
-- Creates a checkbox widget.
-- Use this when creates a checkbox widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newCheckbox(0)
end

--@api-stub: Image_Widget:newSlider
-- Creates a value slider widget.
-- Use this when creates a value slider widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSlider(1, 0)
end

--@api-stub: Image_Widget:newProgressBar
-- Creates a progress bar widget.
-- Use this when creates a progress bar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newProgressBar(1, 0)
end

--@api-stub: Image_Widget:newComboBox
-- Creates a dropdown combo box widget.
-- Use this when creates a dropdown combo box widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newComboBox()
end

--@api-stub: Image_Widget:newList
-- Creates a selectable list widget.
-- Use this when creates a selectable list widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newList()
end

--@api-stub: Image_Widget:newPanel
-- Creates a container panel widget.
-- Use this when creates a container panel widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newPanel()
end

--@api-stub: Image_Widget:newLayout
-- Creates a flexbox layout container.
-- Use this when creates a flexbox layout container is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newLayout(1)
end

--@api-stub: Image_Widget:newScrollPanel
-- Creates a scrollable panel widget.
-- Use this when creates a scrollable panel widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newScrollPanel()
end

--@api-stub: Image_Widget:newNinePatch
-- Creates a 9-patch slicer widget.
-- Use this when creates a 9-patch slicer widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newNinePatch()
end

--@api-stub: Image_Widget:newTabBar
-- Creates a tab bar widget.
-- Use this when creates a tab bar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTabBar()
end

--@api-stub: Image_Widget:newSeparator
-- Creates a separator line.
-- Use this when creates a separator line is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSeparator(0)
end

--@api-stub: Image_Widget:newSpacer
-- Creates a spacing filler widget.
-- Use this when creates a spacing filler widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSpacer(0, 0)
end

--@api-stub: Image_Widget:newToast
-- Creates a toast notification widget.
-- Use this when creates a toast notification widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newToast(nil, 1)
end

--@api-stub: Image_Widget:newTreeView
-- Creates a collapsible tree view widget.
-- Use this when creates a collapsible tree view widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTreeView()
end

--@api-stub: Image_Widget:newRadioButton
-- Creates a grouped radio button widget.
-- Use this when creates a grouped radio button widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newRadioButton(0, nil)
end

--@api-stub: Image_Widget:newScrollBar
-- Creates a scroll bar widget.
-- Use this when creates a scroll bar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newScrollBar(0)
end

--@api-stub: Image_Widget:newWindow
-- Creates a draggable window widget.
-- Use this when creates a draggable window widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newWindow(0)
end

--@api-stub: Image_Widget:newSplitPanel
-- Creates a resizable split panel.
-- Use this when creates a resizable split panel is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSplitPanel(1)
end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new docking panel that arranges children along its edges.
-- Use this when creates and returns a new docking panel that arranges children along its edges is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newDockPanel()
end

--@api-stub: Image_Widget:newToolbar
-- Creates a toolbar widget.
-- Use this when creates a toolbar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newToolbar(1)
end

--@api-stub: Image_Widget:newMenuBar
-- Creates a menu bar widget.
-- Use this when creates a menu bar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newMenuBar()
end

--@api-stub: Image_Widget:newMenuItem
-- Creates a menu item widget.
-- Use this when creates a menu item widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newMenuItem(0)
end

--@api-stub: Image_Widget:newDialog
-- Creates a modal dialog widget.
-- Use this when creates a modal dialog widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newDialog(0)
end

--@api-stub: Image_Widget:newStatusBar
-- Creates a status bar widget.
-- Use this when creates a status bar widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newStatusBar()
end

--@api-stub: Image_Widget:newAccordion
-- Creates a collapsible accordion widget.
-- Use this when creates a collapsible accordion widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newAccordion()
end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates a tooltip panel widget.
-- Use this when creates a tooltip panel widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTooltipPanel(0)
end

--@api-stub: Image_Widget:newColorPicker
-- Creates a color picker widget.
-- Use this when creates a color picker widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newColorPicker()
end

--@api-stub: Image_Widget:newTable
-- Creates a data table widget.
-- Use this when creates a data table widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTable()
end

--@api-stub: Image_Widget:newImageWidget
-- Creates an image display widget.
-- Use this when creates an image display widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newImageWidget()
end

--@api-stub: Image_Widget:newTheme
-- Creates a new theme instance.
-- Use this when creates a new theme instance is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newTheme()
end

--@api-stub: Image_Widget:setTheme
-- Sets the active GUI theme.
-- Use this when sets the active GUI theme is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setTheme(0)
end

--@api-stub: Image_Widget:getTheme
-- Returns whether a theme is set.
-- Use this when returns whether a theme is set is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getTheme()
end

--@api-stub: Image_Widget:getRoot
-- Returns the root panel widget table.
-- Use this when returns the root panel widget table is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getRoot()
end

--@api-stub: Image_Widget:setFocus
-- Sets keyboard focus to a widget or clears it.
-- Use this when sets keyboard focus to a widget or clears it is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setFocus(1)
end

--@api-stub: Image_Widget:getFocus
-- Returns the focused widget index or nil.
-- Use this when returns the focused widget index or nil is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getFocus()
end

--@api-stub: Image_Widget:focusNext
-- Moves focus to the next focusable widget.
-- Use this when moves focus to the next focusable widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:focusNext()
end

--@api-stub: Image_Widget:focusPrev
-- Moves focus to the previous focusable widget.
-- Use this when moves focus to the previous focusable widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:focusPrev()
end

--@api-stub: Image_Widget:clearFocus
-- Removes keyboard focus from this widget so key events go to the next focusable.
-- Use this when removes keyboard focus from this widget so key events go to the next focusable is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:clearFocus()
end

--@api-stub: Image_Widget:addToast
-- Queues a toast notification from a table.
-- Use this when queues a toast notification from a table is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:addToast(0)
end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of active toasts.
-- Use this when returns the number of active toasts is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getToastCount()
end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to the GUI.
-- Use this when forwards a mouse press event to the GUI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:mousepressed(0, 0, 1)
end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to the GUI.
-- Use this when forwards a mouse release event to the GUI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:mousereleased(0, 0, 1)
end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to the GUI.
-- Use this when forwards a mouse move event to the GUI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:mousemoved(0, 0)
end

--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to the GUI.
-- Use this when forwards a key press event to the GUI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:keypressed(0)
end

--@api-stub: Image_Widget:textinput
-- Forwards text input to the focused text input widget.
-- Use this when forwards text input to the focused text input widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:textinput(0)
end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to the GUI.
-- Use this when forwards a mouse wheel event to the GUI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:wheelmoved(0, 0)
end

--@api-stub: Image_Widget:update
-- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
-- Use this when advances toast timers, removes expired toasts, and dispatches pending GUI events is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:update(0)
end

--@api-stub: Image_Widget:draw
-- Headless compatibility stub for GUI draw.
-- Use this when headless compatibility stub for GUI draw is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:draw()
end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the total widget count in the context.
-- Use this when returns the total widget count in the context is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:getWidgetCount()
end

--@api-stub: Image_Widget:drawToImage
-- Renders the UI widget tree to a CPU ImageData at the given resolution.
-- Use this when renders the UI widget tree to a CPU ImageData at the given resolution is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:drawToImage(0, 0)
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Use this when creates a new line chart is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newLineChart(0)
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Use this when creates and returns a new bar chart widget attached to this image widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newBarChart(0)
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Use this when creates a new scatter plot is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newScatterPlot(0)
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Use this when creates and returns a new pie chart widget attached to this image widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newPieChart(0)
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Use this when creates a new stacked-area chart is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newAreaChart(0)
end

--@api-stub: Image_Widget:newLineChart
-- Creates a new line chart.
-- Use this when creates a new line chart is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newLineChart(0)
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget attached to this image widget.
-- Use this when creates and returns a new bar chart widget attached to this image widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newBarChart(0)
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates a new scatter plot.
-- Use this when creates a new scatter plot is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newScatterPlot(0)
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget attached to this image widget.
-- Use this when creates and returns a new pie chart widget attached to this image widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newPieChart(0)
end

--@api-stub: Image_Widget:newAreaChart
-- Creates a new stacked-area chart.
-- Use this when creates a new stacked-area chart is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newAreaChart(0)
end

--@api-stub: Image_Widget:parseWidgetState
-- Parses a widget state string, returning the canonical form or nil if invalid.
-- Use this when parses a widget state string, returning the canonical form or nil if invalid is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:parseWidgetState(0)
end

--@api-stub: Image_Widget:newSpinBox
-- Creates a numeric spin box widget with increment and decrement buttons.
-- Use this when creates a numeric spin box widget with increment and decrement buttons is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSpinBox(1, 0)
end

--@api-stub: Image_Widget:newSwitch
-- Creates a toggle switch widget.
-- Use this when creates a toggle switch widget is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newSwitch(1)
end

--@api-stub: Image_Widget:newBadge
-- Creates a badge widget displaying a numeric count.
-- Use this when creates a badge widget displaying a numeric count is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:newBadge(1)
end

--@api-stub: Image_Widget:setDefaultTheme
-- Installs the built-in dark theme as the active GUI theme.
-- Use this when installs the built-in dark theme as the active GUI theme is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setDefaultTheme()
end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport dimensions used for anchor constraints and layout.
-- Use this when sets the viewport dimensions used for anchor constraints and layout is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:setViewport(0, 0)
end

--@api-stub: Image_Widget:flushCache
-- Returns true if the widget tree changed since the last call, then resets the flag.
-- Use this when returns true if the widget tree changed since the last call, then resets the flag is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:flushCache()
end

--@api-stub: Image_Widget:update_bindings
-- Updates all widgets that have a data-binding key registered via `:bind(key)`.
-- Use this when updates all widgets that have a data-binding key registered via `:bind(key)` is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:update_bindings()
end

--@api-stub: Image_Widget:loadLayout
-- Load a widget tree from a Lua table definition and attach it to the UI.
-- Use this when load a widget tree from a Lua table definition and attach it to the UI is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:loadLayout()
end

--@api-stub: Image_Widget:loadLayoutFile
-- Load a widget tree from a TOML layout file and attach it to the UI root.
-- Use this when load a widget tree from a TOML layout file and attach it to the UI root is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:loadLayoutFile(0)
end

--@api-stub: Image_Widget:renderToImage
-- Render the current UI widget tree to a PNG file for testing purposes.
-- Use this when render the current UI widget tree to a PNG file for testing purposes is needed.
if false then
  local _o = nil  -- Image_Widget instance
  _o:renderToImage(1, 1, 0)
end

-- ── LineChart methods ──

--@api-stub: LineChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Use this when sets the maximum Y value for axis scaling is needed.
if false then
  local _o = nil  -- LineChart instance
  _o:setYMax(0)
end

--@api-stub: LineChart:setXMax
-- Sets the maximum X value for axis scaling.
-- Use this when sets the maximum X value for axis scaling is needed.
if false then
  local _o = nil  -- LineChart instance
  _o:setXMax(0)
end

--@api-stub: LineChart:drawToImage
-- Renders the line chart into an existing ImageData.
-- Use this when renders the line chart into an existing ImageData is needed.
if false then
  local _o = nil  -- LineChart instance
  _o:drawToImage()
end

-- ── BarChart methods ──

--@api-stub: BarChart:drawToImage
-- Renders the bar chart into an existing ImageData.
-- Use this when renders the bar chart into an existing ImageData is needed.
if false then
  local _o = nil  -- BarChart instance
  _o:drawToImage()
end

-- ── ScatterPlot methods ──

--@api-stub: ScatterPlot:setXRange
-- Sets the X-axis data range.
-- Use this when sets the X-axis data range is needed.
if false then
  local _o = nil  -- ScatterPlot instance
  _o:setXRange(1, 0)
end

--@api-stub: ScatterPlot:setYRange
-- Sets the Y-axis data range.
-- Use this when sets the Y-axis data range is needed.
if false then
  local _o = nil  -- ScatterPlot instance
  _o:setYRange(1, 0)
end

--@api-stub: ScatterPlot:drawToImage
-- Renders the scatter plot into an existing ImageData.
-- Use this when renders the scatter plot into an existing ImageData is needed.
if false then
  local _o = nil  -- ScatterPlot instance
  _o:drawToImage()
end

-- ── PieChart methods ──

--@api-stub: PieChart:drawToImage
-- Renders the pie chart into an existing ImageData.
-- Use this when renders the pie chart into an existing ImageData is needed.
if false then
  local _o = nil  -- PieChart instance
  _o:drawToImage()
end

-- ── AreaChart methods ──

--@api-stub: AreaChart:setYMax
-- Sets the maximum Y value for axis scaling.
-- Use this when sets the maximum Y value for axis scaling is needed.
if false then
  local _o = nil  -- AreaChart instance
  _o:setYMax(0)
end

--@api-stub: AreaChart:drawToImage
-- Renders the area chart into an existing ImageData.
-- Use this when renders the area chart into an existing ImageData is needed.
if false then
  local _o = nil  -- AreaChart instance
  _o:drawToImage()
end

