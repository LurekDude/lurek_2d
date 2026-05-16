-- content/examples/ui.lua
-- lurek.ui API examples.
-- Run: cargo run -- content/examples/ui.lua

--@api-stub: lurek.ui.beginDrag
-- Begins a drag operation on a widget
do
  local w = lurek.ui.newButton("Drag")
  pcall(function() lurek.ui.beginDrag(w) end)
end

--@api-stub: lurek.ui.getActiveDrag
-- Returns the widget index currently being dragged, or nil
do
  pcall(function()
    local v = lurek.ui.getActiveDrag()
    print("getActiveDrag:", v)
  end)
end

--@api-stub: lurek.ui.dropOn
-- Drops the currently dragged widget onto a target widget
do
  local container = lurek.ui.newPanel()
  local w = lurek.ui.newLabel("drop")
  pcall(function()
    lurek.ui.beginDrag(w)
    lurek.ui.dropOn(container)
  end)
end

--@api-stub: lurek.ui.endDrag
-- Ends the current drag operation without dropping
do
  pcall(function()
    local prev = lurek.ui.endDrag()
    print("endDrag:", prev)
  end)
end

--@api-stub: LUiWidget:animateAlpha
-- Performs the animate alpha operation on this ui widget.
do
  local w = lurek.ui.newLabel("alpha")
  pcall(function() w["animateAlpha"](0.5, 0.25, false) end)
end

--@api-stub: LUiWidget:animatePosition
-- Performs the animate position operation on this ui widget.
do
  local w = lurek.ui.newLabel("move")
  pcall(function() w["animatePosition"](120, 40, 0.25) end)
end

--@api-stub: LUiWidget:isAnimating
-- Returns true if this ui widget animating.
do
  local w = lurek.ui.newLabel("state")
  pcall(function()
    local v = w["isAnimating"]()
    print("isAnimating:", v)
  end)
end

--@api-stub: LUiWidget:cancelAnimations
-- Performs the cancel animations operation on this ui widget.
do
  local w = lurek.ui.newLabel("cancel")
  pcall(function() w["cancelAnimations"]() end)
end

--@api-stub: lurek.ui.setPosition
-- Sets the position of this ui.
do
  pcall(function() lurek.ui.setPosition(100, 200) end)
  print("applied")
end

--@api-stub: lurek.ui.getPosition
-- Returns the position of this ui.
do
  pcall(function()
    local v = lurek.ui.getPosition()
    print("getPosition:", v)
  end)
end

--@api-stub: lurek.ui.setSize
-- Sets the size of this ui.
do
  pcall(function() lurek.ui.setSize(200, 50) end)
  print("applied")
end

--@api-stub: lurek.ui.getSize
-- Returns the size of this ui.
do
  pcall(function()
    local v = lurek.ui.getSize()
    print("getSize:", v)
  end)
end

--@api-stub: lurek.ui.getRect
-- Returns the rect of this ui.
do
  pcall(function()
    local v = lurek.ui.getRect()
    print("getRect:", v)
  end)
end

--@api-stub: lurek.ui.setVisible
-- Sets the visibility flag for this ui.
do
  pcall(function() lurek.ui.setVisible(true) end)
  print("applied")
end

--@api-stub: lurek.ui.isVisible
-- Returns true if this ui is currently visible.
do
  pcall(function()
    local v = lurek.ui.isVisible()
    print("isVisible:", v)
  end)
end

--@api-stub: lurek.ui.setEnabled
-- Sets whether this ui is enabled and accepts input.
do
  pcall(function() lurek.ui.setEnabled(true) end)
  print("applied")
end

--@api-stub: lurek.ui.isEnabled
-- Returns true if this ui is currently enabled.
do
  pcall(function()
    local v = lurek.ui.isEnabled()
    print("isEnabled:", v)
  end)
end

--@api-stub: lurek.ui.setId
-- Sets the id of this ui.
do
  pcall(function()
    lurek.ui.setId("primary")
    print("applied")
  end)
end

--@api-stub: lurek.ui.getId
-- Returns the id of this ui.
do
  pcall(function()
    local v = lurek.ui.getId()
    print("getId:", v)
  end)
end

--@api-stub: lurek.ui.setTooltip
-- Sets the tooltip of this ui.
do
  lurek.ui.setTooltip("Hello")
  print("applied")
end

--@api-stub: lurek.ui.getTooltip
-- Returns the tooltip of this ui.
do
  local v = lurek.ui.getTooltip()
  print("getTooltip:", v)
end

--@api-stub: lurek.ui.getState
-- Returns the state of this ui.
do
  local v = lurek.ui.getState()
  print("getState:", v)
end

--@api-stub: lurek.ui.addChild
-- Adds a child to this ui.
do
  lurek.ui.addChild(1)
  print("added")
end

--@api-stub: lurek.ui.removeChild
-- Removes a child from this ui.
do
  lurek.ui.removeChild(1)
  print("done")
end

--@api-stub: lurek.ui.getChildCount
-- Returns the number of child items in this ui.
do
  local v = lurek.ui.getChildCount()
  print("getChildCount:", v)
end

--@api-stub: lurek.ui.getChildren
-- Returns the children of this ui.
do
  local v = lurek.ui.getChildren()
  print("getChildren:", v)
end

--@api-stub: lurek.ui.findById
-- Finds and returns the by id in this ui by name or id.
do
  local v = lurek.ui.findById("widget_id")
  print("findById:", v)
end

--@api-stub: lurek.ui.setOnClick
-- Sets the on click of this ui.
do
  lurek.ui.setOnClick(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnChange
-- Sets the on change of this ui.
do
  lurek.ui.setOnChange(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.setOnDraw
-- Sets the on draw of this ui.
do
  lurek.ui.setOnDraw(function() print("event") end)
  print("applied")
end

--@api-stub: lurek.ui.containsPoint
-- Performs the contains point operation on this ui.
do
  local v = lurek.ui.containsPoint(0, 0)
  print("containsPoint:", v)
end

--@api-stub: lurek.ui.setPadding
-- Sets the padding of this ui.
do
  lurek.ui.setPadding(8)
  print("applied")
end

--@api-stub: lurek.ui.getPadding
-- Returns the padding of this ui.
do
  local v = lurek.ui.getPadding()
  print("getPadding:", v)
end

--@api-stub: lurek.ui.setMargin
-- Sets the margin of this ui.
do
  lurek.ui.setMargin(8)
  print("applied")
end

--@api-stub: lurek.ui.getMargin
-- Returns the margin of this ui.
do
  local v = lurek.ui.getMargin()
  print("getMargin:", v)
end

--@api-stub: lurek.ui.setZOrder
-- Sets the z order of this ui.
do
  lurek.ui.setZOrder(1)
  print("applied")
end

--@api-stub: lurek.ui.getZOrder
-- Returns the z order of this ui.
do
  local v = lurek.ui.getZOrder()
  print("getZOrder:", v)
end

--@api-stub: lurek.ui.setMinSize
-- Sets the min size of this ui.
do
  lurek.ui.setMinSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMinSize
-- Returns the min size of this ui.
do
  local v = lurek.ui.getMinSize()
  print("getMinSize:", v)
end

--@api-stub: lurek.ui.setMaxSize
-- Sets the max size of this ui.
do
  lurek.ui.setMaxSize(200, 50)
  print("applied")
end

--@api-stub: lurek.ui.getMaxSize
-- Returns the max size of this ui.
do
  local v = lurek.ui.getMaxSize()
  print("getMaxSize:", v)
end

--@api-stub: lurek.ui.setAnchor
-- Sets the anchor of this ui.
do
  lurek.ui.setAnchor(8, 8, 8, 8)
  print("applied")
end

--@api-stub: lurek.ui.setAnchorCenter
-- Sets the anchor center of this ui.
do
  lurek.ui.setAnchorCenter(0, 0)
  print("applied")
end

--@api-stub: lurek.ui.clearAnchor
-- Clears all anchor items from this ui.
do
  lurek.ui.clearAnchor()
  print("done")
end

--@api-stub: lurek.ui.setFlexGrow
-- Sets the flex grow of this ui.
do
  lurek.ui.setFlexGrow(1)
  print("applied")
end

--@api-stub: lurek.ui.getFlexGrow
-- Returns the flex grow of this ui.
do
  local v = lurek.ui.getFlexGrow()
  print("getFlexGrow:", v)
end

--@api-stub: lurek.ui.setFlexShrink
-- Sets the flex shrink of this ui.
do
  lurek.ui.setFlexShrink(1)
  print("applied")
end

--@api-stub: lurek.ui.getFlexShrink
-- Returns the flex shrink of this ui.
do
  local v = lurek.ui.getFlexShrink()
  print("getFlexShrink:", v)
end

--@api-stub: lurek.ui.bind
-- Performs the bind operation on this ui.
do
  lurek.ui.bind("key")
  print("bind called")
end

--@api-stub: lurek.ui.unbind
-- Performs the unbind operation on this ui.
do
  lurek.ui.unbind()
  print("unbind called")
end

--@api-stub: lurek.ui.setAlpha
-- Sets the alpha of this ui.
do
  lurek.ui.setAlpha(0.85)
  print("applied")
end

--@api-stub: lurek.ui.getAlpha
-- Returns the alpha of this ui.
do
  local v = lurek.ui.getAlpha()
  print("getAlpha:", v)
end

--@api-stub: lurek.ui.fadeIn
-- Performs the fade in operation on this ui.
do
  lurek.ui.fadeIn()
  print("fadeIn called")
end

--@api-stub: lurek.ui.fadeOut
-- Performs the fade out operation on this ui.
do
  lurek.ui.fadeOut()
  print("fadeOut called")
end

--@api-stub: lurek.ui.slideIn
-- Performs the slide in operation on this ui.
do
  lurek.ui.slideIn(0, 0)
  print("slideIn called")
end

--@api-stub: lurek.ui.slideOut
-- Performs the slide out operation on this ui.
do
  lurek.ui.slideOut(0, 0)
  print("slideOut called")
end

--@api-stub: lurek.ui.attachToEntity
-- Performs the attach to entity operation on this ui.
do
  lurek.ui.attachToEntity(1)
  print("attachToEntity called")
end

--@api-stub: lurek.ui.detachFromEntity
-- Performs the detach from entity operation on this ui.
do
  lurek.ui.detachFromEntity()
  print("detachFromEntity called")
end


---@return any
local function new_example_image_widget()
  return {}
end

--@api-stub: Button:setText
-- Sets the text of this button.
do
  local btn = new_example_image_widget():newButton("btn_play", "Play")
  btn:setText("Hello")
end

--@api-stub: Button:getText
-- Returns the text of this button.
do
  local btn = new_example_image_widget():newButton("btn_play", "Play")
  local v = btn:getText()
  print("getText:", v)
end

-- Label methods

--@api-stub: Label:setText
-- Sets the text of this label.
do
  local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
  lbl:setText("Hello")
end

--@api-stub: Label:getText
-- Returns the text of this label.
do
  local lbl = new_example_image_widget():newLabel("lbl_score", "Score: 0")
  local v = lbl:getText()
  print("getText:", v)
end

-- Text_Input methods

--@api-stub: Text_Input:setText
-- Sets the text of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setText("Hello")
end

--@api-stub: Text_Input:getText
-- Returns the text of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getText()
  print("getText:", v)
end

--@api-stub: Text_Input:setPlaceholder
-- Sets the placeholder of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setPlaceholder("Hello")
end

--@api-stub: Text_Input:getPlaceholder
-- Returns the placeholder of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getPlaceholder()
  print("getPlaceholder:", v)
end

--@api-stub: Text_Input:setMaxLength
-- Sets the max length of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  ti:setMaxLength(100)
end

--@api-stub: Text_Input:isFocused
-- Returns true if this text_input focused.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:isFocused()
  print("isFocused:", v)
end

--@api-stub: Text_Input:getCursorPosition
-- Returns the cursor position of this text_input.
do
  local ti = new_example_image_widget():newTextInput("ti_name", "")
  local v = ti:getCursorPosition()
  print("getCursorPosition:", v)
end

-- Checkbox methods

--@api-stub: Checkbox:setChecked
-- Sets the checked of this checkbox.
do
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  cb:setChecked(true)
end

--@api-stub: Checkbox:isChecked
-- Returns true if this checkbox checked.
do
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  local v = cb:isChecked()
  print("isChecked:", v)
end

--@api-stub: Checkbox:setText
-- Sets the text of this checkbox.
do
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  cb:setText("Hello")
end

--@api-stub: Checkbox:getText
-- Returns the text of this checkbox.
do
  local cb = new_example_image_widget():newCheckbox("cb_sound", "Sound", true)
  local v = cb:getText()
  print("getText:", v)
end

-- Slider methods

--@api-stub: Slider:setValue
-- Sets the value of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setValue(0.5)
end

--@api-stub: Slider:getValue
-- Returns the value of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getValue()
  print("getValue:", v)
end

--@api-stub: Slider:setRange
-- Sets the range of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setRange(1)
end

--@api-stub: Slider:setStep
-- Sets the step of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  sl:setStep(1)
end

--@api-stub: Slider:getMin
-- Returns the min of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getMin()
  print("getMin:", v)
end

--@api-stub: Slider:getMax
-- Returns the max of this slider.
do
  local sl = new_example_image_widget():newSlider(0, 100, 50)
  local v = sl:getMax()
  print("getMax:", v)
end

-- Progress_Bar methods

--@api-stub: Progress_Bar:setValue
-- Sets the value of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  pb:setValue(0.5)
end

--@api-stub: Progress_Bar:getValue
-- Returns the value of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getValue()
  print("getValue:", v)
end

--@api-stub: Progress_Bar:getProgress
-- Returns the progress of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getProgress()
  print("getProgress:", v)
end

--@api-stub: Progress_Bar:setRange
-- Sets the range of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  pb:setRange(1)
end

--@api-stub: Progress_Bar:getMin
-- Returns the min of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getMin()
  print("getMin:", v)
end

--@api-stub: Progress_Bar:getMax
-- Returns the max of this progress_bar.
do
  local pb = new_example_image_widget():newProgressBar(0.5)
  local v = pb:getMax()
  print("getMax:", v)
end

-- Combo_Box methods

--@api-stub: Combo_Box:addItem
-- Adds a item to this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:addItem("item_1")
end

--@api-stub: Combo_Box:removeItem
-- Removes a item from this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:removeItem()
end

--@api-stub: Combo_Box:clearItems
-- Clears all items items from this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:clearItems()
end

--@api-stub: Combo_Box:getItemCount
-- Returns the number of item items in this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: Combo_Box:getItem
-- Returns the item of this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getItem()
  print("getItem:", v)
end

--@api-stub: Combo_Box:setSelectedIndex
-- Sets the selected index of this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  cb:setSelectedIndex(true)
end

--@api-stub: Combo_Box:getSelectedIndex
-- Returns the selected index of this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: Combo_Box:getSelectedItem
-- Returns the selected item of this combo_box.
do
  local cb = new_example_image_widget():newComboBox({"Easy","Normal","Hard"})
  local v = cb:getSelectedItem()
  print("getSelectedItem:", v)
end

-- List_Box methods

--@api-stub: List_Box:addItem
-- Adds a item to this list_box.
do
  local w = new_example_image_widget():newList()
  w:addItem("item_1")
end

--@api-stub: List_Box:removeItem
-- Removes a item from this list_box.
do
  local w = new_example_image_widget():newList()
  w:removeItem()
end

--@api-stub: List_Box:clearItems
-- Clears all items items from this list_box.
do
  local w = new_example_image_widget():newList()
  w:clearItems()
end

--@api-stub: List_Box:getItemCount
-- Returns the number of item items in this list_box.
do
  local w = new_example_image_widget():newList()
  local v = w:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: List_Box:getItem
-- Returns the item of this list_box.
do
  local w = new_example_image_widget():newList()
  local v = w:getItem()
  print("getItem:", v)
end

--@api-stub: List_Box:setSelectedIndex
-- Sets the selected index of this list_box.
do
  local w = new_example_image_widget():newList()
  w:setSelectedIndex(true)
end

--@api-stub: List_Box:getSelectedIndex
-- Returns the selected index of this list_box.
do
  local w = new_example_image_widget():newList()
  local v = w:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: List_Box:setItemHeight
-- Sets the item height of this list_box.
do
  local w = new_example_image_widget():newList()
  w:setItemHeight(50)
end

-- Tab_Bar methods

--@api-stub: Tab_Bar:addTab
-- Adds a tab to this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local child = new_example_image_widget():newButton("child_1", "Child")
  tabs:addTab(child)
end

--@api-stub: Tab_Bar:removeTab
-- Removes a tab from this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  tabs:removeTab()
end

--@api-stub: Tab_Bar:getTab
-- Returns the tab of this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTab()
  print("getTab:", v)
end

--@api-stub: Tab_Bar:getTabCount
-- Returns the number of tab items in this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getTabCount()
  print("getTabCount:", v)
end

--@api-stub: Tab_Bar:setActiveTab
-- Sets the active tab of this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  tabs:setActiveTab(1)
end

--@api-stub: Tab_Bar:getActiveTab
-- Returns the active tab of this tab_bar.
do
  local tabs = new_example_image_widget():newTabBar({"Equip","Stats","Map"})
  local v = tabs:getActiveTab()
  print("getActiveTab:", v)
end

-- Spin_Box methods

--@api-stub: Spin_Box:setValue
-- Sets the value of this spin_box.
do
  local spin = new_example_image_widget():newSpinBox()
  spin:setValue(0.5)
end

--@api-stub: Spin_Box:getValue
-- Returns the value of this spin_box.
do
  local spin = new_example_image_widget():newSpinBox()
  local v = spin:getValue()
  print("getValue:", v)
end

--@api-stub: Spin_Box:increment
-- Increments the value of this spin_box by one step.
do
  local spin = new_example_image_widget():newSpinBox()
  spin:increment()
end

--@api-stub: Spin_Box:decrement
-- Decrements the value of this spin_box by one step.
do
  local spin = new_example_image_widget():newSpinBox()
  spin:decrement()
end

--@api-stub: Spin_Box:setRange
-- Sets the range of this spin_box.
do
  local spin = new_example_image_widget():newSpinBox()
  spin:setRange(1)
end

--@api-stub: Spin_Box:setStep
-- Sets the step of this spin_box.
do
  local spin = new_example_image_widget():newSpinBox()
  spin:setStep(1)
end

-- Switch methods

--@api-stub: Switch:setOn
-- Sets the on of this switch.
do
  local sw = new_example_image_widget():newSwitch(false)
  sw:setOn(function() print("event") end)
end

--@api-stub: Switch:isOn
-- Returns true if this switch on.
do
  local sw = new_example_image_widget():newSwitch(false)
  local v = sw:isOn()
  print("isOn:", v)
end

--@api-stub: Switch:toggle
-- Toggles the  state of this switch.
do
  local sw = new_example_image_widget():newSwitch(false)
  sw:toggle()
end

-- Badge methods

--@api-stub: Badge:setCount
-- Sets the count of this badge.
do
  local badge = new_example_image_widget():newBadge("3")
  badge:setCount(4)
end

--@api-stub: Badge:getCount
-- Returns the total count of items held by this badge.
do
  local badge = new_example_image_widget():newBadge("3")
  local v = badge:getCount()
  print("getCount:", v)
end

--@api-stub: Badge:getDisplayText
-- Returns the display text of this badge.
do
  local badge = new_example_image_widget():newBadge("3")
  local v = badge:getDisplayText()
  print("getDisplayText:", v)
end

-- Panel methods

--@api-stub: Panel:setTitle
-- Sets the title of this panel.
do
  local panel = new_example_image_widget():newPanel()
  panel:setTitle("Hello")
end

--@api-stub: Panel:getTitle
-- Returns the title of this panel.
do
  local panel = new_example_image_widget():newPanel()
  local v = panel:getTitle()
  print("getTitle:", v)
end

--@api-stub: Panel:setScrollable
-- Sets the scrollable of this panel.
do
  local panel = new_example_image_widget():newPanel()
  panel:setScrollable(1)
end

-- Layout methods

--@api-stub: Layout:setDirection
-- Sets the direction of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setDirection("horizontal")
end

--@api-stub: Layout:getDirection
-- Returns the direction of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getDirection()
  print("getDirection:", v)
end

--@api-stub: Layout:setSpacing
-- Sets the spacing of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setSpacing(8)
end

--@api-stub: Layout:getSpacing
-- Returns the spacing of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getSpacing()
  print("getSpacing:", v)
end

--@api-stub: Layout:setColumns
-- Sets the columns of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setColumns(1)
end

--@api-stub: Layout:setWrap
-- Sets the wrap of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setWrap(true)
end

--@api-stub: Layout:getWrap
-- Returns the wrap of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getWrap()
  print("getWrap:", v)
end

--@api-stub: Layout:setAlign
-- Sets the align of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setAlign("center")
end

--@api-stub: Layout:getAlign
-- Returns the align of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getAlign()
  print("getAlign:", v)
end

--@api-stub: Layout:setJustify
-- Sets the justify of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  layout:setJustify(1)
end

--@api-stub: Layout:getJustify
-- Returns the justify of this layout.
do
  local layout = new_example_image_widget():newLayout("vertical")
  local v = layout:getJustify()
  print("getJustify:", v)
end

-- Scroll_Panel methods

--@api-stub: Scroll_Panel:setContentSize
-- Sets the content size of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  sp:setContentSize(200, 50)
end

--@api-stub: Scroll_Panel:getContentSize
-- Returns the content size of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Panel:setScrollPosition
-- Sets the scroll position of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  sp:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Panel:getScrollPosition
-- Returns the scroll position of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Panel:getMaxScroll
-- Returns the max scroll of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getMaxScroll()
  print("getMaxScroll:", v)
end

--@api-stub: Scroll_Panel:setScrollSpeed
-- Sets the scroll speed of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  sp:setScrollSpeed(1)
end

--@api-stub: Scroll_Panel:getScrollSpeed
-- Returns the scroll speed of this scroll_panel.
do
  local sp = new_example_image_widget():newScrollPanel()
  local v = sp:getScrollSpeed()
  print("getScrollSpeed:", v)
end

-- Nine_Patch methods

--@api-stub: Nine_Patch:setInsets
-- Sets the insets of this nine_patch.
do
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  np:setInsets(1)
end

--@api-stub: Nine_Patch:getInsets
-- Returns the insets of this nine_patch.
do
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getInsets()
  print("getInsets:", v)
end

--@api-stub: Nine_Patch:setImageDimensions
-- Sets the image dimensions of this nine_patch.
do
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  np:setImageDimensions("assets/icon.png")
end

--@api-stub: Nine_Patch:getImageDimensions
-- Returns the image dimensions of this nine_patch.
do
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getImageDimensions()
  print("getImageDimensions:", v)
end

--@api-stub: Nine_Patch:getSlices
-- Returns the slices of this nine_patch.
do
  local np = new_example_image_widget():newNinePatch("assets/panel.9.png")
  local v = np:getSlices()
  print("getSlices:", v)
end

-- Toast methods

--@api-stub: Toast:setMessage
-- Sets the message of this toast.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  toast:setMessage(1)
end

--@api-stub: Toast:getMessage
-- Returns the message of this toast.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getMessage()
  print("getMessage:", v)
end

--@api-stub: Toast:setDuration
-- Sets the duration of this toast.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  toast:setDuration(0.5)
end

--@api-stub: Toast:getDuration
-- Returns the duration of this toast.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getDuration()
  print("getDuration:", v)
end

--@api-stub: Toast:getProgress
-- Returns the progress of this toast.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:getProgress()
  print("getProgress:", v)
end

--@api-stub: Toast:isExpired
-- Returns true if this toast expired.
do
  local toast = new_example_image_widget():newToast("Saved.", 2.0)
  local v = toast:isExpired()
  print("isExpired:", v)
end

-- Separator methods

--@api-stub: Separator:setVertical
-- Sets the vertical of this separator.
do
  local sep = new_example_image_widget():newSeparator("horizontal")
  sep:setVertical(1)
end

--@api-stub: Separator:isVertical
-- Returns true if this separator vertical.
do
  local sep = new_example_image_widget():newSeparator("horizontal")
  local v = sep:isVertical()
  print("isVertical:", v)
end

--@api-stub: Separator:setThickness
-- Sets the thickness of this separator.
do
  local sep = new_example_image_widget():newSeparator("horizontal")
  sep:setThickness(1)
end

--@api-stub: Separator:getThickness
-- Returns the thickness of this separator.
do
  local sep = new_example_image_widget():newSeparator("horizontal")
  local v = sep:getThickness()
  print("getThickness:", v)
end

-- Tree_View methods

--@api-stub: Tree_View:addNode
-- Adds a node to this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:addNode("item_1")
end

--@api-stub: Tree_View:toggleNode
-- Toggles the node state of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:toggleNode()
end

--@api-stub: Tree_View:isExpanded
-- Returns true if this tree_view expanded.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:isExpanded()
  print("isExpanded:", v)
end

--@api-stub: Tree_View:getNodeCount
-- Returns the number of node items in this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeCount()
  print("getNodeCount:", v)
end

--@api-stub: Tree_View:removeNode
-- Removes a node from this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:removeNode()
end

--@api-stub: Tree_View:clearNodes
-- Clears all nodes items from this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:clearNodes()
end

--@api-stub: Tree_View:getNodeText
-- Returns the node text of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeText()
  print("getNodeText:", v)
end

--@api-stub: Tree_View:setNodeText
-- Sets the node text of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setNodeText("Hello")
end

--@api-stub: Tree_View:setNodeIcon
-- Sets the node icon of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setNodeIcon("assets/icon.png")
end

--@api-stub: Tree_View:expandNode
-- Expands this tree_view to show its children or content.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:expandNode()
end

--@api-stub: Tree_View:collapseNode
-- Collapses this tree_view to hide its children or content.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:collapseNode()
end

--@api-stub: Tree_View:isNodeExpanded
-- Returns true if this tree_view node expanded.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:isNodeExpanded()
  print("isNodeExpanded:", v)
end

--@api-stub: Tree_View:expandAll
-- Expands this tree_view to show its children or content.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:expandAll()
end

--@api-stub: Tree_View:collapseAll
-- Collapses this tree_view to hide its children or content.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:collapseAll()
end

--@api-stub: Tree_View:setSelectedNode
-- Sets the selected node of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  tree:setSelectedNode(true)
end

--@api-stub: Tree_View:getSelectedNode
-- Returns the selected node of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getSelectedNode()
  print("getSelectedNode:", v)
end

--@api-stub: Tree_View:getChildNodes
-- Returns the child nodes of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getChildNodes()
  print("getChildNodes:", v)
end

--@api-stub: Tree_View:getParentNode
-- Returns the parent node of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getParentNode()
  print("getParentNode:", v)
end

--@api-stub: Tree_View:getNodeDepth
-- Returns the node depth of this tree_view.
do
  local tree = new_example_image_widget():newTreeView({label="root"})
  local v = tree:getNodeDepth()
  print("getNodeDepth:", v)
end

-- Radio_Button methods

--@api-stub: Radio_Button:getText
-- Returns the text of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:getText()
  print("getText:", v)
end

--@api-stub: Radio_Button:setText
-- Sets the text of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setText("Hello")
end

--@api-stub: Radio_Button:isSelected
-- Returns true if this radio_button selected.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:isSelected()
  print("isSelected:", v)
end

--@api-stub: Radio_Button:setSelected
-- Sets the selected of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setSelected(true)
end

--@api-stub: Radio_Button:getGroup
-- Returns the group of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  local v = rb:getGroup()
  print("getGroup:", v)
end

--@api-stub: Radio_Button:setGroup
-- Sets the group of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setGroup(1)
end

--@api-stub: Radio_Button:setOnChange
-- Sets the on change of this radio_button.
do
  local rb = new_example_image_widget():newRadioButton("rb_easy","Easy","diff")
  rb:setOnChange(function() print("event") end)
end

-- Scroll_Bar methods

--@api-stub: Scroll_Bar:getScrollPosition
-- Returns the scroll position of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: Scroll_Bar:setScrollPosition
-- Sets the scroll position of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setScrollPosition(100, 200)
end

--@api-stub: Scroll_Bar:getContentSize
-- Returns the content size of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: Scroll_Bar:setContentSize
-- Sets the content size of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setContentSize(200, 50)
end

--@api-stub: Scroll_Bar:getViewSize
-- Returns the view size of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:getViewSize()
  print("getViewSize:", v)
end

--@api-stub: Scroll_Bar:setViewSize
-- Sets the view size of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setViewSize(200, 50)
end

--@api-stub: Scroll_Bar:isVertical
-- Returns true if this scroll_bar vertical.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  local v = sb:isVertical()
  print("isVertical:", v)
end

--@api-stub: Scroll_Bar:setOnChange
-- Sets the on change of this scroll_bar.
do
  local sb = new_example_image_widget():newScrollBar("vertical", 0, 100)
  sb:setOnChange(function() print("event") end)
end

-- Gui_Window methods

--@api-stub: Gui_Window:getTitle
-- Returns the title of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  local v = w:getTitle()
  print("getTitle:", v)
end

--@api-stub: Gui_Window:setTitle
-- Sets the title of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  w:setTitle("Hello")
end

--@api-stub: Gui_Window:isCloseable
-- Returns true if this gui_window closeable.
do
  local w = new_example_image_widget():newPanel()
  local v = w:isCloseable()
  print("isCloseable:", v)
end

--@api-stub: Gui_Window:setCloseable
-- Sets the closeable of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  w:setCloseable(1)
end

--@api-stub: Gui_Window:isDraggable
-- Returns true if this gui_window draggable.
do
  local w = new_example_image_widget():newPanel()
  local v = w:isDraggable()
  print("isDraggable:", v)
end

--@api-stub: Gui_Window:setDraggable
-- Sets the draggable of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  w:setDraggable(1)
end

--@api-stub: Gui_Window:isResizable
-- Returns true if this gui_window resizable.
do
  local w = new_example_image_widget():newPanel()
  local v = w:isResizable()
  print("isResizable:", v)
end

--@api-stub: Gui_Window:setResizable
-- Sets the resizable of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  w:setResizable(true)
end

--@api-stub: Gui_Window:setOnClose
-- Sets the on close of this gui_window.
do
  local w = new_example_image_widget():newPanel()
  w:setOnClose(function() print("event") end)
end

-- Split_Panel methods

--@api-stub: Split_Panel:getOrientation
-- Returns the orientation of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Split_Panel:setOrientation
-- Sets the orientation of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setOrientation("horizontal")
end

--@api-stub: Split_Panel:getSplitPosition
-- Returns the split position of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getSplitPosition()
  print("getSplitPosition:", v)
end

--@api-stub: Split_Panel:setSplitPosition
-- Sets the split position of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setSplitPosition(100, 200)
end

--@api-stub: Split_Panel:getMinPanelSize
-- Returns the min panel size of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getMinPanelSize()
  print("getMinPanelSize:", v)
end

--@api-stub: Split_Panel:setMinPanelSize
-- Sets the min panel size of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setMinPanelSize(200, 50)
end

--@api-stub: Split_Panel:setFirstChild
-- Sets the first child of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setFirstChild(1)
end

--@api-stub: Split_Panel:setSecondChild
-- Sets the second child of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  split:setSecondChild(function() print("event") end)
end

--@api-stub: Split_Panel:getFirstChild
-- Returns the first child of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getFirstChild()
  print("getFirstChild:", v)
end

--@api-stub: Split_Panel:getSecondChild
-- Returns the second child of this split_panel.
do
  local split = new_example_image_widget():newSplitPanel("horizontal", 0.5)
  local v = split:getSecondChild()
  print("getSecondChild:", v)
end

-- Dock_Panel methods

--@api-stub: Dock_Panel:dock
-- Docks a child widget into this dock_panel panel.
do
  local dock = new_example_image_widget():newDockPanel()
  dock:dock()
end

--@api-stub: Dock_Panel:undock
-- Undocks a previously docked widget from this dock_panel panel.
do
  local dock = new_example_image_widget():newDockPanel()
  dock:undock()
end

--@api-stub: Dock_Panel:getDockedCount
-- Returns the number of docked items in this dock_panel.
do
  local dock = new_example_image_widget():newDockPanel()
  local v = dock:getDockedCount()
  print("getDockedCount:", v)
end

--@api-stub: Dock_Panel:setSplitSize
-- Sets the split size of this dock_panel.
do
  local dock = new_example_image_widget():newDockPanel()
  dock:setSplitSize(200, 50)
end

--@api-stub: Dock_Panel:getSplitSize
-- Returns the split size of this dock_panel.
do
  local dock = new_example_image_widget():newDockPanel()
  local v = dock:getSplitSize()
  print("getSplitSize:", v)
end

-- Toolbar methods

--@api-stub: Toolbar:getOrientation
-- Returns the orientation of this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  local v = tb:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: Toolbar:setOrientation
-- Sets the orientation of this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  tb:setOrientation("horizontal")
end

--@api-stub: Toolbar:addButton
-- Adds a button to this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  tb:addButton(1)
end

--@api-stub: Toolbar:addSeparator
-- Adds a separator to this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  tb:addSeparator(1)
end

--@api-stub: Toolbar:addSpacer
-- Adds a spacer to this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  tb:addSpacer(1)
end

--@api-stub: Toolbar:getButton
-- Returns the button of this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  local v = tb:getButton()
  print("getButton:", v)
end

--@api-stub: Toolbar:setButtonEnabled
-- Sets whether this toolbar is enabled and accepts input.
do
  local tb = new_example_image_widget():newToolbar()
  tb:setButtonEnabled(true)
end

--@api-stub: Toolbar:setButtonToggled
-- Sets the button toggled of this toolbar.
do
  local tb = new_example_image_widget():newToolbar()
  tb:setButtonToggled(function() print("event") end)
end

--@api-stub: Toolbar:isButtonToggled
-- Returns true if this toolbar button toggled.
do
  local tb = new_example_image_widget():newToolbar()
  local v = tb:isButtonToggled()
  print("isButtonToggled:", v)
end

-- Menu_Bar methods

--@api-stub: Menu_Bar:addMenu
-- Adds a menu to this menu_bar.
do
  local mb = new_example_image_widget():newMenuBar()
  local child = new_example_image_widget():newButton("child_1", "Child")
  mb:addMenu(child)
end

--@api-stub: Menu_Bar:removeMenu
-- Removes a menu from this menu_bar.
do
  local mb = new_example_image_widget():newMenuBar()
  mb:removeMenu()
end

--@api-stub: Menu_Bar:getMenus
-- Returns the menus of this menu_bar.
do
  local mb = new_example_image_widget():newMenuBar()
  local v = mb:getMenus()
  print("getMenus:", v)
end

--@api-stub: Menu_Bar:getMenuCount
-- Returns the number of menu items in this menu_bar.
do
  local mb = new_example_image_widget():newMenuBar()
  local v = mb:getMenuCount()
  print("getMenuCount:", v)
end

-- Menu_Item methods

--@api-stub: Menu_Item:getText
-- Returns the text of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getText()
  print("getText:", v)
end

--@api-stub: Menu_Item:setText
-- Sets the text of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setText("Hello")
end

--@api-stub: Menu_Item:getShortcut
-- Returns the shortcut of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getShortcut()
  print("getShortcut:", v)
end

--@api-stub: Menu_Item:setShortcut
-- Sets the shortcut of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setShortcut(1)
end

--@api-stub: Menu_Item:isChecked
-- Returns true if this menu_item checked.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:isChecked()
  print("isChecked:", v)
end

--@api-stub: Menu_Item:setChecked
-- Sets the checked of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setChecked(true)
end

--@api-stub: Menu_Item:addSubItem
-- Adds a sub item to this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:addSubItem("item_1")
end

--@api-stub: Menu_Item:getSubItems
-- Returns the sub items of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  local v = mi:getSubItems()
  print("getSubItems:", v)
end

--@api-stub: Menu_Item:setOnClick
-- Sets the on click of this menu_item.
do
  local mi = new_example_image_widget():newMenuItem("New Game")
  mi:setOnClick(function() print("event") end)
end

-- Dialog methods

--@api-stub: Dialog:getTitle
-- Returns the title of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:getTitle()
  print("getTitle:", v)
end

--@api-stub: Dialog:setTitle
-- Sets the title of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setTitle("Hello")
end

--@api-stub: Dialog:isModal
-- Returns true if this dialog modal.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:isModal()
  print("isModal:", v)
end

--@api-stub: Dialog:setModal
-- Sets the modal of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setModal(true)
end

--@api-stub: Dialog:isOpen
-- Returns true if this dialog open.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:isOpen()
  print("isOpen:", v)
end

--@api-stub: Dialog:open
-- Performs the open operation on this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:open()
end

--@api-stub: Dialog:close
-- Performs the close operation on this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:close()
end

--@api-stub: Dialog:setOnClose
-- Sets the on close of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setOnClose(function() print("event") end)
end

--@api-stub: Dialog:setContent
-- Sets the content of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:setContent(function() print("event") end)
end

--@api-stub: Dialog:getContent
-- Returns the content of this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  local v = dlg:getContent()
  print("getContent:", v)
end

--@api-stub: Dialog:addButton
-- Adds a button to this dialog.
do
  local dlg = new_example_image_widget():newDialog("dlg_quit", "Quit?")
  dlg:addButton(1)
end

-- Status_Bar methods

--@api-stub: Status_Bar:addSection
-- Adds a section to this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  sb:addSection(1)
end

--@api-stub: Status_Bar:setSectionText
-- Sets the section text of this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionText("Hello")
end

--@api-stub: Status_Bar:getSectionText
-- Returns the section text of this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  local v = sb:getSectionText()
  print("getSectionText:", v)
end

--@api-stub: Status_Bar:getSectionCount
-- Returns the number of section items in this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  local v = sb:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Status_Bar:setSectionCount
-- Sets the section count of this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionCount(4)
end

--@api-stub: Status_Bar:setSectionWidget
-- Sets the section widget of this status_bar.
do
  local sb = new_example_image_widget():newStatusBar()
  sb:setSectionWidget("primary")
end

-- Accordion methods

--@api-stub: Accordion:addSection
-- Adds a section to this accordion.
do
  local acc = new_example_image_widget():newAccordion()
  acc:addSection(1)
end

--@api-stub: Accordion:getSectionCount
-- Returns the number of section items in this accordion.
do
  local acc = new_example_image_widget():newAccordion()
  local v = acc:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: Accordion:toggleSection
-- Toggles the section state of this accordion.
do
  local acc = new_example_image_widget():newAccordion()
  acc:toggleSection()
end

--@api-stub: Accordion:isSectionExpanded
-- Returns true if this accordion section expanded.
do
  local acc = new_example_image_widget():newAccordion()
  local v = acc:isSectionExpanded()
  print("isSectionExpanded:", v)
end

--@api-stub: Accordion:isExclusive
-- Returns true if this accordion exclusive.
do
  local acc = new_example_image_widget():newAccordion()
  local v = acc:isExclusive()
  print("isExclusive:", v)
end

--@api-stub: Accordion:setExclusive
-- Sets the exclusive of this accordion.
do
  local acc = new_example_image_widget():newAccordion()
  acc:setExclusive(1)
end

--@api-stub: Accordion:getSectionTitle
-- Returns the section title of this accordion.
do
  local acc = new_example_image_widget():newAccordion()
  local v = acc:getSectionTitle()
  print("getSectionTitle:", v)
end

-- Tooltip_Panel methods

--@api-stub: Tooltip_Panel:getText
-- Returns the text of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getText()
  print("getText:", v)
end

--@api-stub: Tooltip_Panel:setText
-- Sets the text of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setText("Hello")
end

--@api-stub: Tooltip_Panel:getDelay
-- Returns the delay of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getDelay()
  print("getDelay:", v)
end

--@api-stub: Tooltip_Panel:setDelay
-- Sets the delay of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setDelay(2.0)
end

--@api-stub: Tooltip_Panel:getTarget
-- Returns the target of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  local v = tip:getTarget()
  print("getTarget:", v)
end

--@api-stub: Tooltip_Panel:setTarget
-- Sets the target of this tooltip_panel.
do
  local tip = new_example_image_widget():newTooltipPanel("Click to attack")
  tip:setTarget(1)
end

-- Color_Picker methods

--@api-stub: Color_Picker:getColor
-- Returns the color of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getColor()
  print("getColor:", v)
end

--@api-stub: Color_Picker:setColor
-- Sets the color of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setColor({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:getShowAlpha
-- Returns the show alpha of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getShowAlpha()
  print("getShowAlpha:", v)
end

--@api-stub: Color_Picker:setShowAlpha
-- Sets the show alpha of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setShowAlpha(0.85)
end

--@api-stub: Color_Picker:getColorMode
-- Returns the color mode of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  local v = cp:getColorMode()
  print("getColorMode:", v)
end

--@api-stub: Color_Picker:setColorMode
-- Sets the color mode of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setColorMode({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Color_Picker:setOnChange
-- Sets the on change of this color_picker.
do
  local cp = new_example_image_widget():newColorPicker({1,0,0,1})
  cp:setOnChange(function() print("event") end)
end

-- Gui_Table methods

--@api-stub: Gui_Table:addColumn
-- Adds a column to this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:addColumn("item_1")
end

--@api-stub: Gui_Table:getColumnCount
-- Returns the number of column items in this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getColumnCount()
  print("getColumnCount:", v)
end

--@api-stub: Gui_Table:addRow
-- Adds a row to this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:addRow("item_1")
end

--@api-stub: Gui_Table:getRowCount
-- Returns the number of row items in this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getRowCount()
  print("getRowCount:", v)
end

--@api-stub: Gui_Table:getCell
-- Returns the cell of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getCell()
  print("getCell:", v)
end

--@api-stub: Gui_Table:setCell
-- Sets the cell of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setCell(1)
end

--@api-stub: Gui_Table:getSelectedRow
-- Returns the selected row of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:getSelectedRow()
  print("getSelectedRow:", v)
end

--@api-stub: Gui_Table:setSelectedRow
-- Sets the selected row of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setSelectedRow(true)
end

--@api-stub: Gui_Table:isSortable
-- Returns true if this gui_table sortable.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  local v = tbl:isSortable()
  print("isSortable:", v)
end

--@api-stub: Gui_Table:setSortable
-- Sets the sortable of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setSortable(1)
end

--@api-stub: Gui_Table:setOnSelect
-- Sets the on select of this gui_table.
do
  local tbl = new_example_image_widget():newTable({"Name","Score"})
  tbl:setOnSelect(function() print("event") end)
end

-- Image_Widget methods

--@api-stub: Image_Widget:getScaleMode
-- Returns the scale mode of this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getScaleMode()
  print("getScaleMode:", v)
end

--@api-stub: Image_Widget:setScaleMode
-- Sets the scale mode of this image_widget.
do
  local img = new_example_image_widget()
  img:setScaleMode(1.5)
end

--@api-stub: Image_Widget:getTint
-- Returns the tint of this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getTint()
  print("getTint:", v)
end

--@api-stub: Image_Widget:setTint
-- Sets the tint of this image_widget.
do
  local img = new_example_image_widget()
  img:setTint({0.2, 0.6, 1.0, 1.0})
end

--@api-stub: Image_Widget:newButton
-- Creates and returns a new button widget or object.
do
  local img = new_example_image_widget()
  img:newButton()
end

--@api-stub: Image_Widget:newLabel
-- Creates and returns a new label widget or object.
do
  local img = new_example_image_widget()
  img:newLabel()
end

--@api-stub: Image_Widget:newTextInput
-- Creates and returns a new text input widget or object.
do
  local img = new_example_image_widget()
  img:newTextInput()
end

--@api-stub: Image_Widget:newCheckbox
-- Creates and returns a new checkbox widget or object.
do
  local img = new_example_image_widget()
  img:newCheckbox()
end

--@api-stub: Image_Widget:newSlider
-- Creates and returns a new slider widget or object.
do
  local img = new_example_image_widget()
  img:newSlider()
end

--@api-stub: Image_Widget:newProgressBar
-- Creates and returns a new progress bar widget or object.
do
  local img = new_example_image_widget()
  img:newProgressBar()
end

--@api-stub: Image_Widget:newComboBox
-- Creates and returns a new combo box widget or object.
do
  local img = new_example_image_widget()
  img:newComboBox()
end

--@api-stub: Image_Widget:newList
-- Creates and returns a new list widget or object.
do
  local img = new_example_image_widget()
  img:newList()
end

--@api-stub: Image_Widget:newPanel
-- Creates and returns a new panel widget or object.
do
  local img = new_example_image_widget()
  img:newPanel()
end

--@api-stub: Image_Widget:newLayout
-- Creates and returns a new layout widget or object.
do
  local img = new_example_image_widget()
  img:newLayout()
end

--@api-stub: Image_Widget:newScrollPanel
-- Creates and returns a new scroll panel widget or object.
do
  local img = new_example_image_widget()
  img:newScrollPanel()
end

--@api-stub: Image_Widget:newNinePatch
-- Creates and returns a new nine patch widget or object.
do
  local img = new_example_image_widget()
  img:newNinePatch()
end

--@api-stub: Image_Widget:newTabBar
-- Creates and returns a new tab bar widget or object.
do
  local img = new_example_image_widget()
  img:newTabBar()
end

--@api-stub: Image_Widget:newSeparator
-- Creates and returns a new separator widget or object.
do
  local img = new_example_image_widget()
  img:newSeparator()
end

--@api-stub: Image_Widget:newSpacer
-- Creates and returns a new spacer widget or object.
do
  local img = new_example_image_widget()
  img:newSpacer()
end

--@api-stub: Image_Widget:newToast
-- Creates and returns a new toast widget or object.
do
  local img = new_example_image_widget()
  img:newToast()
end

--@api-stub: Image_Widget:newTreeView
-- Creates and returns a new tree view widget or object.
do
  local img = new_example_image_widget()
  img:newTreeView()
end

--@api-stub: Image_Widget:newRadioButton
-- Creates and returns a new radio button widget or object.
do
  local img = new_example_image_widget()
  img:newRadioButton()
end

--@api-stub: Image_Widget:newScrollBar
-- Creates and returns a new scroll bar widget or object.
do
  local img = new_example_image_widget()
  img:newScrollBar()
end

--@api-stub: Image_Widget:newWindow
-- Creates and returns a new window widget or object.
do
  local img = new_example_image_widget()
  img:newWindow()
end

--@api-stub: Image_Widget:newSplitPanel
-- Creates and returns a new split panel widget or object.
do
  local img = new_example_image_widget()
  img:newSplitPanel()
end

--@api-stub: Image_Widget:newDockPanel
-- Creates and returns a new dock panel widget or object.
do
  local img = new_example_image_widget()
  img:newDockPanel()
end

--@api-stub: Image_Widget:newToolbar
-- Creates and returns a new toolbar widget or object.
do
  local img = new_example_image_widget()
  img:newToolbar()
end

--@api-stub: Image_Widget:newMenuBar
-- Creates and returns a new menu bar widget or object.
do
  local img = new_example_image_widget()
  img:newMenuBar()
end

--@api-stub: Image_Widget:newMenuItem
-- Creates and returns a new menu item widget or object.
do
  local img = new_example_image_widget()
  img:newMenuItem()
end

--@api-stub: Image_Widget:newDialog
-- Creates and returns a new dialog widget or object.
do
  local img = new_example_image_widget()
  img:newDialog()
end

--@api-stub: Image_Widget:newStatusBar
-- Creates and returns a new status bar widget or object.
do
  local img = new_example_image_widget()
  img:newStatusBar()
end

--@api-stub: Image_Widget:newAccordion
-- Creates and returns a new accordion widget or object.
do
  local img = new_example_image_widget()
  img:newAccordion()
end

--@api-stub: Image_Widget:newTooltipPanel
-- Creates and returns a new tooltip panel widget or object.
do
  local img = new_example_image_widget()
  img:newTooltipPanel()
end

--@api-stub: Image_Widget:newColorPicker
-- Creates and returns a new color picker widget or object.
do
  local img = new_example_image_widget()
  img:newColorPicker()
end

--@api-stub: Image_Widget:newTable
-- Creates and returns a new table widget or object.
do
  local img = new_example_image_widget()
  img:newTable()
end

--@api-stub: Image_Widget:newImageWidget
-- Creates and returns a new image widget widget or object.
do
  local img = new_example_image_widget()
  img:newImageWidget()
end

--@api-stub: Image_Widget:newTheme
-- Creates and returns a new theme widget or object.
do
  local img = new_example_image_widget()
  img:newTheme()
end

--@api-stub: Image_Widget:setTheme
-- Sets the theme of this image_widget.
do
  local img = new_example_image_widget()
  img:setTheme("dark")
end

--@api-stub: Image_Widget:getTheme
-- Returns the theme of this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getTheme()
  print("getTheme:", v)
end

--@api-stub: Image_Widget:getRoot
-- Returns the root of this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getRoot()
  print("getRoot:", v)
end

--@api-stub: Image_Widget:setFocus
-- Sets the focus of this image_widget.
do
  local img = new_example_image_widget()
  img:setFocus(1)
end

--@api-stub: Image_Widget:getFocus
-- Returns the focus of this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getFocus()
  print("getFocus:", v)
end

--@api-stub: Image_Widget:focusNext
-- Performs the focus next operation on this image_widget.
do
  local img = new_example_image_widget()
  img:focusNext()
end

--@api-stub: Image_Widget:focusPrev
-- Performs the focus prev operation on this image_widget.
do
  local img = new_example_image_widget()
  img:focusPrev()
end

--@api-stub: Image_Widget:clearFocus
-- Clears all focus items from this image_widget.
do
  local img = new_example_image_widget()
  img:clearFocus()
end

--@api-stub: Image_Widget:addToast
-- Adds a toast to this image_widget.
do
  local img = new_example_image_widget()
  img:addToast(1)
end

--@api-stub: Image_Widget:getToastCount
-- Returns the number of toast items in this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getToastCount()
  print("getToastCount:", v)
end

--@api-stub: Image_Widget:mousepressed
-- Forwards a mouse press event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:mousepressed()
end

--@api-stub: Image_Widget:mousereleased
-- Forwards a mouse release event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:mousereleased()
end

--@api-stub: Image_Widget:mousemoved
-- Forwards a mouse move event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:mousemoved()
end
--@api-stub: Image_Widget:keypressed
-- Forwards a key press event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:keypressed()
end

--@api-stub: Image_Widget:textinput
-- Forwards a text input event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:textinput()
end

--@api-stub: Image_Widget:wheelmoved
-- Forwards a mouse wheel event to this image_widget for input handling.
do
  local img = new_example_image_widget()
  img:wheelmoved()
end

--@api-stub: Image_Widget:update
-- Advances this image_widget by the given delta time.
do
  local img = new_example_image_widget()
  img:update()
end

--@api-stub: Image_Widget:draw
-- Draws or renders this image_widget to the current render target.
do
  local img = new_example_image_widget()
  img:draw()
end

--@api-stub: Image_Widget:getWidgetCount
-- Returns the number of widget items in this image_widget.
do
  local img = new_example_image_widget()
  local v = img:getWidgetCount()
  print("getWidgetCount:", v)
end

--@api-stub: Image_Widget:drawToImage
-- Draws or renders this image_widget to the current render target.
do
  local img = new_example_image_widget()
  img:drawToImage()
end

--@api-stub: Image_Widget:newLineChart
-- Creates and returns a new line chart widget or object.
do
  local img = new_example_image_widget()
  img:newLineChart()
end

--@api-stub: Image_Widget:newBarChart
-- Creates and returns a new bar chart widget or object.
do
  local img = new_example_image_widget()
  img:newBarChart()
end

--@api-stub: Image_Widget:newScatterPlot
-- Creates and returns a new scatter plot widget or object.
do
  local img = new_example_image_widget()
  img:newScatterPlot()
end

--@api-stub: Image_Widget:newPieChart
-- Creates and returns a new pie chart widget or object.
do
  local img = new_example_image_widget()
  img:newPieChart()
end

--@api-stub: Image_Widget:newAreaChart
-- Creates and returns a new area chart widget or object.
do
  local img = new_example_image_widget()
  img:newAreaChart()
end

--@api-stub: Image_Widget:parseWidgetState
-- Performs the parse widget state operation on this image_widget.
do
  local img = new_example_image_widget()
  img:parseWidgetState()
end

--@api-stub: Image_Widget:newSpinBox
-- Creates and returns a new spin box widget or object.
do
  local img = new_example_image_widget()
  img:newSpinBox()
end

--@api-stub: Image_Widget:newSwitch
-- Creates and returns a new switch widget or object.
do
  local img = new_example_image_widget()
  img:newSwitch()
end

--@api-stub: Image_Widget:newBadge
-- Creates and returns a new badge widget or object.
do
  local img = new_example_image_widget()
  img:newBadge()
end

--@api-stub: Image_Widget:setDefaultTheme
-- Sets the default theme of this image_widget.
do
  local img = new_example_image_widget()
  img:setDefaultTheme("dark")
end

--@api-stub: Image_Widget:setViewport
-- Sets the viewport of this image_widget.
do
  local img = new_example_image_widget()
  img:setViewport(1)
end

--@api-stub: Image_Widget:flushCache
-- Performs the flush cache operation on this image_widget.
do
  local img = new_example_image_widget()
  img:flushCache()
end

--@api-stub: Image_Widget:update_bindings
-- Advances _bindings this image_widget by the given delta time.
do
  local img = new_example_image_widget()
  img:update_bindings()
end

--@api-stub: Image_Widget:loadLayout
-- Loads layout into this image_widget.
do
  local img = new_example_image_widget()
  img:loadLayout()
end

--@api-stub: Image_Widget:loadLayoutFile
-- Loads layout file into this image_widget.
do
  local img = new_example_image_widget()
  img:loadLayoutFile()
end

--@api-stub: Image_Widget:renderToImage
-- Draws or renders this image_widget to the current render target.
do
  local img = new_example_image_widget()
  img:renderToImage()
end

-- LineChart methods

--@api-stub: LineChart:setYMax
-- Sets the y max of this line chart.
do
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:setYMax(100)
end

--@api-stub: LineChart:setXMax
-- Sets the x max of this line chart.
do
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:setXMax(100)
end

--@api-stub: LineChart:drawToImage
-- Draws or renders this line chart to the current render target.
do
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
  chart:drawToImage()
end

-- BarChart methods

--@api-stub: BarChart:drawToImage
-- Draws or renders this bar chart to the current render target.
do
  local w = new_example_image_widget():newPanel()
  w:drawToImage()
end

-- ScatterPlot methods

--@api-stub: ScatterPlot:setXRange
-- Sets the x range of this scatter plot.
do
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setXRange(1)
end

--@api-stub: ScatterPlot:setYRange
-- Sets the y range of this scatter plot.
do
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setYRange(1)
end

--@api-stub: ScatterPlot:drawToImage
-- Draws or renders this scatter plot to the current render target.
do
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
  plot:drawToImage()
end

-- PieChart methods

--@api-stub: PieChart:drawToImage
-- Draws or renders this pie chart to the current render target.
do
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
  chart:drawToImage()
end

-- AreaChart methods

--@api-stub: AreaChart:setYMax
-- Sets the y max of this area chart.
do
  local w = new_example_image_widget():newPanel()
  w:setYMax(100)
end

--@api-stub: AreaChart:drawToImage
-- Draws or renders this area chart to the current render target.
do
  local w = new_example_image_widget():newPanel()
  w:drawToImage()
end

-- Custom widget extensibility

--@api-stub: Image_Widget:newCustomWidget
-- Creates and returns a new custom widget widget or object.
do
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


--@api-stub: BarChart:addCategory
-- Adds a category to this bar chart.
do
  lurek.log.info("BarChart:addCategory usage: chart:addCategory('Jan')", "ui")
  local bc = new_example_image_widget():newBarChart(200, 100)
  bc:addCategory("Jan")
  bc:addCategory("Feb")
  lurek.log.info("categories added", "ui")
end

--@api-stub: AreaChart:addLayer
-- Adds a layer to this area chart.
do
  local ac = new_example_image_widget():newAreaChart(300, 150)
  ac:addLayer("series_a", {1,0.3,0.3,0.7}, {10,20,15,30,25})
  ac:addLayer("series_b", {0.3,0.6,1,0.7}, {5,10,8,14,12})
  lurek.log.info("area layers added", "ui")
end

--@api-stub: PieChart:addSegment
-- Adds a segment to this pie chart.
do
  local pc = new_example_image_widget():newPieChart(150, 150)
  pc:addSegment("Wheat",  40, {0.9, 0.8, 0.3, 1})
  pc:addSegment("Sheep",  25, {0.8, 0.9, 0.5, 1})
  pc:addSegment("Forest", 35, {0.2, 0.7, 0.3, 1})
  lurek.log.info("pie segments added", "ui")
end

--@api-stub: LineChart:addSeries
-- Adds a series to this line chart.
do
  local lc = new_example_image_widget():newLineChart(300, 150)
  lc:addSeries("revenue", {0.2, 0.8, 0.4, 1}, {10, 20, 15, 35, 30})
  lc:addSeries("cost",    {0.9, 0.3, 0.2, 1}, {8,  12, 10, 18, 20})
  lurek.log.info("line series added", "ui")
end

--@api-stub: BarChart:addSeries
-- Adds a series to this bar chart.
do
  local bc = new_example_image_widget():newBarChart(300, 150)
  bc:addCategory("Q1"); bc:addCategory("Q2")
  bc:addSeries("sales",   {0.2, 0.6, 0.9, 1}, {120, 180})
  bc:addSeries("returns", {0.9, 0.3, 0.2, 1}, {10,  15})
  lurek.log.info("bar series added", "ui")
end

--@api-stub: ScatterPlot:addSeries
-- Adds a series to this scatter plot.
do
  local sp = new_example_image_widget():newScatterPlot(200, 200)
  sp:addSeries("players", {0.2, 0.7, 1, 1}, {10,20, 30,40, 50,35, 70,55})
  sp:setXRange(0, 100); sp:setYRange(0, 80)
  lurek.log.info("scatter series added", "ui")
end

--@api-stub: Theme:setStyle
-- Sets the style of this theme.
do
  local theme = new_example_image_widget():newTheme()
  theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
  theme:setStyle("button.text_color",  {1, 1, 1, 1})
  lurek.log.info("theme styles set", "ui")
end

-- LineChart methods


--@api-stub: LineChart:type
-- Returns the Lua-visible type name string for this line chart handle.
do
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  local t = chart:type()
  lurek.log.info("LineChart:type = " .. t, "ui")
end
--@api-stub: LineChart:typeOf
-- Returns true if this line chart handle matches the given type name string.
do
  local chart = new_example_image_widget():newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  lurek.log.info("is LineChart: " .. tostring(chart:typeOf("LineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end


-- LAreaChart methods


--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local w = new_example_image_widget():newPanel()
    w:setYMax(100)
  local t = w:type()
  lurek.log.info("LAreaChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local w = new_example_image_widget():newPanel()
    w:setYMax(100)
  lurek.log.info("is LAreaChart: " .. tostring(w:typeOf("LAreaChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LBarChart:type
-- Returns the type name of this object
do
  local w = new_example_image_widget():newPanel()
    w:drawToImage()
  local t = w:type()
  lurek.log.info("LBarChart:type = " .. t, "ui")
end
--@api-stub: LBarChart:typeOf
-- Checks whether this object matches the given type name
do
  local w = new_example_image_widget():newPanel()
    w:drawToImage()
  lurek.log.info("is LBarChart: " .. tostring(w:typeOf("LBarChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LLineChart:type
-- Returns the type name of this object
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Sales" })
  local t = chart:type()
  lurek.log.info("LLineChart:type=" .. t, "ui")
end
--@api-stub: LLineChart:typeOf
-- Checks whether this object matches the given type name
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Revenue" })
  lurek.log.info("is LLineChart: " .. tostring(chart:typeOf("LLineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LPieChart:type
-- Returns the type name of this object
do
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
    chart:drawToImage()
  local t = chart:type()
  lurek.log.info("LPieChart:type = " .. t, "ui")
end
--@api-stub: LPieChart:typeOf
-- Checks whether this object matches the given type name
do
  local chart = new_example_image_widget():newPieChart({{label="HP",value=70}})
    chart:drawToImage()
  lurek.log.info("is LPieChart: " .. tostring(chart:typeOf("LPieChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LScatterPlot:type
-- Returns the type name of this object
do
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1)
  local t = plot:type()
  lurek.log.info("LScatterPlot:type = " .. t, "ui")
end
--@api-stub: LScatterPlot:typeOf
-- Checks whether this object matches the given type name
do
  local plot = new_example_image_widget():newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1)
  lurek.log.info("is LScatterPlot: " .. tostring(plot:typeOf("LScatterPlot")), "ui")
  lurek.log.info("is wrong: " .. tostring(plot:typeOf("Unknown")), "ui")
end
--@api-stub: LTheme:type
-- Returns the type name of this object
do
  local theme = new_example_image_widget():newTheme()
    theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
    theme:setStyle("button.text_color",  {1, 1, 1, 1})
  local t = theme:type()
  lurek.log.info("LTheme:type = " .. t, "ui")
end
--@api-stub: LTheme:typeOf
-- Checks whether this object matches the given type name
do
  local theme = new_example_image_widget():newTheme()
    theme:setStyle("button.background", {0.2, 0.4, 0.8, 1})
    theme:setStyle("button.text_color",  {1, 1, 1, 1})
  lurek.log.info("is LTheme: " .. tostring(theme:typeOf("LTheme")), "ui")
  lurek.log.info("is wrong: " .. tostring(theme:typeOf("Unknown")), "ui")
end

--@api-stub: lurek.ui.type
-- Returns the Lua-visible type name string for this ui handle.
do
  local chart = lurek.ui.newLineChart({ width = 200, height = 150, title = "FPS" })
  local t = chart:type()
  lurek.log.info("ui.type=" .. tostring(t), "ui")
end
--@api-stub: LLineChart:setYMax
-- Sets the maximum Y-axis value for this line chart
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Score" })
  chart:setYMax(1000)
  lurek.log.info("y-axis max set to 1000", "ui")
end
--@api-stub: LLineChart:setXMax
-- Sets the maximum X-axis value for this line chart
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "FPS" })
  chart:setXMax(60)   -- fixed 60-second window
  lurek.log.info("x-axis max set to 60", "ui")
end
--@api-stub: LLineChart:drawToImage
-- Renders this line chart to an image buffer
do
  local chart = lurek.ui.newLineChart({ width = 256, height = 128, title = "Wave" })
  chart:setXMax(10)
  chart:setYMax(1.0)
  local idata = lurek.image.newImageData(256, 128)
  chart:drawToImage(idata)
  lurek.log.info("chart rendered to ImageData 256x128", "ui")
end

--@api-stub: lurek.ui.newButton
-- Creates a new button widget
do
  local btn = lurek.ui.newButton("Play")
  lurek.log.info("newButton: " .. tostring(btn), "ui")
end


--@api-stub: lurek.ui.newLabel
-- Creates a new label widget
do
  local lbl = lurek.ui.newLabel("Score: 0")
  lurek.log.info("newLabel: " .. tostring(lbl), "ui")
end


--@api-stub: lurek.ui.newTextInput
-- Creates a new text input widget
do
  local input = lurek.ui.newTextInput()
  lurek.log.info("newTextInput: " .. tostring(input), "ui")
end


--@api-stub: lurek.ui.newCheckbox
-- Creates a new checkbox widget
do
  local cb = lurek.ui.newCheckbox("Enable music")
  lurek.log.info("newCheckbox: " .. tostring(cb), "ui")
end


--@api-stub: lurek.ui.newSlider
-- Creates a new slider widget
do
  local slider = lurek.ui.newSlider(0, 100)
  lurek.log.info("newSlider: " .. tostring(slider), "ui")
end


--@api-stub: lurek.ui.newProgressBar
-- Creates a new progress bar widget
do
  local bar = lurek.ui.newProgressBar(0, 100)
  lurek.log.info("newProgressBar: " .. tostring(bar), "ui")
end


--@api-stub: lurek.ui.newComboBox
-- Creates a new combo box (drop-down) widget
do
  local combo = lurek.ui.newComboBox()
  lurek.log.info("newComboBox: " .. tostring(combo), "ui")
end


--@api-stub: lurek.ui.newList
-- Creates a new list box widget
do
  local list = lurek.ui.newList()
  lurek.log.info("newList: " .. tostring(list), "ui")
end


--@api-stub: lurek.ui.newPanel
-- Creates a new panel widget (container)
do
  local panel = lurek.ui.newPanel()
  lurek.log.info("newPanel: " .. tostring(panel), "ui")
end


--@api-stub: lurek.ui.newLayout
-- Creates a new layout container widget
do
  local layout = lurek.ui.newLayout("horizontal")
  lurek.log.info("newLayout: " .. tostring(layout), "ui")
end


--@api-stub: lurek.ui.newScrollPanel
-- Creates a new scrollable panel widget
do
  local sp = lurek.ui.newScrollPanel()
  lurek.log.info("newScrollPanel: " .. tostring(sp), "ui")
end


--@api-stub: lurek.ui.newNinePatch
-- Creates a new nine-patch widget for scalable bordered images
do
  local np = lurek.ui.newNinePatch()
  lurek.log.info("newNinePatch: " .. tostring(np), "ui")
end


--@api-stub: lurek.ui.newTabBar
-- Creates a new tab bar widget
do
  local tabs = lurek.ui.newTabBar()
  lurek.log.info("newTabBar: " .. tostring(tabs), "ui")
end


--@api-stub: lurek.ui.newSeparator
-- Creates a new separator widget
do
  local sep = lurek.ui.newSeparator(false)
  lurek.log.info("newSeparator: " .. tostring(sep), "ui")
end


--@api-stub: lurek.ui.newSpacer
-- Creates a new spacer widget for spacing between other widgets
do
  local spacer = lurek.ui.newSpacer(20, 10)
  lurek.log.info("newSpacer: " .. tostring(spacer), "ui")
end


--@api-stub: lurek.ui.newToast
-- Creates a new toast notification widget
do
  local toast = lurek.ui.newToast("Item collected!", 3.0)
  lurek.log.info("newToast: " .. tostring(toast), "ui")
end


--@api-stub: lurek.ui.newTreeView
-- Creates a new tree view widget
do
  local tree = lurek.ui.newTreeView()
  lurek.log.info("newTreeView: " .. tostring(tree), "ui")
end


--@api-stub: lurek.ui.newRadioButton
-- Creates a new radio button widget
do
  local rb = lurek.ui.newRadioButton("Easy", "difficulty")
  lurek.log.info("newRadioButton: " .. tostring(rb), "ui")
end


--@api-stub: lurek.ui.newScrollBar
-- Creates a new scroll bar widget
do
  local sb = lurek.ui.newScrollBar(true)
  lurek.log.info("newScrollBar: " .. tostring(sb), "ui")
end


--@api-stub: lurek.ui.newWindow
-- Creates a new GUI window widget
do
  local win = lurek.ui.newWindow("Inventory")
  lurek.log.info("newWindow: " .. tostring(win), "ui")
end


--@api-stub: lurek.ui.newSplitPanel
-- Creates a new split panel widget with two resizable sub-panels
do
  local split = lurek.ui.newSplitPanel("vertical")
  lurek.log.info("newSplitPanel: " .. tostring(split), "ui")
end


--@api-stub: lurek.ui.newDockPanel
-- Creates a new dock panel widget for docking child widgets to sides
do
  local dock = lurek.ui.newDockPanel()
  lurek.log.info("newDockPanel: " .. tostring(dock), "ui")
end


--@api-stub: lurek.ui.newToolbar
-- Creates a new toolbar widget
do
  local tb = lurek.ui.newToolbar("horizontal")
  lurek.log.info("newToolbar: " .. tostring(tb), "ui")
end


--@api-stub: lurek.ui.newMenuBar
-- Creates a new menu bar widget
do
  local mb = lurek.ui.newMenuBar()
  lurek.log.info("newMenuBar: " .. tostring(mb), "ui")
end


--@api-stub: lurek.ui.newMenuItem
-- Creates a new menu item widget
do
  local mi = lurek.ui.newMenuItem("File")
  lurek.log.info("newMenuItem: " .. tostring(mi), "ui")
end


--@api-stub: lurek.ui.newDialog
-- Creates a new dialog widget
do
  local dlg = lurek.ui.newDialog("Confirm Exit")
  lurek.log.info("newDialog: " .. tostring(dlg), "ui")
end


--@api-stub: lurek.ui.newStatusBar
-- Creates a new status bar widget
do
  local sbar = lurek.ui.newStatusBar()
  lurek.log.info("newStatusBar: " .. tostring(sbar), "ui")
end


--@api-stub: lurek.ui.newAccordion
-- Creates a new accordion widget
do
  local acc = lurek.ui.newAccordion()
  lurek.log.info("newAccordion: " .. tostring(acc), "ui")
end


--@api-stub: lurek.ui.newTooltipPanel
-- Creates a new tooltip panel widget
do
  local tp = lurek.ui.newTooltipPanel("Hover info")
  lurek.log.info("newTooltipPanel: " .. tostring(tp), "ui")
end


--@api-stub: lurek.ui.newColorPicker
-- Creates a new color picker widget
do
  local cp = lurek.ui.newColorPicker()
  lurek.log.info("newColorPicker: " .. tostring(cp), "ui")
end


--@api-stub: lurek.ui.newTable
-- Creates a new table widget for tabular data display
do
  local tbl = lurek.ui.newTable()
  lurek.log.info("newTable: " .. tostring(tbl), "ui")
end


--@api-stub: lurek.ui.newImageWidget
-- Creates a new image display widget
do
  local iw = lurek.ui.newImageWidget()
  lurek.log.info("newImageWidget: " .. tostring(iw), "ui")
end


--@api-stub: lurek.ui.newTheme
-- Creates a new UI theme for styling widgets
do
  local theme = lurek.ui.newTheme()
  lurek.log.info("newTheme: " .. tostring(theme), "ui")
end


--@api-stub: lurek.ui.setTheme
-- Applies a theme to the UI context
do
  local theme = lurek.ui.newTheme()
  lurek.ui.setTheme(theme)
  lurek.log.info("theme applied", "ui")
end


--@api-stub: lurek.ui.getTheme
-- Returns whether a theme is currently set
do
  local theme = lurek.ui.getTheme()
  lurek.log.info("getTheme: " .. tostring(theme), "ui")
end


--@api-stub: lurek.ui.getRoot
-- Returns the root panel widget
do
  local root = lurek.ui.getRoot()
  lurek.log.info("root: " .. tostring(root), "ui")
end


--@api-stub: lurek.ui.setFocus
-- Sets keyboard focus to a widget, or clears focus if nil
do
  local btn = lurek.ui.newButton("Focus")
  lurek.ui.setFocus(btn)
  lurek.log.info("focus set", "ui")
end


--@api-stub: lurek.ui.getFocus
-- Returns the index of the currently focused widget, or nil
do
  local idx = lurek.ui.getFocus()
  lurek.log.info("focus idx=" .. tostring(idx), "ui")
end


--@api-stub: lurek.ui.focusNext
-- Moves keyboard focus to the next focusable widget
do
  lurek.ui.focusNext()
  lurek.log.info("focus moved next", "ui")
end


--@api-stub: lurek.ui.focusPrev
-- Moves keyboard focus to the previous focusable widget
do
  lurek.ui.focusPrev()
  lurek.log.info("focus moved prev", "ui")
end


--@api-stub: lurek.ui.clearFocus
-- Clears keyboard focus from all widgets
do
  lurek.ui.clearFocus()
  lurek.log.info("focus cleared", "ui")
end


--@api-stub: lurek.ui.addToast
-- Adds a toast notification to the queue
do
  lurek.ui.addToast({ message = "Achievement!", duration = 2.5 })
  lurek.log.info("toast queued", "ui")
end


--@api-stub: lurek.ui.getToastCount
-- Returns the number of active toast notifications
do
  local count = lurek.ui.getToastCount()
  lurek.log.info("toasts=" .. tostring(count), "ui")
end


--@api-stub: lurek.ui.mousepressed
-- Delivers a mouse press event to the UI
do
  local handled = lurek.ui.mousepressed(100.0, 200.0, 1)
  lurek.log.info("mousepressed=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.mousereleased
-- Delivers a mouse release event to the UI
do
  local handled = lurek.ui.mousereleased(100.0, 200.0, 1)
  lurek.log.info("mousereleased=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.mousemoved
-- Delivers a mouse move event to the UI
do
  local handled = lurek.ui.mousemoved(150.0, 250.0)
  lurek.log.info("mousemoved=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.keypressed
-- Delivers a key press event to the UI
do
  local handled = lurek.ui.keypressed("return")
  lurek.log.info("keypressed=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.textinput
-- Delivers a text input event to the UI
do
  local handled = lurek.ui.textinput("A")
  lurek.log.info("textinput=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.wheelmoved
-- Delivers a mouse wheel event to the UI
do
  local handled = lurek.ui.wheelmoved(0.0, 3.0)
  lurek.log.info("wheelmoved=" .. tostring(handled), "ui")
end


--@api-stub: lurek.ui.update
-- Updates the UI context and dispatches pending events to callbacks
do
  lurek.ui.update(0.016)
  lurek.log.info("ui updated", "ui")
end


--@api-stub: lurek.ui.draw
-- Invokes custom draw callbacks for all widgets that have one registered
do
  lurek.ui.draw()
  lurek.log.info("ui draw invoked", "ui")
end


--@api-stub: lurek.ui.newCustomWidget
-- Creates a new custom widget with optional initial configuration
do
  local cw = lurek.ui.newCustomWidget({ width = 100, height = 50 })
  lurek.log.info("newCustomWidget: " .. tostring(cw), "ui")
end


--@api-stub: lurek.ui.getWidgetCount
-- Returns the total number of widgets in the UI context
do
  local count = lurek.ui.getWidgetCount()
  lurek.log.info("widgets=" .. tostring(count), "ui")
end


--@api-stub: lurek.ui.drawToImage
-- Renders the entire UI to an image buffer
do
  local img = lurek.ui.drawToImage(128.0, 64.0)
  lurek.log.info("rendered to image: " .. tostring(img), "ui")
end


--@api-stub: lurek.ui.newLineChart
-- Creates a new line chart for data visualization
do
  local chart = lurek.ui.newLineChart({ width = 300, height = 200, title = "FPS" })
  lurek.log.info("newLineChart: " .. tostring(chart), "ui")
end


--@api-stub: lurek.ui.newBarChart
-- Creates a new bar chart for data visualization
do
  local chart = lurek.ui.newBarChart({ width = 300, height = 200, title = "Sales" })
  lurek.log.info("newBarChart: " .. tostring(chart), "ui")
end


--@api-stub: lurek.ui.newScatterPlot
-- Creates a new scatter plot for data visualization
do
  local plot = lurek.ui.newScatterPlot({ width = 300, height = 200, title = "Data" })
  lurek.log.info("newScatterPlot: " .. tostring(plot), "ui")
end


--@api-stub: lurek.ui.newPieChart
-- Creates a new pie chart for data visualization
do
  local chart = lurek.ui.newPieChart({ width = 200, height = 200, title = "Budget" })
  lurek.log.info("newPieChart: " .. tostring(chart), "ui")
end


--@api-stub: lurek.ui.newAreaChart
-- Creates a new area chart for data visualization
do
  local chart = lurek.ui.newAreaChart({ width = 300, height = 200, title = "Traffic" })
  lurek.log.info("newAreaChart: " .. tostring(chart), "ui")
end


--@api-stub: lurek.ui.parseWidgetState
-- Validates and normalizes a widget state string
do
  local state = lurek.ui.parseWidgetState("hovered")
  lurek.log.info("state=" .. tostring(state), "ui")
end


--@api-stub: lurek.ui.newSpinBox
-- Creates a new spin box (numeric stepper) widget
do
  local sb = lurek.ui.newSpinBox(1, 10)
  lurek.log.info("newSpinBox: " .. tostring(sb), "ui")
end


--@api-stub: lurek.ui.newSwitch
-- Creates a new toggle switch widget
do
  local sw = lurek.ui.newSwitch(false)
  lurek.log.info("newSwitch: " .. tostring(sw), "ui")
end


--@api-stub: lurek.ui.newBadge
-- Creates a new badge widget for displaying counts
do
  local badge = lurek.ui.newBadge(5)
  lurek.log.info("newBadge: " .. tostring(badge), "ui")
end


--@api-stub: lurek.ui.setDefaultTheme
-- Applies the built-in default theme to the UI context
do
  lurek.ui.setDefaultTheme()
  lurek.log.info("default theme set", "ui")
end


--@api-stub: lurek.ui.setViewport
-- Sets the viewport size for the UI context
do
  lurek.ui.setViewport(1280.0, 720.0)
  lurek.log.info("viewport set", "ui")
end


--@api-stub: lurek.ui.flushCache
-- Flushes internal UI caches
do
  local changed = lurek.ui.flushCache()
  lurek.log.info("cache flushed=" .. tostring(changed), "ui")
end


--@api-stub: lurek.ui.update_bindings
-- Updates data bindings for widgets that reference binding keys
do
  lurek.ui.update_bindings({ health = 75, score = 1200 })
  lurek.log.info("bindings updated", "ui")
end


--@api-stub: lurek.ui.loadLayout
-- Loads a UI layout from a Lua table definition
do
  local root = lurek.ui.loadLayout({ type = "panel", width = 200, height = 100 })
  lurek.log.info("layout root=" .. tostring(root), "ui")
end


--@api-stub: lurek.ui.loadLayoutFile
-- Loads a UI layout from a TOML file
do
  local ok, count = pcall(lurek.ui.loadLayoutFile, "content/layouts/hud.toml")
  if ok then lurek.log.info("layout=" .. tostring(count), "ui") end
end


--@api-stub: lurek.ui.renderToImage
-- Renders the UI to a PNG file
do
  pcall(lurek.ui.renderToImage, 256, 256, "save/ui_snapshot.png")
  lurek.log.info("rendered to file", "ui")
end


-- LAccordion methods


--@api-stub: LAccordion:addSection
-- Adds a section to this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:addSection("Section", 1)
  lurek.log.info("LAccordion:addSection done", "ui")
end


--@api-stub: LAccordion:getSectionCount
-- Returns the number of section items in this accordion.
do
  local acc = lurek.ui.newAccordion()
  local val = acc:getSectionCount()
  lurek.log.info("LAccordion:getSectionCount=" .. tostring(val), "ui")
end


--@api-stub: LAccordion:toggleSection
-- Toggles the section state of this accordion.
do
  local acc = lurek.ui.newAccordion()
  local val = acc:toggleSection(1)
  lurek.log.info("LAccordion:toggleSection=" .. tostring(val), "ui")
end


--@api-stub: LAccordion:isSectionExpanded
-- Returns true if this accordion section expanded.
do
  local acc = lurek.ui.newAccordion()
  local val = acc:isSectionExpanded(1)
  lurek.log.info("LAccordion:isSectionExpanded=" .. tostring(val), "ui")
end


--@api-stub: LAccordion:isExclusive
-- Returns true if this accordion exclusive.
do
  local acc = lurek.ui.newAccordion()
  local val = acc:isExclusive()
  lurek.log.info("LAccordion:isExclusive=" .. tostring(val), "ui")
end


--@api-stub: LAccordion:setExclusive
-- Sets the exclusive of this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:setExclusive(1.0)
  lurek.log.info("LAccordion:setExclusive applied", "ui")
end


--@api-stub: LAccordion:getSectionTitle
-- Returns the section title of this accordion.
do
  local acc = lurek.ui.newAccordion()
  local val = acc:getSectionTitle(1)
  lurek.log.info("LAccordion:getSectionTitle=" .. tostring(val), "ui")
end


-- LBadge methods


--@api-stub: LBadge:setCount
-- Sets the count of this badge.
do
  local badge = lurek.ui.newBadge(5)
  badge:setCount(10)
  lurek.log.info("LBadge:setCount applied", "ui")
end


--@api-stub: LBadge:getCount
-- Returns the total count of items held by this badge.
do
  local badge = lurek.ui.newBadge(5)
  local val = badge:getCount()
  lurek.log.info("LBadge:getCount=" .. tostring(val), "ui")
end


--@api-stub: LBadge:getDisplayText
-- Returns the display text of this badge.
do
  local badge = lurek.ui.newBadge(5)
  local val = badge:getDisplayText()
  lurek.log.info("LBadge:getDisplayText=" .. tostring(val), "ui")
end


-- LButton methods


--@api-stub: LButton:setText
-- Sets the text of this button.
do
  local btn = lurek.ui.newButton("Click")
  btn:setText("Hello, world!")
  lurek.log.info("LButton:setText applied", "ui")
end


--@api-stub: LButton:getText
-- Returns the text of this button.
do
  local btn = lurek.ui.newButton("Click")
  local val = btn:getText()
  lurek.log.info("LButton:getText=" .. tostring(val), "ui")
end


-- LCheckbox methods


--@api-stub: LCheckbox:setChecked
-- Sets the checked of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Option")
  cb:setChecked(true)
  lurek.log.info("LCheckbox:setChecked applied", "ui")
end


--@api-stub: LCheckbox:isChecked
-- Returns true if this checkbox checked.
do
  local cb = lurek.ui.newCheckbox("Option")
  local val = cb:isChecked()
  lurek.log.info("LCheckbox:isChecked=" .. tostring(val), "ui")
end


--@api-stub: LCheckbox:setText
-- Sets the text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Option")
  cb:setText("Hello, world!")
  lurek.log.info("LCheckbox:setText applied", "ui")
end


--@api-stub: LCheckbox:getText
-- Returns the text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Option")
  local val = cb:getText()
  lurek.log.info("LCheckbox:getText=" .. tostring(val), "ui")
end


-- LColorPicker methods


--@api-stub: LColorPicker:getColor
-- Returns the color of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  local val = cp:getColor()
  lurek.log.info("LColorPicker:getColor=" .. tostring(val), "ui")
end


--@api-stub: LColorPicker:setColor
-- Sets the color of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setColor(1.0, 1.0, 0.2, 1.0)
  lurek.log.info("LColorPicker:setColor applied", "ui")
end


--@api-stub: LColorPicker:getShowAlpha
-- Returns the show alpha of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  local val = cp:getShowAlpha()
  lurek.log.info("LColorPicker:getShowAlpha=" .. tostring(val), "ui")
end


--@api-stub: LColorPicker:setShowAlpha
-- Sets the show alpha of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setShowAlpha(1.0)
  lurek.log.info("LColorPicker:setShowAlpha applied", "ui")
end


--@api-stub: LColorPicker:getColorMode
-- Returns the color mode of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  local val = cp:getColorMode()
  lurek.log.info("LColorPicker:getColorMode=" .. tostring(val), "ui")
end


--@api-stub: LColorPicker:setColorMode
-- Sets the color mode of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setColorMode("left")
  lurek.log.info("LColorPicker:setColorMode applied", "ui")
end


--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this color picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setOnChange(function() end)
  lurek.log.info("LColorPicker:setOnChange callback set", "ui")
end


-- LComboBox methods


--@api-stub: LComboBox:addItem
-- Adds a item to this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:addItem("Hello, world!")
  lurek.log.info("LComboBox:addItem done", "ui")
end


--@api-stub: LComboBox:removeItem
-- Removes a item from this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:removeItem(1)
  lurek.log.info("LComboBox:removeItem done", "ui")
end


--@api-stub: LComboBox:clearItems
-- Clears all items items from this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:clearItems()
  lurek.log.info("LComboBox:clearItems done", "ui")
end


--@api-stub: LComboBox:getItemCount
-- Returns the number of item items in this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getItemCount()
  lurek.log.info("LComboBox:getItemCount=" .. tostring(val), "ui")
end


--@api-stub: LComboBox:getItem
-- Returns the item of this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getItem(1)
  lurek.log.info("LComboBox:getItem=" .. tostring(val), "ui")
end


--@api-stub: LComboBox:setSelectedIndex
-- Sets the selected index of this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:setSelectedIndex(1)
  lurek.log.info("LComboBox:setSelectedIndex applied", "ui")
end


--@api-stub: LComboBox:getSelectedIndex
-- Returns the selected index of this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getSelectedIndex()
  lurek.log.info("LComboBox:getSelectedIndex=" .. tostring(val), "ui")
end


--@api-stub: LComboBox:getSelectedItem
-- Returns the selected item of this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getSelectedItem()
  lurek.log.info("LComboBox:getSelectedItem=" .. tostring(val), "ui")
end


-- LDialog methods


--@api-stub: LDialog:getTitle
-- Returns the title of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  local val = dlg:getTitle()
  lurek.log.info("LDialog:getTitle=" .. tostring(val), "ui")
end


--@api-stub: LDialog:setTitle
-- Sets the title of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:setTitle("Section")
  lurek.log.info("LDialog:setTitle applied", "ui")
end


--@api-stub: LDialog:isModal
-- Returns true if this dialog modal.
do
  local dlg = lurek.ui.newDialog("Title")
  local val = dlg:isModal()
  lurek.log.info("LDialog:isModal=" .. tostring(val), "ui")
end


--@api-stub: LDialog:setModal
-- Sets the modal of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:setModal(1.0)
  lurek.log.info("LDialog:setModal applied", "ui")
end


--@api-stub: LDialog:isOpen
-- Returns true if this dialog open.
do
  local dlg = lurek.ui.newDialog("Title")
  local val = dlg:isOpen()
  lurek.log.info("LDialog:isOpen=" .. tostring(val), "ui")
end


--@api-stub: LDialog:open
-- Performs the open operation on this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:open()
  lurek.log.info("LDialog:open called", "ui")
end


--@api-stub: LDialog:close
-- Performs the close operation on this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:close()
  lurek.log.info("LDialog:close called", "ui")
end


--@api-stub: LDialog:setOnClose
-- Sets the on close of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:setOnClose(function() end)
  lurek.log.info("LDialog:setOnClose callback set", "ui")
end


--@api-stub: LDialog:setContent
-- Sets the content of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:setContent(1)
  lurek.log.info("LDialog:setContent applied", "ui")
end


--@api-stub: LDialog:getContent
-- Returns the content of this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  local val = dlg:getContent()
  lurek.log.info("LDialog:getContent=" .. tostring(val), "ui")
end


--@api-stub: LDialog:addButton
-- Adds a button to this dialog.
do
  local dlg = lurek.ui.newDialog("Title")
  dlg:addButton("Hello, world!", function() end)
  lurek.log.info("LDialog:addButton done", "ui")
end


-- LDockPanel methods


--@api-stub: LDockPanel:dock
-- Docks a child widget into this dock panel panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:dock(1, "left")
  lurek.log.info("LDockPanel:dock called", "ui")
end


--@api-stub: LDockPanel:undock
-- Undocks a previously docked widget from this dock panel panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:undock(1)
  lurek.log.info("LDockPanel:undock called", "ui")
end


--@api-stub: LDockPanel:getDockedCount
-- Returns the number of docked items in this dock panel.
do
  local dock = lurek.ui.newDockPanel()
  local val = dock:getDockedCount()
  lurek.log.info("LDockPanel:getDockedCount=" .. tostring(val), "ui")
end


--@api-stub: LDockPanel:setSplitSize
-- Sets the split size of this dock panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:setSplitSize("left", 64.0)
  lurek.log.info("LDockPanel:setSplitSize applied", "ui")
end


--@api-stub: LDockPanel:getSplitSize
-- Returns the split size of this dock panel.
do
  local dock = lurek.ui.newDockPanel()
  local val = dock:getSplitSize("left")
  lurek.log.info("LDockPanel:getSplitSize=" .. tostring(val), "ui")
end


-- LGuiTable methods


--@api-stub: LGuiTable:addColumn
-- Adds a column to this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:addColumn("Hello", 64.0)
  lurek.log.info("LGuiTable:addColumn done", "ui")
end


--@api-stub: LGuiTable:getColumnCount
-- Returns the number of column items in this gui table.
do
  local tbl = lurek.ui.newTable()
  local val = tbl:getColumnCount()
  lurek.log.info("LGuiTable:getColumnCount=" .. tostring(val), "ui")
end


--@api-stub: LGuiTable:addRow
-- Adds a row to this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:addRow({1, 2, 3})
  lurek.log.info("LGuiTable:addRow done", "ui")
end


--@api-stub: LGuiTable:getRowCount
-- Returns the number of row items in this gui table.
do
  local tbl = lurek.ui.newTable()
  local val = tbl:getRowCount()
  lurek.log.info("LGuiTable:getRowCount=" .. tostring(val), "ui")
end


--@api-stub: LGuiTable:getCell
-- Returns the cell of this gui table.
do
  local tbl = lurek.ui.newTable()
  local val = tbl:getCell(1, 1)
  lurek.log.info("LGuiTable:getCell=" .. tostring(val), "ui")
end


--@api-stub: LGuiTable:setCell
-- Sets the cell of this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:setCell(1, 1, "Hello, world!")
  lurek.log.info("LGuiTable:setCell applied", "ui")
end


--@api-stub: LGuiTable:getSelectedRow
-- Returns the selected row of this gui table.
do
  local tbl = lurek.ui.newTable()
  local val = tbl:getSelectedRow()
  lurek.log.info("LGuiTable:getSelectedRow=" .. tostring(val), "ui")
end


--@api-stub: LGuiTable:setSelectedRow
-- Sets the selected row of this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:setSelectedRow(1)
  lurek.log.info("LGuiTable:setSelectedRow applied", "ui")
end


--@api-stub: LGuiTable:isSortable
-- Returns true if this gui table sortable.
do
  local tbl = lurek.ui.newTable()
  local val = tbl:isSortable()
  lurek.log.info("LGuiTable:isSortable=" .. tostring(val), "ui")
end


--@api-stub: LGuiTable:setSortable
-- Sets the sortable of this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:setSortable(1.0)
  lurek.log.info("LGuiTable:setSortable applied", "ui")
end


--@api-stub: LGuiTable:setOnSelect
-- Sets the on select of this gui table.
do
  local tbl = lurek.ui.newTable()
  tbl:setOnSelect(function() end)
  lurek.log.info("LGuiTable:setOnSelect callback set", "ui")
end


-- LGuiWindow methods


--@api-stub: LGuiWindow:getTitle
-- Returns the title of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  local val = win:getTitle()
  lurek.log.info("LGuiWindow:getTitle=" .. tostring(val), "ui")
end


--@api-stub: LGuiWindow:setTitle
-- Sets the title of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  win:setTitle("Section")
  lurek.log.info("LGuiWindow:setTitle applied", "ui")
end


--@api-stub: LGuiWindow:isCloseable
-- Returns true if this gui window closeable.
do
  local win = lurek.ui.newWindow("Title")
  local val = win:isCloseable()
  lurek.log.info("LGuiWindow:isCloseable=" .. tostring(val), "ui")
end


--@api-stub: LGuiWindow:setCloseable
-- Sets the closeable of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  win:setCloseable(1.0)
  lurek.log.info("LGuiWindow:setCloseable applied", "ui")
end


--@api-stub: LGuiWindow:isDraggable
-- Returns true if this gui window draggable.
do
  local win = lurek.ui.newWindow("Title")
  local val = win:isDraggable()
  lurek.log.info("LGuiWindow:isDraggable=" .. tostring(val), "ui")
end


--@api-stub: LGuiWindow:setDraggable
-- Sets the draggable of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  win:setDraggable(1.0)
  lurek.log.info("LGuiWindow:setDraggable applied", "ui")
end


--@api-stub: LGuiWindow:isResizable
-- Returns true if this gui window resizable.
do
  local win = lurek.ui.newWindow("Title")
  local val = win:isResizable()
  lurek.log.info("LGuiWindow:isResizable=" .. tostring(val), "ui")
end


--@api-stub: LGuiWindow:setResizable
-- Sets the resizable of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  win:setResizable(1.0)
  lurek.log.info("LGuiWindow:setResizable applied", "ui")
end


--@api-stub: LGuiWindow:setOnClose
-- Sets the on close of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  win:setOnClose(function() end)
  lurek.log.info("LGuiWindow:setOnClose callback set", "ui")
end


-- LImageWidget methods


--@api-stub: LImageWidget:getScaleMode
-- Returns the scale mode of this image widget.
do
  local iw = lurek.ui.newImageWidget()
  local val = iw:getScaleMode()
  lurek.log.info("LImageWidget:getScaleMode=" .. tostring(val), "ui")
end


--@api-stub: LImageWidget:setScaleMode
-- Sets the scale mode of this image widget.
do
  local iw = lurek.ui.newImageWidget()
  iw:setScaleMode("left")
  lurek.log.info("LImageWidget:setScaleMode applied", "ui")
end


--@api-stub: LImageWidget:getTint
-- Returns the tint of this image widget.
do
  local iw = lurek.ui.newImageWidget()
  local val = iw:getTint()
  lurek.log.info("LImageWidget:getTint=" .. tostring(val), "ui")
end


--@api-stub: LImageWidget:setTint
-- Sets the tint of this image widget.
do
  local iw = lurek.ui.newImageWidget()
  iw:setTint(1.0, 1.0, 0.2, 1.0)
  lurek.log.info("LImageWidget:setTint applied", "ui")
end


-- LLabel methods


--@api-stub: LLabel:setText
-- Sets the text of this abel.
do
  local lbl = lurek.ui.newLabel("Text")
  lbl:setText("Hello, world!")
  lurek.log.info("LLabel:setText applied", "ui")
end


--@api-stub: LLabel:getText
-- Returns the text of this abel.
do
  local lbl = lurek.ui.newLabel("Text")
  local val = lbl:getText()
  lurek.log.info("LLabel:getText=" .. tostring(val), "ui")
end


-- LLayout methods


--@api-stub: LLayout:setDirection
-- Sets the direction of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setDirection("left")
  lurek.log.info("LLayout:setDirection applied", "ui")
end


--@api-stub: LLayout:getDirection
-- Returns the direction of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  local val = layout:getDirection()
  lurek.log.info("LLayout:getDirection=" .. tostring(val), "ui")
end


--@api-stub: LLayout:setSpacing
-- Sets the spacing of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setSpacing(0.0)
  lurek.log.info("LLayout:setSpacing applied", "ui")
end


--@api-stub: LLayout:getSpacing
-- Returns the spacing of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  local val = layout:getSpacing()
  lurek.log.info("LLayout:getSpacing=" .. tostring(val), "ui")
end


--@api-stub: LLayout:setColumns
-- Sets the columns of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setColumns(5)
  lurek.log.info("LLayout:setColumns applied", "ui")
end


--@api-stub: LLayout:setWrap
-- Sets the wrap of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setWrap(true)
  lurek.log.info("LLayout:setWrap applied", "ui")
end


--@api-stub: LLayout:getWrap
-- Returns the wrap of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  local val = layout:getWrap()
  lurek.log.info("LLayout:getWrap=" .. tostring(val), "ui")
end


--@api-stub: LLayout:setAlign
-- Sets the align of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setAlign("left")
  lurek.log.info("LLayout:setAlign applied", "ui")
end


--@api-stub: LLayout:getAlign
-- Returns the align of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  local val = layout:getAlign()
  lurek.log.info("LLayout:getAlign=" .. tostring(val), "ui")
end


--@api-stub: LLayout:setJustify
-- Sets the justify of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  layout:setJustify("left")
  lurek.log.info("LLayout:setJustify applied", "ui")
end


--@api-stub: LLayout:getJustify
-- Returns the justify of this ayout.
do
  local layout = lurek.ui.newLayout("horizontal")
  local val = layout:getJustify()
  lurek.log.info("LLayout:getJustify=" .. tostring(val), "ui")
end


-- LLineChart methods


--@api-stub: LLineChart:addSeries
-- Adds a named series of points to this line chart
do
  local chart = lurek.ui.newLineChart({ width = 300, height = 200, title = "Data" })
  chart:addSeries("hero", {1, 2, 3}, 1.0, 0.8, 0.2)
  lurek.log.info("LLineChart:addSeries done", "ui")
end


-- LListBox methods


--@api-stub: LListBox:addItem
-- Adds a item to this ist box.
do
  local list = lurek.ui.newList()
  list:addItem("Hello, world!")
  lurek.log.info("LListBox:addItem done", "ui")
end


--@api-stub: LListBox:removeItem
-- Removes a item from this ist box.
do
  local list = lurek.ui.newList()
  list:removeItem(1)
  lurek.log.info("LListBox:removeItem done", "ui")
end


--@api-stub: LListBox:clearItems
-- Clears all items items from this ist box.
do
  local list = lurek.ui.newList()
  list:clearItems()
  lurek.log.info("LListBox:clearItems done", "ui")
end


--@api-stub: LListBox:getItemCount
-- Returns the number of item items in this ist box.
do
  local list = lurek.ui.newList()
  local val = list:getItemCount()
  lurek.log.info("LListBox:getItemCount=" .. tostring(val), "ui")
end


--@api-stub: LListBox:getItem
-- Returns the item of this ist box.
do
  local list = lurek.ui.newList()
  local val = list:getItem(1)
  lurek.log.info("LListBox:getItem=" .. tostring(val), "ui")
end


--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index of this ist box.
do
  local list = lurek.ui.newList()
  list:setSelectedIndex(1)
  lurek.log.info("LListBox:setSelectedIndex applied", "ui")
end


--@api-stub: LListBox:getSelectedIndex
-- Returns the selected index of this ist box.
do
  local list = lurek.ui.newList()
  local val = list:getSelectedIndex()
  lurek.log.info("LListBox:getSelectedIndex=" .. tostring(val), "ui")
end


--@api-stub: LListBox:setItemHeight
-- Sets the item height of this ist box.
do
  local list = lurek.ui.newList()
  list:setItemHeight(64.0)
  lurek.log.info("LListBox:setItemHeight applied", "ui")
end


-- LMenuBar methods


--@api-stub: LMenuBar:addMenu
-- Adds a menu to this menu bar.
do
  local mb = lurek.ui.newMenuBar()
  mb:addMenu(1)
  lurek.log.info("LMenuBar:addMenu done", "ui")
end


--@api-stub: LMenuBar:removeMenu
-- Removes a menu from this menu bar.
do
  local mb = lurek.ui.newMenuBar()
  mb:removeMenu(1)
  lurek.log.info("LMenuBar:removeMenu done", "ui")
end


--@api-stub: LMenuBar:getMenus
-- Returns the menus of this menu bar.
do
  local mb = lurek.ui.newMenuBar()
  local val = mb:getMenus()
  lurek.log.info("LMenuBar:getMenus=" .. tostring(val), "ui")
end


--@api-stub: LMenuBar:getMenuCount
-- Returns the number of menu items in this menu bar.
do
  local mb = lurek.ui.newMenuBar()
  local val = mb:getMenuCount()
  lurek.log.info("LMenuBar:getMenuCount=" .. tostring(val), "ui")
end


-- LMenuItem methods


--@api-stub: LMenuItem:getText
-- Returns the text of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  local val = mi:getText()
  lurek.log.info("LMenuItem:getText=" .. tostring(val), "ui")
end


--@api-stub: LMenuItem:setText
-- Sets the text of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  mi:setText("Hello, world!")
  lurek.log.info("LMenuItem:setText applied", "ui")
end


--@api-stub: LMenuItem:getShortcut
-- Returns the shortcut of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  local val = mi:getShortcut()
  lurek.log.info("LMenuItem:getShortcut=" .. tostring(val), "ui")
end


--@api-stub: LMenuItem:setShortcut
-- Sets the shortcut of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  mi:setShortcut("Hello")
  lurek.log.info("LMenuItem:setShortcut applied", "ui")
end


--@api-stub: LMenuItem:isChecked
-- Returns true if this menu item checked.
do
  local mi = lurek.ui.newMenuItem("File")
  local val = mi:isChecked()
  lurek.log.info("LMenuItem:isChecked=" .. tostring(val), "ui")
end


--@api-stub: LMenuItem:setChecked
-- Sets the checked of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  mi:setChecked(1.0)
  lurek.log.info("LMenuItem:setChecked applied", "ui")
end


--@api-stub: LMenuItem:addSubItem
-- Adds a sub item to this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  mi:addSubItem(1)
  lurek.log.info("LMenuItem:addSubItem done", "ui")
end


--@api-stub: LMenuItem:getSubItems
-- Returns the sub items of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  local val = mi:getSubItems()
  lurek.log.info("LMenuItem:getSubItems=" .. tostring(val), "ui")
end


--@api-stub: LMenuItem:setOnClick
-- Sets the on click of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  mi:setOnClick(function() end)
  lurek.log.info("LMenuItem:setOnClick callback set", "ui")
end


-- LNinePatch methods


--@api-stub: LNinePatch:setInsets
-- Sets the insets of this nine patch.
do
  local np = lurek.ui.newNinePatch()
  np:setInsets(64.0, 64.0, 64.0, 64.0)
  lurek.log.info("LNinePatch:setInsets applied", "ui")
end


--@api-stub: LNinePatch:getInsets
-- Returns the insets of this nine patch.
do
  local np = lurek.ui.newNinePatch()
  local val = np:getInsets()
  lurek.log.info("LNinePatch:getInsets=" .. tostring(val), "ui")
end


--@api-stub: LNinePatch:setImageDimensions
-- Sets the image dimensions of this nine patch.
do
  local np = lurek.ui.newNinePatch()
  np:setImageDimensions(64.0, 64.0)
  lurek.log.info("LNinePatch:setImageDimensions applied", "ui")
end


--@api-stub: LNinePatch:getImageDimensions
-- Returns the image dimensions of this nine patch.
do
  local np = lurek.ui.newNinePatch()
  local val = np:getImageDimensions()
  lurek.log.info("LNinePatch:getImageDimensions=" .. tostring(val), "ui")
end


--@api-stub: LNinePatch:getSlices
-- Returns the slices of this nine patch.
do
  local np = lurek.ui.newNinePatch()
  local val = np:getSlices()
  lurek.log.info("LNinePatch:getSlices=" .. tostring(val), "ui")
end


-- LPanel methods


--@api-stub: LPanel:setTitle
-- Sets the title of this panel.
do
  local panel = lurek.ui.newPanel()
  panel:setTitle("Section")
  lurek.log.info("LPanel:setTitle applied", "ui")
end


--@api-stub: LPanel:getTitle
-- Returns the title of this panel.
do
  local panel = lurek.ui.newPanel()
  local val = panel:getTitle()
  lurek.log.info("LPanel:getTitle=" .. tostring(val), "ui")
end


--@api-stub: LPanel:setScrollable
-- Sets the scrollable of this panel.
do
  local panel = lurek.ui.newPanel()
  panel:setScrollable(true)
  lurek.log.info("LPanel:setScrollable applied", "ui")
end


-- LProgressBar methods


--@api-stub: LProgressBar:setValue
-- Sets the value of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  bar:setValue(1.0)
  lurek.log.info("LProgressBar:setValue applied", "ui")
end


--@api-stub: LProgressBar:getValue
-- Returns the value of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getValue()
  lurek.log.info("LProgressBar:getValue=" .. tostring(val), "ui")
end


--@api-stub: LProgressBar:getProgress
-- Returns the progress of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getProgress()
  lurek.log.info("LProgressBar:getProgress=" .. tostring(val), "ui")
end


--@api-stub: LProgressBar:setRange
-- Sets the range of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  bar:setRange(0.0, 0.0)
  lurek.log.info("LProgressBar:setRange applied", "ui")
end


--@api-stub: LProgressBar:getMin
-- Returns the min of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getMin()
  lurek.log.info("LProgressBar:getMin=" .. tostring(val), "ui")
end


--@api-stub: LProgressBar:getMax
-- Returns the max of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getMax()
  lurek.log.info("LProgressBar:getMax=" .. tostring(val), "ui")
end


-- LRadioButton methods


--@api-stub: LRadioButton:getText
-- Returns the text of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  local val = rb:getText()
  lurek.log.info("LRadioButton:getText=" .. tostring(val), "ui")
end


--@api-stub: LRadioButton:setText
-- Sets the text of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  rb:setText("Hello, world!")
  lurek.log.info("LRadioButton:setText applied", "ui")
end


--@api-stub: LRadioButton:isSelected
-- Returns true if this radio button selected.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  local val = rb:isSelected()
  lurek.log.info("LRadioButton:isSelected=" .. tostring(val), "ui")
end


--@api-stub: LRadioButton:setSelected
-- Sets the selected of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  rb:setSelected(1.0)
  lurek.log.info("LRadioButton:setSelected applied", "ui")
end


--@api-stub: LRadioButton:getGroup
-- Returns the group of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  local val = rb:getGroup()
  lurek.log.info("LRadioButton:getGroup=" .. tostring(val), "ui")
end


--@api-stub: LRadioButton:setGroup
-- Sets the group of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  rb:setGroup("left")
  lurek.log.info("LRadioButton:setGroup applied", "ui")
end


--@api-stub: LRadioButton:setOnChange
-- Sets the on change of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  rb:setOnChange(function() end)
  lurek.log.info("LRadioButton:setOnChange callback set", "ui")
end


-- LScrollBar methods


--@api-stub: LScrollBar:getScrollPosition
-- Returns the scroll position of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  local val = scrollbar:getScrollPosition()
  lurek.log.info("LScrollBar:getScrollPosition=" .. tostring(val), "ui")
end


--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  scrollbar:setScrollPosition(1.0)
  lurek.log.info("LScrollBar:setScrollPosition applied", "ui")
end


--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  local val = scrollbar:getContentSize()
  lurek.log.info("LScrollBar:getContentSize=" .. tostring(val), "ui")
end


--@api-stub: LScrollBar:setContentSize
-- Sets the content size of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  scrollbar:setContentSize(1.0)
  lurek.log.info("LScrollBar:setContentSize applied", "ui")
end


--@api-stub: LScrollBar:getViewSize
-- Returns the view size of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  local val = scrollbar:getViewSize()
  lurek.log.info("LScrollBar:getViewSize=" .. tostring(val), "ui")
end


--@api-stub: LScrollBar:setViewSize
-- Sets the view size of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  scrollbar:setViewSize(1.0)
  lurek.log.info("LScrollBar:setViewSize applied", "ui")
end


--@api-stub: LScrollBar:isVertical
-- Returns true if this scroll bar vertical.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  local val = scrollbar:isVertical()
  lurek.log.info("LScrollBar:isVertical=" .. tostring(val), "ui")
end


--@api-stub: LScrollBar:setOnChange
-- Sets the on change of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  scrollbar:setOnChange(function() end)
  lurek.log.info("LScrollBar:setOnChange callback set", "ui")
end


-- LScrollPanel methods


--@api-stub: LScrollPanel:setContentSize
-- Sets the content size of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(64.0, 64.0)
  lurek.log.info("LScrollPanel:setContentSize applied", "ui")
end


--@api-stub: LScrollPanel:getContentSize
-- Returns the content size of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  local val = sp:getContentSize()
  lurek.log.info("LScrollPanel:getContentSize=" .. tostring(val), "ui")
end


--@api-stub: LScrollPanel:setScrollPosition
-- Sets the scroll position of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setScrollPosition(0.0, 0.0)
  lurek.log.info("LScrollPanel:setScrollPosition applied", "ui")
end


--@api-stub: LScrollPanel:getScrollPosition
-- Returns the scroll position of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  local val = sp:getScrollPosition()
  lurek.log.info("LScrollPanel:getScrollPosition=" .. tostring(val), "ui")
end


--@api-stub: LScrollPanel:getMaxScroll
-- Returns the max scroll of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  local val = sp:getMaxScroll()
  lurek.log.info("LScrollPanel:getMaxScroll=" .. tostring(val), "ui")
end


--@api-stub: LScrollPanel:setScrollSpeed
-- Sets the scroll speed of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setScrollSpeed(120.0)
  lurek.log.info("LScrollPanel:setScrollSpeed applied", "ui")
end


--@api-stub: LScrollPanel:getScrollSpeed
-- Returns the scroll speed of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  local val = sp:getScrollSpeed()
  lurek.log.info("LScrollPanel:getScrollSpeed=" .. tostring(val), "ui")
end


-- LSeparator methods


--@api-stub: LSeparator:setVertical
-- Sets the vertical of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  sep:setVertical(1.0)
  lurek.log.info("LSeparator:setVertical applied", "ui")
end


--@api-stub: LSeparator:isVertical
-- Returns true if this separator vertical.
do
  local sep = lurek.ui.newSeparator(false)
  local val = sep:isVertical()
  lurek.log.info("LSeparator:isVertical=" .. tostring(val), "ui")
end


--@api-stub: LSeparator:setThickness
-- Sets the thickness of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  sep:setThickness(64.0)
  lurek.log.info("LSeparator:setThickness applied", "ui")
end


--@api-stub: LSeparator:getThickness
-- Returns the thickness of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  local val = sep:getThickness()
  lurek.log.info("LSeparator:getThickness=" .. tostring(val), "ui")
end


-- LSlider methods


--@api-stub: LSlider:setValue
-- Sets the value of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setValue(1.0)
  lurek.log.info("LSlider:setValue applied", "ui")
end


--@api-stub: LSlider:getValue
-- Returns the value of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  local val = slider:getValue()
  lurek.log.info("LSlider:getValue=" .. tostring(val), "ui")
end


--@api-stub: LSlider:setRange
-- Sets the range of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setRange(0.0, 0.0)
  lurek.log.info("LSlider:setRange applied", "ui")
end


--@api-stub: LSlider:setStep
-- Sets the step of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setStep(0.0)
  lurek.log.info("LSlider:setStep applied", "ui")
end


--@api-stub: LSlider:getMin
-- Returns the min of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  local val = slider:getMin()
  lurek.log.info("LSlider:getMin=" .. tostring(val), "ui")
end


--@api-stub: LSlider:getMax
-- Returns the max of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  local val = slider:getMax()
  lurek.log.info("LSlider:getMax=" .. tostring(val), "ui")
end


-- LSpinBox methods


--@api-stub: LSpinBox:setValue
-- Sets the value of this spin box.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  sb:setValue(1.0)
  lurek.log.info("LSpinBox:setValue applied", "ui")
end


--@api-stub: LSpinBox:getValue
-- Returns the value of this spin box.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  local val = sb:getValue()
  lurek.log.info("LSpinBox:getValue=" .. tostring(val), "ui")
end


--@api-stub: LSpinBox:increment
-- Increments the value of this spin box by one step.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  sb:increment()
  lurek.log.info("LSpinBox:increment called", "ui")
end


--@api-stub: LSpinBox:decrement
-- Decrements the value of this spin box by one step.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  sb:decrement()
  lurek.log.info("LSpinBox:decrement called", "ui")
end


--@api-stub: LSpinBox:setRange
-- Sets the range of this spin box.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  sb:setRange(0.0, 0.0)
  lurek.log.info("LSpinBox:setRange applied", "ui")
end


--@api-stub: LSpinBox:setStep
-- Sets the step of this spin box.
do
  local sb = lurek.ui.newSpinBox(0, 100)
  sb:setStep(0.0)
  lurek.log.info("LSpinBox:setStep applied", "ui")
end


-- LSplitPanel methods


--@api-stub: LSplitPanel:getOrientation
-- Returns the orientation of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getOrientation()
  lurek.log.info("LSplitPanel:getOrientation=" .. tostring(val), "ui")
end


--@api-stub: LSplitPanel:setOrientation
-- Sets the orientation of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setOrientation(1.0)
  lurek.log.info("LSplitPanel:setOrientation applied", "ui")
end


--@api-stub: LSplitPanel:getSplitPosition
-- Returns the split position of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getSplitPosition()
  lurek.log.info("LSplitPanel:getSplitPosition=" .. tostring(val), "ui")
end


--@api-stub: LSplitPanel:setSplitPosition
-- Sets the split position of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setSplitPosition(1.0)
  lurek.log.info("LSplitPanel:setSplitPosition applied", "ui")
end


--@api-stub: LSplitPanel:getMinPanelSize
-- Returns the min panel size of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getMinPanelSize()
  lurek.log.info("LSplitPanel:getMinPanelSize=" .. tostring(val), "ui")
end


--@api-stub: LSplitPanel:setMinPanelSize
-- Sets the min panel size of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setMinPanelSize(1.0)
  lurek.log.info("LSplitPanel:setMinPanelSize applied", "ui")
end


--@api-stub: LSplitPanel:setFirstChild
-- Sets the first child of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setFirstChild(1)
  lurek.log.info("LSplitPanel:setFirstChild applied", "ui")
end


--@api-stub: LSplitPanel:setSecondChild
-- Sets the second child of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setSecondChild(1)
  lurek.log.info("LSplitPanel:setSecondChild applied", "ui")
end


--@api-stub: LSplitPanel:getFirstChild
-- Returns the first child of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getFirstChild()
  lurek.log.info("LSplitPanel:getFirstChild=" .. tostring(val), "ui")
end


--@api-stub: LSplitPanel:getSecondChild
-- Returns the second child of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getSecondChild()
  lurek.log.info("LSplitPanel:getSecondChild=" .. tostring(val), "ui")
end


-- LStatusBar methods


--@api-stub: LStatusBar:addSection
-- Adds a section to this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  sbar:addSection("Hello, world!", 64.0)
  lurek.log.info("LStatusBar:addSection done", "ui")
end


--@api-stub: LStatusBar:setSectionText
-- Sets the section text of this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  sbar:setSectionText(1, "Hello, world!")
  lurek.log.info("LStatusBar:setSectionText applied", "ui")
end


--@api-stub: LStatusBar:getSectionText
-- Returns the section text of this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  local val = sbar:getSectionText(1)
  lurek.log.info("LStatusBar:getSectionText=" .. tostring(val), "ui")
end


--@api-stub: LStatusBar:getSectionCount
-- Returns the number of section items in this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  local val = sbar:getSectionCount()
  lurek.log.info("LStatusBar:getSectionCount=" .. tostring(val), "ui")
end


--@api-stub: LStatusBar:setSectionCount
-- Sets the section count of this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  sbar:setSectionCount(10)
  lurek.log.info("LStatusBar:setSectionCount applied", "ui")
end


--@api-stub: LStatusBar:setSectionWidget
-- Sets the section widget of this status bar.
do
  local sbar = lurek.ui.newStatusBar()
  sbar:setSectionWidget(1, 1.0)
  lurek.log.info("LStatusBar:setSectionWidget applied", "ui")
end


-- LSwitch methods


--@api-stub: LSwitch:setOn
-- Sets the on of this switch.
do
  local sw = lurek.ui.newSwitch(false)
  sw:setOn(function() end)
  lurek.log.info("LSwitch:setOn callback set", "ui")
end


--@api-stub: LSwitch:isOn
-- Returns true if this switch on.
do
  local sw = lurek.ui.newSwitch(false)
  local val = sw:isOn()
  lurek.log.info("LSwitch:isOn=" .. tostring(val), "ui")
end


--@api-stub: LSwitch:toggle
-- Toggles the  state of this switch.
do
  local sw = lurek.ui.newSwitch(false)
  local val = sw:toggle()
  lurek.log.info("LSwitch:toggle=" .. tostring(val), "ui")
end


-- LTabBar methods


--@api-stub: LTabBar:addTab
-- Adds a tab to this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  tabs:addTab("Hello")
  lurek.log.info("LTabBar:addTab done", "ui")
end


--@api-stub: LTabBar:removeTab
-- Removes a tab from this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  tabs:removeTab(1)
  lurek.log.info("LTabBar:removeTab done", "ui")
end


--@api-stub: LTabBar:getTab
-- Returns the tab of this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  local val = tabs:getTab(1)
  lurek.log.info("LTabBar:getTab=" .. tostring(val), "ui")
end


--@api-stub: LTabBar:getTabCount
-- Returns the number of tab items in this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  local val = tabs:getTabCount()
  lurek.log.info("LTabBar:getTabCount=" .. tostring(val), "ui")
end


--@api-stub: LTabBar:setActiveTab
-- Sets the active tab of this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  tabs:setActiveTab(1)
  lurek.log.info("LTabBar:setActiveTab applied", "ui")
end


--@api-stub: LTabBar:getActiveTab
-- Returns the active tab of this tab bar.
do
  local tabs = lurek.ui.newTabBar()
  local val = tabs:getActiveTab()
  lurek.log.info("LTabBar:getActiveTab=" .. tostring(val), "ui")
end


-- LTextInput methods


--@api-stub: LTextInput:setText
-- Sets the text of this text input.
do
  local input = lurek.ui.newTextInput()
  input:setText("Hello, world!")
  lurek.log.info("LTextInput:setText applied", "ui")
end


--@api-stub: LTextInput:getText
-- Returns the text of this text input.
do
  local input = lurek.ui.newTextInput()
  local val = input:getText()
  lurek.log.info("LTextInput:getText=" .. tostring(val), "ui")
end


--@api-stub: LTextInput:setPlaceholder
-- Sets the placeholder of this text input.
do
  local input = lurek.ui.newTextInput()
  input:setPlaceholder("Hello, world!")
  lurek.log.info("LTextInput:setPlaceholder applied", "ui")
end


--@api-stub: LTextInput:getPlaceholder
-- Returns the placeholder of this text input.
do
  local input = lurek.ui.newTextInput()
  local val = input:getPlaceholder()
  lurek.log.info("LTextInput:getPlaceholder=" .. tostring(val), "ui")
end


--@api-stub: LTextInput:setMaxLength
-- Sets the max length of this text input.
do
  local input = lurek.ui.newTextInput()
  input:setMaxLength(5)
  lurek.log.info("LTextInput:setMaxLength applied", "ui")
end


--@api-stub: LTextInput:isFocused
-- Returns true if this text input focused.
do
  local input = lurek.ui.newTextInput()
  local val = input:isFocused()
  lurek.log.info("LTextInput:isFocused=" .. tostring(val), "ui")
end


--@api-stub: LTextInput:getCursorPosition
-- Returns the cursor position of this text input.
do
  local input = lurek.ui.newTextInput()
  local val = input:getCursorPosition()
  lurek.log.info("LTextInput:getCursorPosition=" .. tostring(val), "ui")
end


-- LToast methods


--@api-stub: LToast:setMessage
-- Sets the message of this toast.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  toast:setMessage("level_complete")
  lurek.log.info("LToast:setMessage applied", "ui")
end


--@api-stub: LToast:getMessage
-- Returns the message of this toast.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  local val = toast:getMessage()
  lurek.log.info("LToast:getMessage=" .. tostring(val), "ui")
end


--@api-stub: LToast:setDuration
-- Sets the duration of this toast.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  toast:setDuration(1.0)
  lurek.log.info("LToast:setDuration applied", "ui")
end


--@api-stub: LToast:getDuration
-- Returns the duration of this toast.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  local val = toast:getDuration()
  lurek.log.info("LToast:getDuration=" .. tostring(val), "ui")
end


--@api-stub: LToast:getProgress
-- Returns the progress of this toast.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  local val = toast:getProgress()
  lurek.log.info("LToast:getProgress=" .. tostring(val), "ui")
end


--@api-stub: LToast:isExpired
-- Returns true if this toast expired.
do
  local toast = lurek.ui.newToast("Hello!", 2.0)
  local val = toast:isExpired()
  lurek.log.info("LToast:isExpired=" .. tostring(val), "ui")
end


-- LToolbar methods


--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  local val = tb:getOrientation()
  lurek.log.info("LToolbar:getOrientation=" .. tostring(val), "ui")
end


--@api-stub: LToolbar:setOrientation
-- Sets the orientation of this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:setOrientation(1.0)
  lurek.log.info("LToolbar:setOrientation applied", "ui")
end


--@api-stub: LToolbar:addButton
-- Adds a button to this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:addButton(1, 1.0)
  lurek.log.info("LToolbar:addButton done", "ui")
end


--@api-stub: LToolbar:addSeparator
-- Adds a separator to this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:addSeparator()
  lurek.log.info("LToolbar:addSeparator done", "ui")
end


--@api-stub: LToolbar:addSpacer
-- Adds a spacer to this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:addSpacer(64.0)
  lurek.log.info("LToolbar:addSpacer done", "ui")
end


--@api-stub: LToolbar:getButton
-- Returns the button of this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  local val = tb:getButton(1)
  lurek.log.info("LToolbar:getButton=" .. tostring(val), "ui")
end


--@api-stub: LToolbar:setButtonEnabled
-- Sets whether this toolbar is enabled and accepts input.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:setButtonEnabled(1, true)
  lurek.log.info("LToolbar:setButtonEnabled applied", "ui")
end


--@api-stub: LToolbar:setButtonToggled
-- Sets the button toggled of this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:setButtonToggled(1, 1.0)
  lurek.log.info("LToolbar:setButtonToggled applied", "ui")
end


--@api-stub: LToolbar:isButtonToggled
-- Returns true if this toolbar button toggled.
do
  local tb = lurek.ui.newToolbar("horizontal")
  local val = tb:isButtonToggled(1)
  lurek.log.info("LToolbar:isButtonToggled=" .. tostring(val), "ui")
end


-- LTooltipPanel methods


--@api-stub: LTooltipPanel:getText
-- Returns the text of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  local val = tp:getText()
  lurek.log.info("LTooltipPanel:getText=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setText
-- Sets the text of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  tp:setText("Hello, world!")
  lurek.log.info("LTooltipPanel:setText applied", "ui")
end


--@api-stub: LTooltipPanel:getDelay
-- Returns the delay of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  local val = tp:getDelay()
  lurek.log.info("LTooltipPanel:getDelay=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setDelay
-- Sets the delay of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  tp:setDelay(1.0)
  lurek.log.info("LTooltipPanel:setDelay applied", "ui")
end


--@api-stub: LTooltipPanel:getTarget
-- Returns the target of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  local val = tp:getTarget()
  lurek.log.info("LTooltipPanel:getTarget=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setTarget
-- Sets the target of this tooltip panel.
do
  local tp = lurek.ui.newTooltipPanel("Info")
  tp:setTarget(1.0)
  lurek.log.info("LTooltipPanel:setTarget applied", "ui")
end


-- LTreeView methods


--@api-stub: LTreeView:addNode
-- Adds a node to this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Hello, world!", 1.0)
  lurek.log.info("LTreeView:addNode done", "ui")
end


--@api-stub: LTreeView:toggleNode
-- Toggles the node state of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:toggleNode(1)
  lurek.log.info("LTreeView:toggleNode=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:isExpanded
-- Returns true if this tree view expanded.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:isExpanded(1)
  lurek.log.info("LTreeView:isExpanded=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:getNodeCount
-- Returns the number of node items in this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getNodeCount()
  lurek.log.info("LTreeView:getNodeCount=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:removeNode
-- Removes a node from this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:removeNode(1)
  lurek.log.info("LTreeView:removeNode done", "ui")
end


--@api-stub: LTreeView:clearNodes
-- Clears all nodes items from this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:clearNodes()
  lurek.log.info("LTreeView:clearNodes done", "ui")
end


--@api-stub: LTreeView:getNodeText
-- Returns the node text of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getNodeText(1)
  lurek.log.info("LTreeView:getNodeText=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:setNodeText
-- Sets the node text of this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:setNodeText(1, "Hello, world!")
  lurek.log.info("LTreeView:setNodeText applied", "ui")
end


--@api-stub: LTreeView:setNodeIcon
-- Sets the node icon of this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:setNodeIcon(1, 1.0)
  lurek.log.info("LTreeView:setNodeIcon applied", "ui")
end


--@api-stub: LTreeView:expandNode
-- Expands this tree view to show its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:expandNode(1)
  lurek.log.info("LTreeView:expandNode called", "ui")
end


--@api-stub: LTreeView:collapseNode
-- Collapses this tree view to hide its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:collapseNode(1)
  lurek.log.info("LTreeView:collapseNode called", "ui")
end


--@api-stub: LTreeView:isNodeExpanded
-- Returns true if this tree view node expanded.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:isNodeExpanded(1)
  lurek.log.info("LTreeView:isNodeExpanded=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:expandAll
-- Expands this tree view to show its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:expandAll()
  lurek.log.info("LTreeView:expandAll called", "ui")
end


--@api-stub: LTreeView:collapseAll
-- Collapses this tree view to hide its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:collapseAll()
  lurek.log.info("LTreeView:collapseAll called", "ui")
end


--@api-stub: LTreeView:setSelectedNode
-- Sets the selected node of this tree view.
do
  local tree = lurek.ui.newTreeView()
  tree:setSelectedNode(1)
  lurek.log.info("LTreeView:setSelectedNode applied", "ui")
end


--@api-stub: LTreeView:getSelectedNode
-- Returns the selected node of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getSelectedNode()
  lurek.log.info("LTreeView:getSelectedNode=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:getChildNodes
-- Returns the child nodes of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getChildNodes(1)
  lurek.log.info("LTreeView:getChildNodes=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:getParentNode
-- Returns the parent node of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getParentNode(1)
  lurek.log.info("LTreeView:getParentNode=" .. tostring(val), "ui")
end


--@api-stub: LTreeView:getNodeDepth
-- Returns the node depth of this tree view.
do
  local tree = lurek.ui.newTreeView()
  local val = tree:getNodeDepth(1)
  lurek.log.info("LTreeView:getNodeDepth=" .. tostring(val), "ui")
end


-- LUiWidget methods


--@api-stub: LUiWidget:type
-- Returns the Lua-visible type name string for this ui widget handle.
do
  local w = lurek.ui.newPanel()
  local val = w:type()
  lurek.log.info("LUiWidget:type=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:typeOf
-- Returns true if this ui widget handle matches the given type name string.
do
  local w = lurek.ui.newPanel()
  local val = w:typeOf("hero")
  lurek.log.info("LUiWidget:typeOf=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setPosition
-- Sets the position of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setPosition(0.0, 0.0)
  lurek.log.info("LUiWidget:setPosition applied", "ui")
end


--@api-stub: LUiWidget:getPosition
-- Returns the position of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getPosition()
  lurek.log.info("LUiWidget:getPosition=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setSize
-- Sets the size of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setSize(64.0, 64.0)
  lurek.log.info("LUiWidget:setSize applied", "ui")
end


--@api-stub: LUiWidget:getSize
-- Returns the size of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getSize()
  lurek.log.info("LUiWidget:getSize=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:getRect
-- Returns the rect of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getRect()
  lurek.log.info("LUiWidget:getRect=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setVisible
-- Sets the visibility flag for this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setVisible(1.0)
  lurek.log.info("LUiWidget:setVisible applied", "ui")
end


--@api-stub: LUiWidget:isVisible
-- Returns true if this ui widget is currently visible.
do
  local w = lurek.ui.newPanel()
  local val = w:isVisible()
  lurek.log.info("LUiWidget:isVisible=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setEnabled
-- Sets whether this ui widget is enabled and accepts input.
do
  local w = lurek.ui.newPanel()
  w:setEnabled(1.0)
  lurek.log.info("LUiWidget:setEnabled applied", "ui")
end


--@api-stub: LUiWidget:isEnabled
-- Returns true if this ui widget is currently enabled.
do
  local w = lurek.ui.newPanel()
  local val = w:isEnabled()
  lurek.log.info("LUiWidget:isEnabled=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setId
-- Sets the id of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setId(1)
  lurek.log.info("LUiWidget:setId applied", "ui")
end


--@api-stub: LUiWidget:getId
-- Returns the id of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getId()
  lurek.log.info("LUiWidget:getId=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setTooltip
-- Sets the tooltip of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setTooltip("Hello, world!")
  lurek.log.info("LUiWidget:setTooltip applied", "ui")
end


--@api-stub: LUiWidget:getTooltip
-- Returns the tooltip of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getTooltip()
  lurek.log.info("LUiWidget:getTooltip=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:getState
-- Returns the state of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getState()
  lurek.log.info("LUiWidget:getState=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:addChild
-- Adds a child to this ui widget.
do
  local w = lurek.ui.newPanel()
  w:addChild(1.0)
  lurek.log.info("LUiWidget:addChild done", "ui")
end


--@api-stub: LUiWidget:removeChild
-- Removes a child from this ui widget.
do
  local w = lurek.ui.newPanel()
  w:removeChild(1.0)
  lurek.log.info("LUiWidget:removeChild done", "ui")
end


--@api-stub: LUiWidget:getChildCount
-- Returns the number of child items in this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getChildCount()
  lurek.log.info("LUiWidget:getChildCount=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:getChildren
-- Returns the children of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getChildren()
  lurek.log.info("LUiWidget:getChildren=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:findById
-- Finds and returns the by id in this ui widget by name or id.
do
  local w = lurek.ui.newPanel()
  w:findById(1)
  lurek.log.info("LUiWidget:findById called", "ui")
end


--@api-stub: LUiWidget:setOnClick
-- Sets the on click of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setOnClick(function() end)
  lurek.log.info("LUiWidget:setOnClick callback set", "ui")
end


--@api-stub: LUiWidget:setOnChange
-- Sets the on change of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setOnChange(function() end)
  lurek.log.info("LUiWidget:setOnChange callback set", "ui")
end


--@api-stub: LUiWidget:setOnDraw
-- Sets the on draw of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setOnDraw(function() end)
  lurek.log.info("LUiWidget:setOnDraw callback set", "ui")
end


--@api-stub: LUiWidget:containsPoint
-- Performs the contains point operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:containsPoint(0.0, 0.0)
  lurek.log.info("LUiWidget:containsPoint=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setPadding
-- Sets the padding of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setPadding(64.0, 64.0, 64.0, 64.0)
  lurek.log.info("LUiWidget:setPadding applied", "ui")
end


--@api-stub: LUiWidget:getPadding
-- Returns the padding of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getPadding()
  lurek.log.info("LUiWidget:getPadding=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setMargin
-- Sets the margin of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setMargin(64.0, 64.0, 64.0, 64.0)
  lurek.log.info("LUiWidget:setMargin applied", "ui")
end


--@api-stub: LUiWidget:getMargin
-- Returns the margin of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getMargin()
  lurek.log.info("LUiWidget:getMargin=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setZOrder
-- Sets the z order of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setZOrder(0)
  lurek.log.info("LUiWidget:setZOrder applied", "ui")
end


--@api-stub: LUiWidget:getZOrder
-- Returns the z order of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getZOrder()
  lurek.log.info("LUiWidget:getZOrder=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setMinSize
-- Sets the min size of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setMinSize(64.0, 64.0)
  lurek.log.info("LUiWidget:setMinSize applied", "ui")
end


--@api-stub: LUiWidget:getMinSize
-- Returns the min size of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getMinSize()
  lurek.log.info("LUiWidget:getMinSize=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setMaxSize
-- Sets the max size of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setMaxSize(64.0, 64.0)
  lurek.log.info("LUiWidget:setMaxSize applied", "ui")
end


--@api-stub: LUiWidget:getMaxSize
-- Returns the max size of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getMaxSize()
  lurek.log.info("LUiWidget:getMaxSize=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setAnchor
-- Sets the anchor of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setAnchor()
  lurek.log.info("LUiWidget:setAnchor applied", "ui")
end


--@api-stub: LUiWidget:setAnchorCenter
-- Sets the anchor center of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setAnchorCenter(1.0, 1.0)
  lurek.log.info("LUiWidget:setAnchorCenter applied", "ui")
end


--@api-stub: LUiWidget:clearAnchor
-- Clears all anchor items from this ui widget.
do
  local w = lurek.ui.newPanel()
  w:clearAnchor()
  lurek.log.info("LUiWidget:clearAnchor done", "ui")
end


--@api-stub: LUiWidget:setFlexGrow
-- Sets the flex grow of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setFlexGrow(1.0)
  lurek.log.info("LUiWidget:setFlexGrow applied", "ui")
end


--@api-stub: LUiWidget:getFlexGrow
-- Returns the flex grow of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getFlexGrow()
  lurek.log.info("LUiWidget:getFlexGrow=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:setFlexShrink
-- Sets the flex shrink of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setFlexShrink(1.0)
  lurek.log.info("LUiWidget:setFlexShrink applied", "ui")
end


--@api-stub: LUiWidget:getFlexShrink
-- Returns the flex shrink of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getFlexShrink()
  lurek.log.info("LUiWidget:getFlexShrink=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:bind
-- Performs the bind operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:bind("player_score")
  lurek.log.info("LUiWidget:bind called", "ui")
end


--@api-stub: LUiWidget:unbind
-- Performs the unbind operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:unbind()
  lurek.log.info("LUiWidget:unbind called", "ui")
end


--@api-stub: LUiWidget:setAlpha
-- Sets the alpha of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setAlpha(1.0)
  lurek.log.info("LUiWidget:setAlpha applied", "ui")
end


--@api-stub: LUiWidget:getAlpha
-- Returns the alpha of this ui widget.
do
  local w = lurek.ui.newPanel()
  local val = w:getAlpha()
  lurek.log.info("LUiWidget:getAlpha=" .. tostring(val), "ui")
end


--@api-stub: LUiWidget:fadeIn
-- Performs the fade in operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:fadeIn()
  lurek.log.info("LUiWidget:fadeIn called", "ui")
end


--@api-stub: LUiWidget:fadeOut
-- Performs the fade out operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:fadeOut()
  lurek.log.info("LUiWidget:fadeOut called", "ui")
end


--@api-stub: LUiWidget:slideIn
-- Performs the slide in operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:slideIn(0.0, 0.0)
  lurek.log.info("LUiWidget:slideIn called", "ui")
end


--@api-stub: LUiWidget:slideOut
-- Performs the slide out operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:slideOut(0.0, 0.0)
  lurek.log.info("LUiWidget:slideOut called", "ui")
end


--@api-stub: LUiWidget:attachToEntity
-- Performs the attach to entity operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:attachToEntity(1.0)
  lurek.log.info("LUiWidget:attachToEntity called", "ui")
end


--@api-stub: LUiWidget:detachFromEntity
-- Performs the detach from entity operation on this ui widget.
do
  local w = lurek.ui.newPanel()
  w:detachFromEntity()
  lurek.log.info("LUiWidget:detachFromEntity called", "ui")
end

