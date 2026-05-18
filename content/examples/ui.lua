-- content/examples/ui.lua
-- Demonstrates every lurek.ui.* function with realistic game UI patterns.
-- Run: cargo run -- content/examples/ui.lua

--@api-stub: lurek.ui.beginDrag
-- Begins a drag operation on a widget
do
  -- Start dragging an inventory item when the player holds left-click.
  -- The widget follows the cursor until dropOn() or endDrag() is called.
  local slot = lurek.ui.newButton("Iron Sword")
  lurek.ui.beginDrag(slot)
end

--@api-stub: lurek.ui.getActiveDrag
-- Returns the widget index currently being dragged, or nil
do
  -- Check if the player is currently moving an item between inventory slots.
  -- Returns nil when nothing is being dragged — useful for cursor icon switching.
  local dragged = lurek.ui.getActiveDrag()
  if dragged then
    print("Currently dragging widget:", dragged)
  end
end

--@api-stub: lurek.ui.dropOn
-- Drops the currently dragged widget onto a target widget
do
  -- Simulate equipping an item: drag from inventory, drop onto equipment slot.
  -- The target widget receives the dragged widget as a new child.
  local equipment_slot = lurek.ui.newPanel()
  local item = lurek.ui.newLabel("Steel Shield")
  lurek.ui.beginDrag(item)
  lurek.ui.dropOn(equipment_slot)
end

--@api-stub: lurek.ui.endDrag
-- Ends the current drag operation without dropping
do
  -- Cancel the drag if the player releases outside any valid drop target.
  -- Returns the widget that was being dragged so you can snap it back.
  local cancelled_widget = lurek.ui.endDrag()
  print("Drag cancelled, returning widget:", cancelled_widget)
end

--@api-stub: LUiWidget:animateAlpha
-- Performs the animate alpha operation on this ui widget.
do
  -- Fade a damage indicator to transparent over 0.25 seconds.
  -- Parameters: target alpha, duration, loop flag.
  local damage_text = lurek.ui.newLabel("-42 HP")
  damage_text:animateAlpha(0.0, 0.25, false)
end

--@api-stub: LUiWidget:animatePosition
-- Performs the animate position operation on this ui widget.
do
  -- Slide a notification toast from off-screen to its final position.
  -- Parameters: target x, target y, duration in seconds.
  local toast = lurek.ui.newLabel("Quest Complete!")
  toast:animatePosition(120, 40, 0.25)
end

--@api-stub: LUiWidget:isAnimating
-- Returns true if this ui widget animating.
do
  -- Poll animation state to prevent input during transitions.
  -- Useful to block button clicks while a menu is still sliding in.
  local menu = lurek.ui.newLabel("Main Menu")
  local busy = menu:isAnimating()
  print("Menu animating:", busy)
end

--@api-stub: LUiWidget:cancelAnimations
-- Performs the cancel animations operation on this ui widget.
do
  -- Immediately stop all running animations on a widget.
  -- Use when the player opens a new screen and old transitions are irrelevant.
  local dialog = lurek.ui.newLabel("Loading...")
  dialog:cancelAnimations()
end

--@api-stub: LUiWidget:setPosition
-- Sets the position of this ui widget.
do
  -- setPosition is a method on each widget instance (not a lurek.ui global).
  -- Use colon syntax: widget:setPosition(x, y) — a method on the widget instance.
  local label = lurek.ui.newLabel("HP: 100")
  label:setPosition(100, 200)
end

--@api-stub: LUiWidget:getPosition
-- Returns the position of this ui widget.
do
  -- getPosition is also a widget method; use colon syntax.
  local label = lurek.ui.newLabel("Score: 0")
  label:setPosition(50, 100)
  local x, y = label:getPosition()
  print("Widget at:", x, y)
end

--@api-stub: LUiWidget:setSize
-- Sets the size of this ui.
do
  -- Resize the dialog box to fit varying amounts of NPC dialogue text.
  -- Width and height in pixels; respects min/max size constraints if set.
  local _w = lurek.ui.newLabel("ui")
  _w:setSize(320, 80)
end

--@api-stub: LUiWidget:getSize
-- Returns the size of this ui.
do
  -- Query the panel size to center a child element manually.
  local _w = lurek.ui.newLabel("ui")
  local w, h = _w:getSize()
  print("Panel size:", w, "x", h)
end

--@api-stub: LUiWidget:getRect
-- Returns the rect of this ui.
do
  -- Get the bounding rectangle (x, y, w, h) for hit-testing or overlap checks.
  -- Useful for custom tooltip positioning relative to the widget bounds.
  local _w = lurek.ui.newLabel("ui")
  local rect = _w:getRect()
  print("Bounding rect:", rect)
end

--@api-stub: LUiWidget:setVisible
-- Sets the visibility flag for this ui.
do
  -- Show the game-over screen when the player's HP reaches zero.
  -- Hidden widgets skip rendering but keep their layout slot.
  local _w = lurek.ui.newLabel("ui")
  _w:setVisible(true)
end

--@api-stub: LUiWidget:isVisible
-- Returns true if this ui is currently visible.
do
  -- Check visibility before toggling — avoids redundant show/hide calls.
  local _w = lurek.ui.newLabel("ui")
  local shown = _w:isVisible()
  print("Currently visible:", shown)
end

--@api-stub: LUiWidget:setEnabled
-- Sets whether this ui is enabled and accepts input.
do
  -- Disable the "Buy" button when the player lacks enough gold.
  -- Disabled widgets render with reduced alpha and ignore clicks.
  local _w = lurek.ui.newLabel("ui")
  _w:setEnabled(true)
end

--@api-stub: LUiWidget:isEnabled
-- Returns true if this ui is currently enabled.
do
  -- Guard input handlers — skip processing if the widget is disabled.
  local _w = lurek.ui.newLabel("ui")
  local active = _w:isEnabled()
  print("Accepts input:", active)
end

--@api-stub: LUiWidget:setId
-- Sets the id of this ui.
do
  -- Assign a unique string ID for later lookup with findById().
  -- IDs should be stable across frames (e.g. "hud_health", "btn_attack").
  local _w = lurek.ui.newLabel("ui")
  _w:setId("hud_health_bar")
end

--@api-stub: LUiWidget:getId
-- Returns the id of this ui.
do
  -- Retrieve the ID to log which widget received a click event.
  local _w = lurek.ui.newLabel("ui")
  local id = _w:getId()
  print("Clicked widget ID:", id)
end

--@api-stub: LUiWidget:setTooltip
-- Sets the tooltip of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:setTooltip("Hello")
  print("applied")
end

--@api-stub: LUiWidget:getTooltip
-- Returns the tooltip of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:setTooltip("Info")
  local v = _w:getTooltip()
  print("getTooltip:", v)
end

--@api-stub: LUiWidget:getState
-- Returns the state of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getState()
  print("getState:", v)
end

--@api-stub: LUiWidget:addChild
-- Adds a child to this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:addChild(lurek.ui.newButton("x"))
  print("added")
end

--@api-stub: LUiWidget:removeChild
-- Removes a child from this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:removeChild(lurek.ui.newButton("x"))
  print("done")
end

--@api-stub: LUiWidget:getChildCount
-- Returns the number of child items in this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getChildCount()
  print("getChildCount:", v)
end

--@api-stub: LUiWidget:getChildren
-- Returns the children of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getChildren()
  print("getChildren:", v)
end

--@api-stub: LUiWidget:findById
-- Finds and returns the by id in this ui by name or id.
do
  -- Retrieve a widget reference by its unique ID string.
  -- Use this to update HUD elements from game logic, e.g. a score label.
  local _w = lurek.ui.newLabel("ui")
  local v = _w:findById("widget_id")
  print("findById:", v)
end

--@api-stub: LMenuItem:setOnClick
-- Sets the on click of this ui.
do
  -- Register a click handler — fires when the player clicks/taps this widget.
  -- Common for menu buttons, inventory slots, shop items.
  local _w = lurek.ui.newLabel("ui")
  _w:setOnClick(function()
    print("event")
  end)
  print("applied")
end

--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this ui.
do
  -- Fires when the widget value changes (slider moved, checkbox toggled, text typed).
  -- Use to apply settings in real-time, e.g. volume slider updates audio bus.
  local _w = lurek.ui.newLabel("ui")
  _w:setOnChange(function()
    print("event")
  end)
  print("applied")
end

--@api-stub: LUiWidget:setOnDraw
-- Sets the on draw of this ui.
do
  -- Custom draw callback — invoked every frame for this widget.
  -- Use for custom rendering: minimap overlays, dynamic health bars, graphs.
  local _w = lurek.ui.newLabel("ui")
  _w:setOnDraw(function()
    print("event")
  end)
  print("applied")
end

--@api-stub: LUiWidget:containsPoint
-- Performs the contains point operation on this ui.
do
  -- Hit-test: returns true if (x, y) is inside the widget bounds.
  -- Useful for custom drag-and-drop or tooltip positioning logic.
  local _w = lurek.ui.newLabel("ui")
  local v = _w:containsPoint(0, 0)
  print("containsPoint:", v)
end

--@api-stub: LUiWidget:setPadding
-- Sets the padding of this ui.
do
  -- Inner spacing between widget border and content (in pixels).
  -- Keeps text/icons from touching edges — standard for dialog panels.
  local _w = lurek.ui.newLabel("ui")
  _w:setPadding(8)
  print("applied")
end

--@api-stub: LUiWidget:getPadding
-- Returns the padding of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getPadding()
  print("getPadding:", v)
end

--@api-stub: LUiWidget:setMargin
-- Sets the margin of this ui.
do
  -- Outer spacing between this widget and its neighbors (in pixels).
  -- Use to space out toolbar buttons or list items evenly.
  local _w = lurek.ui.newLabel("ui")
  _w:setMargin(8)
  print("applied")
end

--@api-stub: LUiWidget:getMargin
-- Returns the margin of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getMargin()
  print("getMargin:", v)
end

--@api-stub: LUiWidget:setZOrder
-- Sets the z order of this ui.
do
  -- Controls draw order: higher z = drawn on top.
  -- Use to ensure popups/tooltips render above the game HUD.
  local _w = lurek.ui.newLabel("ui")
  _w:setZOrder(1)
  print("applied")
end

--@api-stub: LUiWidget:getZOrder
-- Returns the z order of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getZOrder()
  print("getZOrder:", v)
end

--@api-stub: LUiWidget:setMinSize
-- Sets the min size of this ui.
do
  -- Prevents the widget from shrinking below this size during layout.
  -- Important for buttons that must remain clickable on small screens.
  local _w = lurek.ui.newLabel("ui")
  _w:setMinSize(200, 50)
  print("applied")
end

--@api-stub: LUiWidget:getMinSize
-- Returns the min size of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getMinSize()
  print("getMinSize:", v)
end

--@api-stub: LUiWidget:setMaxSize
-- Sets the max size of this ui.
do
  -- Caps the widget size — prevents expansion beyond this limit.
  -- Useful for chat bubbles or tooltips that should not fill the screen.
  local _w = lurek.ui.newLabel("ui")
  _w:setMaxSize(200, 50)
  print("applied")
end

--@api-stub: LUiWidget:getMaxSize
-- Returns the max size of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getMaxSize()
  print("getMaxSize:", v)
end

--@api-stub: LUiWidget:setAnchor
-- Sets the anchor of this ui.
do
  -- Pins widget edges to parent with pixel offsets (top, right, bottom, left).
  -- Classic use: anchor a health bar to the top-left corner of the screen.
  local _w = lurek.ui.newLabel("ui")
  _w:setAnchor(8, 8, 8, 8)
  print("applied")
end

--@api-stub: LUiWidget:setAnchorCenter
-- Sets the anchor center of this ui.
do
  -- Centers the widget in its parent with an optional pixel offset.
  -- Perfect for pause menus, "Game Over" screens, or modal dialogs.
  local _w = lurek.ui.newLabel("ui")
  _w:setAnchorCenter(0, 0)
  print("applied")
end

--@api-stub: LUiWidget:clearAnchor
-- Clears all anchor items from this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:clearAnchor()
  print("done")
end

--@api-stub: LUiWidget:setFlexGrow
-- Sets the flex grow of this ui.
do
  -- Flex grow factor: how much extra space this widget claims.
  -- Set to 1 on a content panel to fill remaining space in a toolbar layout.
  local _w = lurek.ui.newLabel("ui")
  _w:setFlexGrow(1)
  print("applied")
end

--@api-stub: LUiWidget:getFlexGrow
-- Returns the flex grow of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getFlexGrow()
  print("getFlexGrow:", v)
end

--@api-stub: LUiWidget:setFlexShrink
-- Sets the flex shrink of this ui.
do
  -- Flex shrink factor: how much this widget can compress when space is tight.
  -- Set to 0 on critical buttons so they never disappear on narrow screens.
  local _w = lurek.ui.newLabel("ui")
  _w:setFlexShrink(1)
  print("applied")
end

--@api-stub: LUiWidget:getFlexShrink
-- Returns the flex shrink of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getFlexShrink()
  print("getFlexShrink:", v)
end

--@api-stub: LUiWidget:bind
-- Performs the bind operation on this ui.
do
  -- Binds this widget to a data key for reactive updates.
  -- When the bound value changes, the widget refreshes automatically.
  local _w = lurek.ui.newLabel("ui")
  _w:bind("key")
  print("bind called")
end

--@api-stub: LUiWidget:unbind
-- Performs the unbind operation on this ui.
do
  local _w = lurek.ui.newLabel("ui")
  _w:unbind()
  print("unbind called")
end

--@api-stub: LUiWidget:setAlpha
-- Sets the alpha of this ui.
do
  -- Opacity from 0.0 (invisible) to 1.0 (fully opaque).
  -- Dim inactive panels to 0.5 so players focus on the active one.
  local _w = lurek.ui.newLabel("ui")
  _w:setAlpha(0.85)
  print("applied")
end

--@api-stub: LUiWidget:getAlpha
-- Returns the alpha of this ui.
do
  local _w = lurek.ui.newLabel("ui")
  local v = _w:getAlpha()
  print("getAlpha:", v)
end

--@api-stub: LUiWidget:fadeIn
-- Performs the fade in operation on this ui.
do
  -- Smoothly transitions alpha from 0 to 1.
  -- Use when showing a notification banner or quest popup.
  local _w = lurek.ui.newLabel("ui")
  _w:fadeIn()
  print("fadeIn called")
end

--@api-stub: LUiWidget:fadeOut
-- Performs the fade out operation on this ui.
do
  -- Smoothly transitions alpha from 1 to 0, then hides the widget.
  -- Use to dismiss toast messages or temporary damage numbers.
  local _w = lurek.ui.newLabel("ui")
  _w:fadeOut()
  print("fadeOut called")
end

--@api-stub: LUiWidget:slideIn
-- Performs the slide in operation on this ui.
do
  -- Animates the widget in from an offset (dx, dy) to its final position.
  -- Slide a side panel in from the left: slideIn(-300, 0)
  local _w = lurek.ui.newLabel("ui")
  _w:slideIn(0, 0)
  print("slideIn called")
end

--@api-stub: LUiWidget:slideOut
-- Performs the slide out operation on this ui.
do
  -- Animates the widget out to the given offset and hides it.
  -- Dismiss a bottom drawer: slideOut(0, 200)
  local _w = lurek.ui.newLabel("ui")
  _w:slideOut(0, 0)
  print("slideOut called")
end

--@api-stub: LUiWidget:attachToEntity
-- Performs the attach to entity operation on this ui.
do
  -- Pins this widget above a game entity so it follows movement.
  -- Use for floating name tags, health bars, or speech bubbles over NPCs.
  local _w = lurek.ui.newLabel("ui")
  _w:attachToEntity(1)
  print("attachToEntity called")
end

--@api-stub: LUiWidget:detachFromEntity
-- Performs the detach from entity operation on this ui.
do
  -- Releases entity tracking — widget stays at its last screen position.
  -- Call when an NPC dies so the health bar can fade out in place.
  local _w = lurek.ui.newLabel("ui")
  _w:detachFromEntity()
  print("detachFromEntity called")
end


---@return table
local function new_example_image_widget()
  return {}
end

--@api-stub: LTooltipPanel:setText
-- Sets the text of this button.
do
  -- Change button label at runtime — e.g. toggle "Pause" / "Resume".
  local btn = lurek.ui.newButton("Play")
  btn:setText("Hello")
end

--@api-stub: LTooltipPanel:getText
-- Returns the text of this button.
do
  local btn = lurek.ui.newButton("Play")
  local v = btn:getText()
  print("getText:", v)
end

-- Label methods

--@api-stub: LTooltipPanel:setText
-- Sets the text of this label.
do
  local lbl = lurek.ui.newLabel("Score: 0")
  lbl:setText("Hello")
end

--@api-stub: LTooltipPanel:getText
-- Returns the text of this label.
do
  local lbl = lurek.ui.newLabel("Score: 0")
  local v = lbl:getText()
  print("getText:", v)
end

-- Text_Input methods

--@api-stub: LTooltipPanel:setText
-- Sets the text of this text_input.
do
  local ti = lurek.ui.newTextInput()
  ti:setText("Hello")
end

--@api-stub: LTooltipPanel:getText
-- Returns the text of this text_input.
do
  local ti = lurek.ui.newTextInput()
  local v = ti:getText()
  print("getText:", v)
end

--@api-stub: LTextInput:setPlaceholder
-- Sets the placeholder of this text_input.
do
  local ti = lurek.ui.newTextInput()
  ti:setPlaceholder("Hello")
end

--@api-stub: LTextInput:getPlaceholder
-- Returns the placeholder of this text_input.
do
  local ti = lurek.ui.newTextInput()
  local v = ti:getPlaceholder()
  print("getPlaceholder:", v)
end

--@api-stub: LTextInput:setMaxLength
-- Sets the max length of this text_input.
do
  local ti = lurek.ui.newTextInput()
  ti:setMaxLength(100)
end

--@api-stub: LTextInput:isFocused
-- Returns true if this text_input focused.
do
  local ti = lurek.ui.newTextInput()
  local v = ti:isFocused()
  print("isFocused:", v)
end

--@api-stub: LTextInput:getCursorPosition
-- Returns the cursor position of this text_input.
do
  local ti = lurek.ui.newTextInput()
  local v = ti:getCursorPosition()
  print("getCursorPosition:", v)
end

-- Checkbox methods

--@api-stub: LMenuItem:setChecked
-- Sets the checked of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Sound")
  cb:setChecked(true)
end

--@api-stub: LMenuItem:isChecked
-- Returns true if this checkbox checked.
do
  local cb = lurek.ui.newCheckbox("Sound")
  local v = cb:isChecked()
  print("isChecked:", v)
end

--@api-stub: LTooltipPanel:setText
-- Sets the text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Sound")
  cb:setText("Hello")
end

--@api-stub: LTooltipPanel:getText
-- Returns the text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Sound")
  local v = cb:getText()
  print("getText:", v)
end

-- Slider methods

--@api-stub: LSpinBox:setValue
-- Sets the value of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  sl:setValue(0.5)
end

--@api-stub: LSpinBox:getValue
-- Returns the value of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  local v = sl:getValue()
  print("getValue:", v)
end

--@api-stub: LSpinBox:setRange
-- Sets the range of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  sl:setRange(0, 100)
end

--@api-stub: LSpinBox:setStep
-- Sets the step of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  sl:setStep(1)
end

--@api-stub: LProgressBar:getMin
-- Returns the min of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  local v = sl:getMin()
  print("getMin:", v)
end

--@api-stub: LProgressBar:getMax
-- Returns the max of this slider.
do
  local sl = lurek.ui.newSlider(0, 100)
  local v = sl:getMax()
  print("getMax:", v)
end

-- Progress_Bar methods

--@api-stub: LSpinBox:setValue
-- Sets the value of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  pb:setValue(0.5)
end

--@api-stub: LSpinBox:getValue
-- Returns the value of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  local v = pb:getValue()
  print("getValue:", v)
end

--@api-stub: LToast:getProgress
-- Returns the progress of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  local v = pb:getProgress()
  print("getProgress:", v)
end

--@api-stub: LSpinBox:setRange
-- Sets the range of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  pb:setRange(0, 100)
end

--@api-stub: LProgressBar:getMin
-- Returns the min of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  local v = pb:getMin()
  print("getMin:", v)
end

--@api-stub: LProgressBar:getMax
-- Returns the max of this progress_bar.
do
  local pb = lurek.ui.newProgressBar()
  local v = pb:getMax()
  print("getMax:", v)
end

-- Combo_Box methods

--@api-stub: LListBox:addItem
-- Adds a item to this combo_box.
do
  -- ComboBox items can be added at runtime — useful for populating
  -- difficulty selectors or resolution lists after loading user config.
  local cb = lurek.ui.newComboBox()
  cb:addItem("Nightmare") -- append a new option discovered from DLC or unlocks
end

--@api-stub: LListBox:removeItem
-- Removes a item from this combo_box.
do
  local cb = lurek.ui.newComboBox()
  cb:removeItem(1)
end

--@api-stub: LListBox:clearItems
-- Clears all items items from this combo_box.
do
  local cb = lurek.ui.newComboBox()
  cb:clearItems()
end

--@api-stub: LListBox:getItemCount
-- Returns the number of item items in this combo_box.
do
  local cb = lurek.ui.newComboBox()
  local v = cb:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: LListBox:getItem
-- Returns the item of this combo_box.
do
  local cb = lurek.ui.newComboBox()
  local v = cb:getItem(1)
  print("getItem:", v)
end

--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index of this combo_box.
do
  -- Programmatically select an item — e.g. restore the player's
  -- saved difficulty preference when re-opening the options menu.
  local cb = lurek.ui.newComboBox()
  cb:setSelectedIndex(2) -- select "Normal" (1-based index)
end

--@api-stub: LListBox:getSelectedIndex
-- Returns the selected index of this combo_box.
do
  local cb = lurek.ui.newComboBox()
  local v = cb:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: LComboBox:getSelectedItem
-- Returns the selected item of this combo_box.
do
  local cb = lurek.ui.newComboBox()
  local v = cb:getSelectedItem()
  print("getSelectedItem:", v)
end

-- List_Box methods

--@api-stub: LListBox:addItem
-- Adds a item to this list_box.
do
  local w = lurek.ui.newList()
  w:addItem("item_1")
end

--@api-stub: LListBox:removeItem
-- Removes a item from this list_box.
do
  local w = lurek.ui.newList()
  w:removeItem(1)
end

--@api-stub: LListBox:clearItems
-- Clears all items items from this list_box.
do
  local w = lurek.ui.newList()
  w:clearItems()
end

--@api-stub: LListBox:getItemCount
-- Returns the number of item items in this list_box.
do
  local w = lurek.ui.newList()
  local v = w:getItemCount()
  print("getItemCount:", v)
end

--@api-stub: LListBox:getItem
-- Returns the item of this list_box.
do
  local w = lurek.ui.newList()
  local v = w:getItem(1)
  print("getItem:", v)
end

--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index of this list_box.
do
  local w = lurek.ui.newList()
  w:setSelectedIndex(1)
end

--@api-stub: LListBox:getSelectedIndex
-- Returns the selected index of this list_box.
do
  local w = lurek.ui.newList()
  local v = w:getSelectedIndex()
  print("getSelectedIndex:", v)
end

--@api-stub: LListBox:setItemHeight
-- Sets the item height of this list_box.
do
  local w = lurek.ui.newList()
  w:setItemHeight(50)
end

-- Tab_Bar methods

--@api-stub: LTabBar:addTab
-- Adds a tab to this tab_bar.
do
  -- TabBars hold child widgets as tab content. Each tab can contain
  -- a full sub-panel — equipment grid, stat sheet, or world map.
  local tabs = lurek.ui.newTabBar()
  tabs:addTab("Journal") -- dynamically add a tab unlocked mid-game
end

--@api-stub: LTabBar:removeTab
-- Removes a tab from this tab_bar.
do
  local tabs = lurek.ui.newTabBar()
  tabs:addTab("Tab1"); tabs:addTab("Tab2")
  tabs:removeTab(1)
end

--@api-stub: LTabBar:getTab
-- Returns the tab of this tab_bar.
do
  local tabs = lurek.ui.newTabBar()
  tabs:addTab("Inventory")
  local v = tabs:getTab(1)
  print("getTab:", v)
end

--@api-stub: LTabBar:getTabCount
-- Returns the number of tab items in this tab_bar.
do
  local tabs = lurek.ui.newTabBar()
  local v = tabs:getTabCount()
  print("getTabCount:", v)
end

--@api-stub: LTabBar:setActiveTab
-- Sets the active tab of this tab_bar.
do
  -- Switch the visible tab programmatically — e.g. open the Map tab
  -- when the player presses 'M' as a keyboard shortcut.
  local tabs = lurek.ui.newTabBar()
  tabs:setActiveTab(3) -- jump directly to the Map tab
end

--@api-stub: LTabBar:getActiveTab
-- Returns the active tab of this tab_bar.
do
  local tabs = lurek.ui.newTabBar()
  local v = tabs:getActiveTab()
  print("getActiveTab:", v)
end

-- Spin_Box methods

--@api-stub: LSpinBox:setValue
-- Sets the value of this spin_box.
do
  local spin = lurek.ui.newSpinBox()
  spin:setValue(0.5)
end

--@api-stub: LSpinBox:getValue
-- Returns the value of this spin_box.
do
  local spin = lurek.ui.newSpinBox()
  local v = spin:getValue()
  print("getValue:", v)
end

--@api-stub: LSpinBox:increment
-- Increments the value of this spin_box by one step.
do
  local spin = lurek.ui.newSpinBox()
  spin:increment()
end

--@api-stub: LSpinBox:decrement
-- Decrements the value of this spin_box by one step.
do
  local spin = lurek.ui.newSpinBox()
  spin:decrement()
end

--@api-stub: LSpinBox:setRange
-- Sets the range of this spin_box.
do
  -- Clamp the spin box to valid bounds — prevents players from
  -- entering impossible values like negative party size or 999 lives.
  local spin = lurek.ui.newSpinBox()
  spin:setRange(1, 99) -- min=1 (e.g. at least 1 party member)
end

--@api-stub: LSpinBox:setStep
-- Sets the step of this spin_box.
do
  -- Step controls the increment per click/arrow press.
  -- Use 5 for volume (0-100), 1 for item count, 0.1 for fine-tuning.
  local spin = lurek.ui.newSpinBox()
  spin:setStep(5) -- each click changes value by 5 (e.g. volume slider)
end

-- Switch methods

--@api-stub: LSwitch:setOn
-- Sets the on of this switch.
do
  local sw = lurek.ui.newSwitch()
  sw:setOn(true)
end

--@api-stub: LSwitch:isOn
-- Returns true if this switch on.
do
  local sw = lurek.ui.newSwitch()
  local v = sw:isOn()
  print("isOn:", v)
end

--@api-stub: LSwitch:toggle
-- Toggles the  state of this switch.
do
  -- Toggle flips on↔off without knowing current state.
  -- Handy for keybinds: press 'H' to toggle HUD visibility.
  local sw = lurek.ui.newSwitch()
  sw:toggle() -- if off → on, if on → off
end

-- Badge methods

--@api-stub: LBadge:setCount
-- Sets the count of this badge.
do
  local badge = lurek.ui.newBadge(3)
  badge:setCount(4)
end

--@api-stub: LBadge:getCount
-- Returns the total count of items held by this badge.
do
  local badge = lurek.ui.newBadge(3)
  local v = badge:getCount()
  print("getCount:", v)
end

--@api-stub: LBadge:getDisplayText
-- Returns the display text of this badge.
do
  local badge = lurek.ui.newBadge(3)
  local v = badge:getDisplayText()
  print("getDisplayText:", v)
end

-- Panel methods

--@api-stub: LDialog:setTitle
-- Sets the title of this panel.
do
  -- Panels are titled containers — use them for inventory windows,
  -- character sheets, or dialog boxes that need a header bar.
  local panel = lurek.ui.newPanel()
  panel:setTitle("Inventory") -- shown in the panel's header area
end

--@api-stub: LDialog:getTitle
-- Returns the title of this panel.
do
  local panel = lurek.ui.newPanel()
  local v = panel:getTitle()
  print("getTitle:", v)
end

--@api-stub: LPanel:setScrollable
-- Sets the scrollable of this panel.
do
  -- Enable scrolling when panel content exceeds visible area.
  -- Essential for long inventory lists or quest logs.
  local panel = lurek.ui.newPanel()
  panel:setScrollable(true) -- allow vertical scrolling
end

-- Layout methods

--@api-stub: LLayout:setDirection
-- Sets the direction of this layout.
do
  -- Direction controls child stacking: "vertical" for menus/lists,
  -- "horizontal" for toolbars, hotbars, or side-by-side stat columns.
  local layout = lurek.ui.newLayout("vertical")
  layout:setDirection("horizontal") -- switch to toolbar-style row
end

--@api-stub: LLayout:getDirection
-- Returns the direction of this layout.
do
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getDirection()
  print("getDirection:", v)
end

--@api-stub: LLayout:setSpacing
-- Sets the spacing of this layout.
do
  -- Spacing is the gap (in pixels) between each child widget.
  -- Use 4-8 for tight lists, 16+ for breathing room in menus.
  local layout = lurek.ui.newLayout("vertical")
  layout:setSpacing(8) -- 8px gap between each menu button
end

--@api-stub: LLayout:getSpacing
-- Returns the spacing of this layout.
do
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getSpacing()
  print("getSpacing:", v)
end

--@api-stub: LLayout:setColumns
-- Sets the columns of this layout.
do
  -- Columns turn a layout into a grid. Use 4-6 columns for
  -- inventory grids, 3 for card hands, 2 for side-by-side stats.
  local layout = lurek.ui.newLayout("vertical")
  layout:setColumns(4) -- 4-column inventory grid
end

--@api-stub: LLayout:setWrap
-- Sets the wrap of this layout.
do
  -- Wrap moves overflow children to the next row/column,
  -- like CSS flex-wrap. Great for dynamic-count item grids.
  local layout = lurek.ui.newLayout("vertical")
  layout:setWrap(true) -- items flow to next row when row is full
end

--@api-stub: LLayout:getWrap
-- Returns the wrap of this layout.
do
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getWrap()
  print("getWrap:", v)
end

--@api-stub: LLayout:setAlign
-- Sets the align of this layout.
do
  -- Align controls cross-axis placement: "center" for centered
  -- menu buttons, "start"/"end" for left/right-anchored elements.
  local layout = lurek.ui.newLayout("vertical")
  layout:setAlign("center") -- center children horizontally
end

--@api-stub: LLayout:getAlign
-- Returns the align of this layout.
do
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getAlign()
  print("getAlign:", v)
end

--@api-stub: LLayout:setJustify
-- Sets the justify of this layout.
do
  -- Justify distributes children along the main axis:
  -- "start", "center", "end", "space-between", "space-around".
  local layout = lurek.ui.newLayout("vertical")
  layout:setJustify("space-between") -- spread items evenly
end

--@api-stub: LLayout:getJustify
-- Returns the justify of this layout.
do
  local layout = lurek.ui.newLayout("vertical")
  local v = layout:getJustify()
  print("getJustify:", v)
end

-- Scroll_Panel methods

--@api-stub: LScrollBar:setContentSize
-- Sets the content size of this scroll_panel.
do
  -- Content size defines the virtual scrollable area.
  -- Set it larger than the panel's visible rect to enable scrolling.
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(800, 2000) -- tall virtual area for a quest log
end

--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this scroll_panel.
do
  local sp = lurek.ui.newScrollPanel()
  local v = sp:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position of this scroll_panel.
do
  -- Programmatic scroll — jump to a specific entry, e.g.
  -- auto-scroll chat to the newest message at the bottom.
  local sp = lurek.ui.newScrollPanel()
  sp:setScrollPosition(0, 200) -- scroll down 200px
end

--@api-stub: LScrollBar:getScrollPosition
-- Returns the scroll position of this scroll_panel.
do
  local sp = lurek.ui.newScrollPanel()
  local v = sp:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: LScrollPanel:getMaxScroll
-- Returns the max scroll of this scroll_panel.
do
  local sp = lurek.ui.newScrollPanel()
  local v = sp:getMaxScroll()
  print("getMaxScroll:", v)
end

--@api-stub: LScrollPanel:setScrollSpeed
-- Sets the scroll speed of this scroll_panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setScrollSpeed(1)
end

--@api-stub: LScrollPanel:getScrollSpeed
-- Returns the scroll speed of this scroll_panel.
do
  local sp = lurek.ui.newScrollPanel()
  local v = sp:getScrollSpeed()
  print("getScrollSpeed:", v)
end

-- Nine_Patch methods

--@api-stub: LNinePatch:setInsets
-- Sets the insets of this nine_patch.
do
  -- Insets define the non-stretchable border regions of a 9-patch.
  -- The center stretches to fill; corners and edges stay fixed-size.
  local np = lurek.ui.newNinePatch()
  np:setInsets(8, 8, 8, 8) -- 8px fixed border on all sides
end

--@api-stub: LNinePatch:getInsets
-- Returns the insets of this nine_patch.
do
  local np = lurek.ui.newNinePatch()
  local v = np:getInsets()
  print("getInsets:", v)
end

--@api-stub: LNinePatch:setImageDimensions
-- Sets the image dimensions of this nine_patch.
do
  local np = lurek.ui.newNinePatch()
  np:setImageDimensions(64, 64)
end

--@api-stub: LNinePatch:getImageDimensions
-- Returns the image dimensions of this nine_patch.
do
  local np = lurek.ui.newNinePatch()
  local v = np:getImageDimensions()
  print("getImageDimensions:", v)
end

--@api-stub: LNinePatch:getSlices
-- Returns the slices of this nine_patch.
do
  local np = lurek.ui.newNinePatch()
  local v = np:getSlices()
  print("getSlices:", v)
end

-- Toast methods

--@api-stub: LToast:setMessage
-- Sets the message of this toast.
do
  local toast = lurek.ui.newToast("Saved.", 2.0)
  toast:setMessage("Level Up!")
end

--@api-stub: LToast:getMessage
-- Returns the message of this toast.
do
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getMessage()
  print("getMessage:", v)
end

--@api-stub: LToast:setDuration
-- Sets the duration of this toast.
do
  -- Duration is how long (seconds) the toast stays visible.
  -- Short (1s) for quick confirmations, longer (4s) for warnings.
  local toast = lurek.ui.newToast("Saved.", 2.0)
  toast:setDuration(3.0) -- show for 3 seconds before fading
end

--@api-stub: LToast:getDuration
-- Returns the duration of this toast.
do
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getDuration()
  print("getDuration:", v)
end

--@api-stub: LToast:getProgress
-- Returns the progress of this toast.
do
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:getProgress()
  print("getProgress:", v)
end

--@api-stub: LToast:isExpired
-- Returns true if this toast expired.
do
  local toast = lurek.ui.newToast("Saved.", 2.0)
  local v = toast:isExpired()
  print("isExpired:", v)
end

-- Separator methods

--@api-stub: LSeparator:setVertical
-- Sets the vertical of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  sep:setVertical(true)
end

--@api-stub: LScrollBar:isVertical
-- Returns true if this separator vertical.
do
  local sep = lurek.ui.newSeparator(false)
  local v = sep:isVertical()
  print("isVertical:", v)
end

--@api-stub: LSeparator:setThickness
-- Sets the thickness of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  sep:setThickness(1)
end

--@api-stub: LSeparator:getThickness
-- Returns the thickness of this separator.
do
  local sep = lurek.ui.newSeparator(false)
  local v = sep:getThickness()
  print("getThickness:", v)
end

-- Tree_View methods

--@api-stub: LTreeView:addNode
-- Adds a node to this tree_view.
do
  -- TreeViews display hierarchical data: skill trees, file browsers,
  -- tech-tree unlocks, or nested quest objectives.
  local tree = lurek.ui.newTreeView()
  tree:addNode("Swordsmanship") -- add a child node to the root
end

--@api-stub: LTreeView:toggleNode
-- Toggles the node state of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Root"); tree:toggleNode(1)
end

--@api-stub: LTreeView:isExpanded
-- Returns true if this tree_view expanded.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Root"); local v = tree:isExpanded(1)
  print("isExpanded:", v)
end

--@api-stub: LTreeView:getNodeCount
-- Returns the number of node items in this tree_view.
do
  local tree = lurek.ui.newTreeView()
  local v = tree:getNodeCount()
  print("getNodeCount:", v)
end

--@api-stub: LTreeView:removeNode
-- Removes a node from this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:removeNode(1)
end

--@api-stub: LTreeView:clearNodes
-- Clears all nodes items from this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:clearNodes()
end

--@api-stub: LTreeView:getNodeText
-- Returns the node text of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Skill"); local v = tree:getNodeText(1)
  print("getNodeText:", v)
end

--@api-stub: LTreeView:setNodeText
-- Sets the node text of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); tree:setNodeText(1, "Hello")
end

--@api-stub: LTreeView:setNodeIcon
-- Sets the node icon of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); tree:setNodeIcon(1, "assets/icon.png")
end

--@api-stub: LTreeView:expandNode
-- Expands this tree_view to show its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); tree:expandNode(1)
end

--@api-stub: LTreeView:collapseNode
-- Collapses this tree_view to hide its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); tree:collapseNode(1)
end

--@api-stub: LTreeView:isNodeExpanded
-- Returns true if this tree_view node expanded.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); local v = tree:isNodeExpanded(1)
  print("isNodeExpanded:", v)
end

--@api-stub: LTreeView:expandAll
-- Expands this tree_view to show its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:expandAll()
end

--@api-stub: LTreeView:collapseAll
-- Collapses this tree_view to hide its children or content.
do
  local tree = lurek.ui.newTreeView()
  tree:collapseAll()
end

--@api-stub: LTreeView:setSelectedNode
-- Sets the selected node of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); tree:setSelectedNode(1)
end

--@api-stub: LTreeView:getSelectedNode
-- Returns the selected node of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  local v = tree:getSelectedNode()
  print("getSelectedNode:", v)
end

--@api-stub: LTreeView:getChildNodes
-- Returns the child nodes of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Parent"); tree:addNode("Child"); local v = tree:getChildNodes(1)
  print("getChildNodes:", v)
end

--@api-stub: LTreeView:getParentNode
-- Returns the parent node of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Parent"); tree:addNode("Child"); local v = tree:getParentNode(2)
  print("getParentNode:", v)
end

--@api-stub: LTreeView:getNodeDepth
-- Returns the node depth of this tree_view.
do
  local tree = lurek.ui.newTreeView()
  tree:addNode("Node"); local v = tree:getNodeDepth(1)
  print("getNodeDepth:", v)
end

-- Radio_Button methods

--@api-stub: LTooltipPanel:getText
-- Returns the text of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  local v = rb:getText()
  print("getText:", v)
end

--@api-stub: LTooltipPanel:setText
-- Sets the text of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  rb:setText("Hello")
end

--@api-stub: LRadioButton:isSelected
-- Returns true if this radio_button selected.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  local v = rb:isSelected()
  print("isSelected:", v)
end

--@api-stub: LRadioButton:setSelected
-- Sets the selected of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  rb:setSelected(true)
end

--@api-stub: LRadioButton:getGroup
-- Returns the group of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  local v = rb:getGroup()
  print("getGroup:", v)
end

--@api-stub: LRadioButton:setGroup
-- Sets the group of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  rb:setGroup("group1")
end

--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this radio_button.
do
  local rb = lurek.ui.newRadioButton("Easy", "diff")
  rb:setOnChange(function() print("event") end)
end

-- Scroll_Bar methods

--@api-stub: LScrollBar:getScrollPosition
-- Returns the scroll position of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  local v = sb:getScrollPosition()
  print("getScrollPosition:", v)
end

--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  sb:setScrollPosition(100)
end

--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  local v = sb:getContentSize()
  print("getContentSize:", v)
end

--@api-stub: LScrollBar:setContentSize
-- Sets the content size of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  sb:setContentSize(200)
end

--@api-stub: LScrollBar:getViewSize
-- Returns the view size of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  local v = sb:getViewSize()
  print("getViewSize:", v)
end

--@api-stub: LScrollBar:setViewSize
-- Sets the view size of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  sb:setViewSize(200)
end

--@api-stub: LScrollBar:isVertical
-- Returns true if this scroll_bar vertical.
do
  local sb = lurek.ui.newScrollBar(true)
  local v = sb:isVertical()
  print("isVertical:", v)
end

--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this scroll_bar.
do
  local sb = lurek.ui.newScrollBar(true)
  sb:setOnChange(function() print("event") end)
end

-- Gui_Window methods

--@api-stub: LDialog:getTitle
-- Returns the title of this gui_window.
do
  local w = lurek.ui.newPanel()
  local v = w:getTitle()
  print("getTitle:", v)
end

--@api-stub: LDialog:setTitle
-- Sets the title of this gui_window.
do
  local w = lurek.ui.newWindow()
  w:setTitle("Hello")
end

--@api-stub: LGuiWindow:isCloseable
-- Returns true if this gui_window closeable.
do
  local w = lurek.ui.newWindow()
  local v = w:isCloseable()
  print("isCloseable:", v)
end

--@api-stub: LGuiWindow:setCloseable
-- Sets the closeable of this gui_window.
do
  local w = lurek.ui.newWindow()
  w:setCloseable(true)
end

--@api-stub: LGuiWindow:isDraggable
-- Returns true if this gui_window draggable.
do
  local w = lurek.ui.newWindow()
  local v = w:isDraggable()
  print("isDraggable:", v)
end

--@api-stub: LGuiWindow:setDraggable
-- Sets the draggable of this gui_window.
do
  local w = lurek.ui.newWindow()
  w:setDraggable(true)
end

--@api-stub: LGuiWindow:isResizable
-- Returns true if this gui_window resizable.
do
  local w = lurek.ui.newWindow()
  local v = w:isResizable()
  print("isResizable:", v)
end

--@api-stub: LGuiWindow:setResizable
-- Sets the resizable of this gui_window.
do
  local w = lurek.ui.newWindow()
  w:setResizable(true)
end

--@api-stub: LDialog:setOnClose
-- Sets the on close of this gui_window.
do
  local w = lurek.ui.newWindow()
  w:setOnClose(function() print("event") end)
end

-- Split_Panel methods

--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  local v = split:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: LToolbar:setOrientation
-- Sets the orientation of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  split:setOrientation("horizontal")
end

--@api-stub: LSplitPanel:getSplitPosition
-- Returns the split position of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  local v = split:getSplitPosition()
  print("getSplitPosition:", v)
end

--@api-stub: LSplitPanel:setSplitPosition
-- Sets the split position of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  split:setSplitPosition(0.5)
end

--@api-stub: LSplitPanel:getMinPanelSize
-- Returns the min panel size of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  local v = split:getMinPanelSize()
  print("getMinPanelSize:", v)
end

--@api-stub: LSplitPanel:setMinPanelSize
-- Sets the min panel size of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  split:setMinPanelSize(50)
end

--@api-stub: LSplitPanel:setFirstChild
-- Sets the first child of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  split:setFirstChild(1)
end

--@api-stub: LSplitPanel:setSecondChild
-- Sets the second child of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  split:setSecondChild(1)
end

--@api-stub: LSplitPanel:getFirstChild
-- Returns the first child of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  local v = split:getFirstChild()
  print("getFirstChild:", v)
end

--@api-stub: LSplitPanel:getSecondChild
-- Returns the second child of this split_panel.
do
  local split = lurek.ui.newSplitPanel("horizontal")
  local v = split:getSecondChild()
  print("getSecondChild:", v)
end

-- Dock_Panel methods

--@api-stub: LDockPanel:dock
-- Docks a child widget into this dock_panel panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:dock(1, "left")
end

--@api-stub: LDockPanel:undock
-- Undocks a previously docked widget from this dock_panel panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:undock(1)
end

--@api-stub: LDockPanel:getDockedCount
-- Returns the number of docked items in this dock_panel.
do
  local dock = lurek.ui.newDockPanel()
  local v = dock:getDockedCount()
  print("getDockedCount:", v)
end

--@api-stub: LDockPanel:setSplitSize
-- Sets the split size of this dock_panel.
do
  local dock = lurek.ui.newDockPanel()
  dock:setSplitSize("left", 200)
end

--@api-stub: LDockPanel:getSplitSize
-- Returns the split size of this dock_panel.
do
  local dock = lurek.ui.newDockPanel()
  local v = dock:getSplitSize("left")
  print("getSplitSize:", v)
end

-- Toolbar methods

--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this toolbar.
do
  local tb = lurek.ui.newToolbar()
  local v = tb:getOrientation()
  print("getOrientation:", v)
end

--@api-stub: LToolbar:setOrientation
-- Sets the orientation of this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:setOrientation("horizontal")
end

--@api-stub: LDialog:addButton
-- Adds a button to this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("file")
end

--@api-stub: LToolbar:addSeparator
-- Adds a separator to this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:addSeparator()
end

--@api-stub: LToolbar:addSpacer
-- Adds a spacer to this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:addSpacer(1)
end

--@api-stub: LToolbar:getButton
-- Returns the button of this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("file"); local v = tb:getButton("file")
  print("getButton:", v)
end

--@api-stub: LToolbar:setButtonEnabled
-- Sets whether this toolbar is enabled and accepts input.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("file"); tb:setButtonEnabled("file", true)
end

--@api-stub: LToolbar:setButtonToggled
-- Sets the button toggled of this toolbar.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("file"); tb:setButtonToggled("file", true)
end

--@api-stub: LToolbar:isButtonToggled
-- Returns true if this toolbar button toggled.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("file"); local v = tb:isButtonToggled("file")
  print("isButtonToggled:", v)
end

-- Menu_Bar methods

--@api-stub: LMenuBar:addMenu
-- Adds a menu to this menu_bar.
do
  local mb = lurek.ui.newMenuBar()
  local child = lurek.ui.newButton("Child")
  mb:addMenu(1)
end

--@api-stub: LMenuBar:removeMenu
-- Removes a menu from this menu_bar.
do
  local mb = lurek.ui.newMenuBar()
  mb:removeMenu(1)
end

--@api-stub: LMenuBar:getMenus
-- Returns the menus of this menu_bar.
do
  local mb = lurek.ui.newMenuBar()
  local v = mb:getMenus()
  print("getMenus:", v)
end

--@api-stub: LMenuBar:getMenuCount
-- Returns the number of menu items in this menu_bar.
do
  local mb = lurek.ui.newMenuBar()
  local v = mb:getMenuCount()
  print("getMenuCount:", v)
end

-- Menu_Item methods

--@api-stub: LTooltipPanel:getText
-- Returns the text of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getText()
  print("getText:", v)
end

--@api-stub: LTooltipPanel:setText
-- Sets the text of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setText("Hello")
end

--@api-stub: LMenuItem:getShortcut
-- Returns the shortcut of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getShortcut()
  print("getShortcut:", v)
end

--@api-stub: LMenuItem:setShortcut
-- Sets the shortcut of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setShortcut("Ctrl+S")
end

--@api-stub: LMenuItem:isChecked
-- Returns true if this menu_item checked.
do
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:isChecked()
  print("isChecked:", v)
end

--@api-stub: LMenuItem:setChecked
-- Sets the checked of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setChecked(true)
end

--@api-stub: LMenuItem:addSubItem
-- Adds a sub item to this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  mi:addSubItem(1)
end

--@api-stub: LMenuItem:getSubItems
-- Returns the sub items of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  local v = mi:getSubItems()
  print("getSubItems:", v)
end

--@api-stub: LMenuItem:setOnClick
-- Sets the on click of this menu_item.
do
  local mi = lurek.ui.newMenuItem("New Game")
  mi:setOnClick(function() print("event") end)
end

-- Dialog methods

--@api-stub: LDialog:getTitle
-- Returns the title of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  local v = dlg:getTitle()
  print("getTitle:", v)
end

--@api-stub: LDialog:setTitle
-- Sets the title of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:setTitle("Hello")
end

--@api-stub: LDialog:isModal
-- Returns true if this dialog modal.
do
  local dlg = lurek.ui.newDialog("Quit?")
  local v = dlg:isModal()
  print("isModal:", v)
end

--@api-stub: LDialog:setModal
-- Sets the modal of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:setModal(true)
end

--@api-stub: LDialog:isOpen
-- Returns true if this dialog open.
do
  local dlg = lurek.ui.newDialog("Quit?")
  local v = dlg:isOpen()
  print("isOpen:", v)
end

--@api-stub: LDialog:open
-- Performs the open operation on this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:open()
end

--@api-stub: LDialog:close
-- Performs the close operation on this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:close()
end

--@api-stub: LDialog:setOnClose
-- Sets the on close of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:setOnClose(function() print("event") end)
end

--@api-stub: LDialog:setContent
-- Sets the content of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:setContent(1)
end

--@api-stub: LDialog:getContent
-- Returns the content of this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  local v = dlg:getContent()
  print("getContent:", v)
end

--@api-stub: LDialog:addButton
-- Adds a button to this dialog.
do
  local dlg = lurek.ui.newDialog("Quit?")
  dlg:addButton("OK")
end

-- Status_Bar methods

--@api-stub: LAccordion:addSection
-- Adds a section to this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("Ready")
end

--@api-stub: LStatusBar:setSectionText
-- Sets the section text of this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("Ready"); sb:setSectionText(1, "Hello")
end

--@api-stub: LStatusBar:getSectionText
-- Returns the section text of this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("Ready"); local v = sb:getSectionText(1)
  print("getSectionText:", v)
end

--@api-stub: LAccordion:getSectionCount
-- Returns the number of section items in this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  local v = sb:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: LStatusBar:setSectionCount
-- Sets the section count of this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:setSectionCount(4)
end

--@api-stub: LStatusBar:setSectionWidget
-- Sets the section widget of this status_bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("Ready"); sb:setSectionWidget(1, nil)
end

-- Accordion methods

--@api-stub: LAccordion:addSection
-- Adds a section to this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:addSection("Stats")
end

--@api-stub: LAccordion:getSectionCount
-- Returns the number of section items in this accordion.
do
  local acc = lurek.ui.newAccordion()
  local v = acc:getSectionCount()
  print("getSectionCount:", v)
end

--@api-stub: LAccordion:toggleSection
-- Toggles the section state of this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:addSection("Stats"); acc:toggleSection(1)
end

--@api-stub: LAccordion:isSectionExpanded
-- Returns true if this accordion section expanded.
do
  local acc = lurek.ui.newAccordion()
  acc:addSection("Stats"); local v = acc:isSectionExpanded(1)
  print("isSectionExpanded:", v)
end

--@api-stub: LAccordion:isExclusive
-- Returns true if this accordion exclusive.
do
  local acc = lurek.ui.newAccordion()
  local v = acc:isExclusive()
  print("isExclusive:", v)
end

--@api-stub: LAccordion:setExclusive
-- Sets the exclusive of this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:setExclusive(true)
end

--@api-stub: LAccordion:getSectionTitle
-- Returns the section title of this accordion.
do
  local acc = lurek.ui.newAccordion()
  acc:addSection("Stats"); local v = acc:getSectionTitle(1)
  print("getSectionTitle:", v)
end

-- Tooltip_Panel methods

--@api-stub: LTooltipPanel:getText
-- Returns the text of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getText()
  print("getText:", v)
end

--@api-stub: LTooltipPanel:setText
-- Sets the text of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setText("Hello")
end

--@api-stub: LTooltipPanel:getDelay
-- Returns the delay of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getDelay()
  print("getDelay:", v)
end

--@api-stub: LTooltipPanel:setDelay
-- Sets the delay of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setDelay(2.0)
end

--@api-stub: LTooltipPanel:getTarget
-- Returns the target of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  local v = tip:getTarget()
  print("getTarget:", v)
end

--@api-stub: LTooltipPanel:setTarget
-- Sets the target of this tooltip_panel.
do
  local tip = lurek.ui.newTooltipPanel("Click to attack")
  tip:setTarget(1)
end

-- Color_Picker methods

--@api-stub: LColorPicker:getColor
-- Returns the color of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  local v = cp:getColor()
  print("getColor:", v)
end

--@api-stub: LColorPicker:setColor
-- Sets the color of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setColor(0.2, 0.6, 1.0, 1.0)
end

--@api-stub: LColorPicker:getShowAlpha
-- Returns the show alpha of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  local v = cp:getShowAlpha()
  print("getShowAlpha:", v)
end

--@api-stub: LColorPicker:setShowAlpha
-- Sets the show alpha of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setShowAlpha(true)
end

--@api-stub: LColorPicker:getColorMode
-- Returns the color mode of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  local v = cp:getColorMode()
  print("getColorMode:", v)
end

--@api-stub: LColorPicker:setColorMode
-- Sets the color mode of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setColorMode("rgb")
end

--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this color_picker.
do
  local cp = lurek.ui.newColorPicker()
  cp:setOnChange(function() print("event") end)
end

-- Gui_Table methods

--@api-stub: LGuiTable:addColumn
-- Adds a column to this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:addColumn("item_1")
end

--@api-stub: LGuiTable:getColumnCount
-- Returns the number of column items in this gui_table.
do
  local tbl = lurek.ui.newTable()
  local v = tbl:getColumnCount()
  print("getColumnCount:", v)
end

--@api-stub: LGuiTable:addRow
-- Adds a row to this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:addRow({"item_1"})
end

--@api-stub: LGuiTable:getRowCount
-- Returns the number of row items in this gui_table.
do
  local tbl = lurek.ui.newTable()
  local v = tbl:getRowCount()
  print("getRowCount:", v)
end

--@api-stub: LGuiTable:getCell
-- Returns the cell of this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:addColumn("Name"); tbl:addRow({"Alice"}); local v = tbl:getCell(1, 1)
  print("getCell:", v)
end

--@api-stub: LGuiTable:setCell
-- Sets the cell of this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:addColumn("Name"); tbl:addRow({"Alice"}); tbl:setCell(1, 1, "Bob")
end

--@api-stub: LGuiTable:getSelectedRow
-- Returns the selected row of this gui_table.
do
  local tbl = lurek.ui.newTable()
  local v = tbl:getSelectedRow()
  print("getSelectedRow:", v)
end

--@api-stub: LGuiTable:setSelectedRow
-- Sets the selected row of this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:setSelectedRow(1)
end

--@api-stub: LGuiTable:isSortable
-- Returns true if this gui_table sortable.
do
  local tbl = lurek.ui.newTable()
  local v = tbl:isSortable()
  print("isSortable:", v)
end

--@api-stub: LGuiTable:setSortable
-- Sets the sortable of this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:setSortable(true)
end

--@api-stub: LGuiTable:setOnSelect
-- Sets the on select of this gui_table.
do
  local tbl = lurek.ui.newTable()
  tbl:setOnSelect(function() print("event") end)
end

-- Image_Widget methods

--@api-stub: LImageWidget:getScaleMode
-- Returns the scale mode of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = img:getScaleMode()
  print("getScaleMode:", v)
end

--@api-stub: LImageWidget:setScaleMode
-- Sets the scale mode of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  img:setScaleMode("fit")
end

--@api-stub: LImageWidget:getTint
-- Returns the tint of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = img:getTint()
  print("getTint:", v)
end

--@api-stub: LImageWidget:setTint
-- Sets the tint of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  img:setTint(0.2, 0.6, 1.0, 1.0)
end

--@api-stub: lurek.ui.newButton
-- Creates and returns a new button widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newButton("Btn")
end

--@api-stub: lurek.ui.newLabel
-- Creates and returns a new label widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newLabel("hello")
end

--@api-stub: lurek.ui.newTextInput
-- Creates and returns a new text input widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTextInput()
end

--@api-stub: lurek.ui.newCheckbox
-- Creates and returns a new checkbox widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newCheckbox("opt")
end

--@api-stub: lurek.ui.newSlider
-- Creates and returns a new slider widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSlider()
end

--@api-stub: lurek.ui.newProgressBar
-- Creates and returns a new progress bar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newProgressBar()
end

--@api-stub: lurek.ui.newComboBox
-- Creates and returns a new combo box widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newComboBox()
end

--@api-stub: lurek.ui.newList
-- Creates and returns a new list widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newList()
end

--@api-stub: lurek.ui.newPanel
-- Creates and returns a new panel widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newPanel()
end

--@api-stub: lurek.ui.newLayout
-- Creates and returns a new layout widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newLayout("row")
end

--@api-stub: lurek.ui.newScrollPanel
-- Creates and returns a new scroll panel widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newScrollPanel()
end

--@api-stub: lurek.ui.newNinePatch
-- Creates and returns a new nine patch widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newNinePatch()
end

--@api-stub: lurek.ui.newTabBar
-- Creates and returns a new tab bar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTabBar()
end

--@api-stub: lurek.ui.newSeparator
-- Creates and returns a new separator widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSeparator()
end

--@api-stub: lurek.ui.newSpacer
-- Creates and returns a new spacer widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSpacer()
end

--@api-stub: lurek.ui.newToast
-- Creates and returns a new toast widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newToast()
end

--@api-stub: lurek.ui.newTreeView
-- Creates and returns a new tree view widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTreeView()
end

--@api-stub: lurek.ui.newRadioButton
-- Creates and returns a new radio button widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newRadioButton("opt")
end

--@api-stub: lurek.ui.newScrollBar
-- Creates and returns a new scroll bar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newScrollBar()
end

--@api-stub: lurek.ui.newWindow
-- Creates and returns a new window widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newWindow()
end

--@api-stub: lurek.ui.newSplitPanel
-- Creates and returns a new split panel widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSplitPanel()
end

--@api-stub: lurek.ui.newDockPanel
-- Creates and returns a new dock panel widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newDockPanel()
end

--@api-stub: lurek.ui.newToolbar
-- Creates and returns a new toolbar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newToolbar()
end

--@api-stub: lurek.ui.newMenuBar
-- Creates and returns a new menu bar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newMenuBar()
end

--@api-stub: lurek.ui.newMenuItem
-- Creates and returns a new menu item widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newMenuItem()
end

--@api-stub: lurek.ui.newDialog
-- Creates and returns a new dialog widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newDialog()
end

--@api-stub: lurek.ui.newStatusBar
-- Creates and returns a new status bar widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newStatusBar()
end

--@api-stub: lurek.ui.newAccordion
-- Creates and returns a new accordion widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newAccordion()
end

--@api-stub: lurek.ui.newTooltipPanel
-- Creates and returns a new tooltip panel widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTooltipPanel()
end

--@api-stub: lurek.ui.newColorPicker
-- Creates and returns a new color picker widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newColorPicker()
end

--@api-stub: lurek.ui.newTable
-- Creates and returns a new table widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTable()
end

--@api-stub: lurek.ui.newImageWidget
-- Creates and returns a new image widget widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newImageWidget()
end

--@api-stub: lurek.ui.newTheme
-- Creates and returns a new theme widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newTheme()
end

--@api-stub: lurek.ui.setTheme
-- Sets the theme of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.setTheme(lurek.ui.newTheme())
end

--@api-stub: lurek.ui.getTheme
-- Returns the theme of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = lurek.ui.getTheme()
  print("getTheme:", v)
end

--@api-stub: lurek.ui.getRoot
-- Returns the root of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = lurek.ui.getRoot()
  print("getRoot:", v)
end

--@api-stub: lurek.ui.setFocus
-- Sets the focus of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.setFocus(nil)
end

--@api-stub: lurek.ui.getFocus
-- Returns the focus of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = lurek.ui.getFocus()
  print("getFocus:", v)
end

--@api-stub: lurek.ui.focusNext
-- Performs the focus next operation on this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.focusNext()
end

--@api-stub: lurek.ui.focusPrev
-- Performs the focus prev operation on this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.focusPrev()
end

--@api-stub: lurek.ui.clearFocus
-- Clears all focus items from this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.clearFocus()
end

--@api-stub: lurek.ui.addToast
-- Adds a toast to this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.addToast({text="Hello"})
end

--@api-stub: lurek.ui.getToastCount
-- Returns the number of toast items in this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = lurek.ui.getToastCount()
  print("getToastCount:", v)
end

--@api-stub: lurek.ui.mousepressed
-- Forwards a mouse press event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.mousepressed(100, 200, 1)
end

--@api-stub: lurek.ui.mousereleased
-- Forwards a mouse release event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.mousereleased(100, 200, 1)
end

--@api-stub: lurek.ui.mousemoved
-- Forwards a mouse move event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.mousemoved(100, 200)
end
--@api-stub: lurek.ui.keypressed
-- Forwards a key press event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.keypressed("space")
end

--@api-stub: lurek.ui.textinput
-- Forwards a text input event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.textinput("a")
end

--@api-stub: lurek.ui.wheelmoved
-- Forwards a mouse wheel event to this image_widget for input handling.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.wheelmoved(0, 1)
end

--@api-stub: lurek.ui.update
-- Advances this image_widget by the given delta time.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.update(0.016)
end

--@api-stub: lurek.ui.draw
-- Draws or renders this image_widget to the current render target.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.draw()
end

--@api-stub: lurek.ui.getWidgetCount
-- Returns the number of widget items in this image_widget.
do
  local img = lurek.ui.newImageWidget()
  local v = lurek.ui.getWidgetCount()
  print("getWidgetCount:", v)
end

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this image_widget to the current render target.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.drawToImage(800, 600)
end

--@api-stub: lurek.ui.newLineChart
-- Creates and returns a new line chart widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newLineChart({})
end

--@api-stub: lurek.ui.newBarChart
-- Creates and returns a new bar chart widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newBarChart({})
end

--@api-stub: lurek.ui.newScatterPlot
-- Creates and returns a new scatter plot widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newScatterPlot({})
end

--@api-stub: lurek.ui.newPieChart
-- Creates and returns a new pie chart widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newPieChart({})
end

--@api-stub: lurek.ui.newAreaChart
-- Creates and returns a new area chart widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newAreaChart({})
end

--@api-stub: lurek.ui.parseWidgetState
-- Performs the parse widget state operation on this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.parseWidgetState("{}")
end

--@api-stub: lurek.ui.newSpinBox
-- Creates and returns a new spin box widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSpinBox()
end

--@api-stub: lurek.ui.newSwitch
-- Creates and returns a new switch widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newSwitch()
end

--@api-stub: lurek.ui.newBadge
-- Creates and returns a new badge widget or object.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.newBadge()
end

--@api-stub: lurek.ui.setDefaultTheme
-- Sets the default theme of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.setDefaultTheme()
end

--@api-stub: lurek.ui.setViewport
-- Sets the viewport of this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.setViewport(800, 600)
end

--@api-stub: lurek.ui.flushCache
-- Performs the flush cache operation on this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.flushCache()
end

--@api-stub: lurek.ui.update_bindings
-- Advances _bindings this image_widget by the given delta time.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.update_bindings({})
end

--@api-stub: lurek.ui.loadLayout
-- Loads layout into this image_widget.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.loadLayout({})
end

--@api-stub: lurek.ui.loadLayoutFile
-- Loads layout file into this image_widget.
do
  local img = lurek.ui.newImageWidget()
  -- loadLayoutFile requires an actual file on disk; verify function exists
  assert(type(lurek.ui.loadLayoutFile) == "function", "loadLayoutFile must be a function")
  lurek.log.info("loadLayoutFile available", "ui")
end

--@api-stub: lurek.ui.renderToImage
-- Draws or renders this image_widget to the current render target.
do
  local img = lurek.ui.newImageWidget()
  lurek.ui.renderToImage(800, 600, "output.png")
end

-- LineChart methods

--@api-stub: LAreaChart:setYMax
-- Sets the y max of this line chart.
do
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:setYMax(100)
end

--@api-stub: LLineChart:setXMax
-- Sets the x max of this line chart.
do
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:setXMax(100)
end

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this line chart to the current render target.
do
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
  chart:drawToImage(lurek.image.newImageData(64, 64))
end

-- BarChart methods

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this bar chart to the current render target.
do
  local w = lurek.ui.newBarChart({})
  w:drawToImage(lurek.image.newImageData(64, 64))
end

-- ScatterPlot methods

--@api-stub: LScatterPlot:setXRange
-- Sets the x range of this scatter plot.
do
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setXRange(1, 10)
end

--@api-stub: LScatterPlot:setYRange
-- Sets the y range of this scatter plot.
do
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:setYRange(1, 10)
end

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this scatter plot to the current render target.
do
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
  plot:drawToImage(lurek.image.newImageData(64, 64))
end

-- PieChart methods

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this pie chart to the current render target.
do
  local chart = lurek.ui.newPieChart({{label="HP",value=70}})
  chart:drawToImage(lurek.image.newImageData(64, 64))
end

-- AreaChart methods

--@api-stub: LAreaChart:setYMax
-- Sets the y max of this area chart.
do
  local w = lurek.ui.newAreaChart({})
  w:setYMax(100)
end

--@api-stub: LAreaChart:drawToImage
-- Draws or renders this area chart to the current render target.
do
  local w = lurek.ui.newBarChart({})
  w:drawToImage(lurek.image.newImageData(64, 64))
end

-- Custom widget extensibility

--@api-stub: lurek.ui.newCustomWidget
-- Creates and returns a new custom widget widget or object.
do
  local widget = lurek.ui.newCustomWidget({
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
-- Adds a category to this bar chart.
do
  lurek.log.info("BarChart:addCategory usage: chart:addCategory('Jan')", "ui")
  local bc = lurek.ui.newBarChart({})
  bc:addCategory("Jan", {100})
  bc:addCategory("Feb", {80})
  lurek.log.info("categories added", "ui")
end

--@api-stub: LAreaChart:addLayer
-- Adds a layer to this area chart.
do
  local ac = lurek.ui.newAreaChart({})
  ac:addLayer("series_a", {10,20,15,30,25}, 1.0, 0.3, 0.3)
  ac:addLayer("series_b", {5,10,8,14,12}, 0.3, 0.6, 1.0)
  lurek.log.info("area layers added", "ui")
end

--@api-stub: LPieChart:addSegment
-- Adds a segment to this pie chart.
do
  local pc = lurek.ui.newPieChart({})
  pc:addSegment("Wheat", 40, 0.9, 0.8, 0.3)
  pc:addSegment("Sheep", 25, 0.8, 0.9, 0.5)
  pc:addSegment("Forest", 35, 0.2, 0.7, 0.3)
  lurek.log.info("pie segments added", "ui")
end

--@api-stub: LScatterPlot:addSeries
-- Adds a series to this line chart.
do
  local lc = lurek.ui.newLineChart({})
  lc:addSeries("revenue", {{1,10},{2,20},{3,15},{4,35},{5,30}}, 0.2, 0.8, 0.4)
  lc:addSeries("cost", {{1,8},{2,12},{3,10},{4,18},{5,20}}, 0.9, 0.3, 0.2)
  lurek.log.info("line series added", "ui")
end

--@api-stub: LScatterPlot:addSeries
-- Adds a series to this bar chart.
do
  local bc = lurek.ui.newBarChart({})
  bc:addCategory("Q1", {120}); bc:addCategory("Q2", {180})
  bc:addSeries("sales", 0.2, 0.6, 0.9)
  bc:addSeries("returns", 0.9, 0.3, 0.2)
  lurek.log.info("bar series added", "ui")
end

--@api-stub: LScatterPlot:addSeries
-- Adds a series to this scatter plot.
do
  local sp = lurek.ui.newScatterPlot({})
  sp:addSeries("players", {{10,20},{30,40},{50,35},{70,55}}, 0.2, 0.7, 1.0)
  sp:setXRange(0, 100); sp:setYRange(0, 80)
  lurek.log.info("scatter series added", "ui")
end

--@api-stub: LTheme:setStyle
-- Sets the style of this theme.
do
  local theme = lurek.ui.newTheme()
  theme:setStyle("button", "normal", {bg = {0.2, 0.4, 0.8, 1}})
  theme:setStyle("button", "hovered", {bg = {0.3, 0.5, 0.9, 1}})
  lurek.log.info("theme styles set", "ui")
end

-- LineChart methods


--@api-stub: LAreaChart:type
-- Returns the Lua-visible type name string for this line chart handle.
do
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  local t = chart:type()
  lurek.log.info("LineChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Returns true if this line chart handle matches the given type name string.
do
  local chart = lurek.ui.newLineChart({0.1,0.3,0.5,0.7})
    chart:setYMax(100)
  lurek.log.info("is LineChart: " .. tostring(chart:typeOf("LineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end


-- LAreaChart methods


--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local w = lurek.ui.newAreaChart({})
  w:setYMax(100)
  local t = w:type()
  lurek.log.info("LAreaChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local w = lurek.ui.newAreaChart({})
  w:setYMax(100)
  lurek.log.info("is LAreaChart: " .. tostring(w:typeOf("LAreaChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local w = lurek.ui.newBarChart({})
  w:drawToImage(lurek.image.newImageData(64, 64))
  local t = w:type()
  lurek.log.info("LBarChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local w = lurek.ui.newBarChart({})
  w:drawToImage(lurek.image.newImageData(64, 64))
  lurek.log.info("is LBarChart: " .. tostring(w:typeOf("LBarChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(w:typeOf("Unknown")), "ui")
end
--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Sales" })
  local t = chart:type()
  lurek.log.info("LLineChart:type=" .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local chart = lurek.ui.newLineChart({ width = 400, height = 300, title = "Revenue" })
  lurek.log.info("is LLineChart: " .. tostring(chart:typeOf("LLineChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local chart = lurek.ui.newPieChart({{label="HP",value=70}})
    chart:drawToImage(lurek.image.newImageData(64, 64))
  local t = chart:type()
  lurek.log.info("LPieChart:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local chart = lurek.ui.newPieChart({{label="HP",value=70}})
    chart:drawToImage(lurek.image.newImageData(64, 64))
  lurek.log.info("is LPieChart: " .. tostring(chart:typeOf("LPieChart")), "ui")
  lurek.log.info("is wrong: " .. tostring(chart:typeOf("Unknown")), "ui")
end
--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1, 10)
  local t = plot:type()
  lurek.log.info("LScatterPlot:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local plot = lurek.ui.newScatterPlot({{1,2},{3,4},{5,6}})
    plot:setXRange(1, 10)
  lurek.log.info("is LScatterPlot: " .. tostring(plot:typeOf("LScatterPlot")), "ui")
  lurek.log.info("is wrong: " .. tostring(plot:typeOf("Unknown")), "ui")
end
--@api-stub: LAreaChart:type
-- Returns the type name of this object
do
  local theme = lurek.ui.newTheme()
  theme:setStyle("button", "normal", {bg = {0.2, 0.4, 0.8, 1}})
  theme:setStyle("button", "hovered", {bg = {0.3, 0.5, 0.9, 1}})
  local t = theme:type()
  lurek.log.info("LTheme:type = " .. t, "ui")
end
--@api-stub: LAreaChart:typeOf
-- Checks whether this object matches the given type name
do
  local theme = lurek.ui.newTheme()
  theme:setStyle("button", "normal", {bg = {0.2, 0.4, 0.8, 1}})
  theme:setStyle("label", "normal", {fg = {1, 1, 1, 1}})
  lurek.log.info("is LTheme: " .. tostring(theme:typeOf("LTheme")), "ui")
  lurek.log.info("is wrong: " .. tostring(theme:typeOf("Unknown")), "ui")
end

--@api-stub: LAreaChart:type
-- Returns the Lua-visible type name string for this ui handle.
do
  local chart = lurek.ui.newLineChart({ width = 200, height = 150, title = "FPS" })
  local t = chart:type()
  lurek.log.info("ui.type=" .. tostring(t), "ui")
end
--@api-stub: LAreaChart:setYMax
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
--@api-stub: LAreaChart:drawToImage
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


--@api-stub: LAreaChart:drawToImage
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
  acc:setExclusive(true)
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


--@api-stub: LTooltipPanel:setText
-- Sets the text of this button.
do
  local btn = lurek.ui.newButton("Click")
  btn:setText("Hello, world!")
  lurek.log.info("LButton:setText applied", "ui")
end


--@api-stub: LTooltipPanel:getText
-- Returns the text of this button.
do
  local btn = lurek.ui.newButton("Click")
  local val = btn:getText()
  lurek.log.info("LButton:getText=" .. tostring(val), "ui")
end


-- LCheckbox methods


--@api-stub: LMenuItem:setChecked
-- Sets the checked of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Option")
  cb:setChecked(true)
  lurek.log.info("LCheckbox:setChecked applied", "ui")
end


--@api-stub: LMenuItem:isChecked
-- Returns true if this checkbox checked.
do
  local cb = lurek.ui.newCheckbox("Option")
  local val = cb:isChecked()
  lurek.log.info("LCheckbox:isChecked=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setText
-- Sets the text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Option")
  cb:setText("Hello, world!")
  lurek.log.info("LCheckbox:setText applied", "ui")
end


--@api-stub: LTooltipPanel:getText
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
  cp:setShowAlpha(true)
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


--@api-stub: LListBox:addItem
-- Adds a item to this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:addItem("Hello, world!")
  lurek.log.info("LComboBox:addItem done", "ui")
end


--@api-stub: LListBox:removeItem
-- Removes a item from this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:removeItem(1)
  lurek.log.info("LComboBox:removeItem done", "ui")
end


--@api-stub: LListBox:clearItems
-- Clears all items items from this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:clearItems()
  lurek.log.info("LComboBox:clearItems done", "ui")
end


--@api-stub: LListBox:getItemCount
-- Returns the number of item items in this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getItemCount()
  lurek.log.info("LComboBox:getItemCount=" .. tostring(val), "ui")
end


--@api-stub: LListBox:getItem
-- Returns the item of this combo box.
do
  local combo = lurek.ui.newComboBox()
  local val = combo:getItem(1)
  lurek.log.info("LComboBox:getItem=" .. tostring(val), "ui")
end


--@api-stub: LListBox:setSelectedIndex
-- Sets the selected index of this combo box.
do
  local combo = lurek.ui.newComboBox()
  combo:setSelectedIndex(1)
  lurek.log.info("LComboBox:setSelectedIndex applied", "ui")
end


--@api-stub: LListBox:getSelectedIndex
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
  dlg:setModal(true)
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
  tbl:setSortable(true)
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


--@api-stub: LDialog:getTitle
-- Returns the title of this gui window.
do
  local win = lurek.ui.newWindow("Title")
  local val = win:getTitle()
  lurek.log.info("LGuiWindow:getTitle=" .. tostring(val), "ui")
end


--@api-stub: LDialog:setTitle
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
  win:setCloseable(true)
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
  win:setDraggable(true)
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
  win:setResizable(true)
  lurek.log.info("LGuiWindow:setResizable applied", "ui")
end


--@api-stub: LDialog:setOnClose
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


--@api-stub: LTooltipPanel:setText
-- Sets the text of this abel.
do
  local lbl = lurek.ui.newLabel("Text")
  lbl:setText("Hello, world!")
  lurek.log.info("LLabel:setText applied", "ui")
end


--@api-stub: LTooltipPanel:getText
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


--@api-stub: LScatterPlot:addSeries
-- Adds a named series of points to this line chart
do
  local chart = lurek.ui.newLineChart({ width = 300, height = 200, title = "Data" })
  chart:addSeries("hero", {{1,10},{2,20},{3,30}}, 1.0, 0.8, 0.2)
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


--@api-stub: LTooltipPanel:getText
-- Returns the text of this menu item.
do
  local mi = lurek.ui.newMenuItem("File")
  local val = mi:getText()
  lurek.log.info("LMenuItem:getText=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setText
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
  mi:setChecked(true)
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


--@api-stub: LDialog:setTitle
-- Sets the title of this panel.
do
  local panel = lurek.ui.newPanel()
  panel:setTitle("Section")
  lurek.log.info("LPanel:setTitle applied", "ui")
end


--@api-stub: LDialog:getTitle
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


--@api-stub: LSpinBox:setValue
-- Sets the value of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  bar:setValue(1.0)
  lurek.log.info("LProgressBar:setValue applied", "ui")
end


--@api-stub: LSpinBox:getValue
-- Returns the value of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getValue()
  lurek.log.info("LProgressBar:getValue=" .. tostring(val), "ui")
end


--@api-stub: LToast:getProgress
-- Returns the progress of this progress bar.
do
  local bar = lurek.ui.newProgressBar(0, 100)
  local val = bar:getProgress()
  lurek.log.info("LProgressBar:getProgress=" .. tostring(val), "ui")
end


--@api-stub: LSpinBox:setRange
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


--@api-stub: LTooltipPanel:getText
-- Returns the text of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option", "group1")
  local val = rb:getText()
  lurek.log.info("LRadioButton:getText=" .. tostring(val), "ui")
end


--@api-stub: LTooltipPanel:setText
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
  rb:setSelected(true)
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


--@api-stub: LColorPicker:setOnChange
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


--@api-stub: LColorPicker:setOnChange
-- Sets the on change of this scroll bar.
do
  local scrollbar = lurek.ui.newScrollBar(true)
  scrollbar:setOnChange(function() end)
  lurek.log.info("LScrollBar:setOnChange callback set", "ui")
end


-- LScrollPanel methods


--@api-stub: LScrollBar:setContentSize
-- Sets the content size of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(64.0, 64.0)
  lurek.log.info("LScrollPanel:setContentSize applied", "ui")
end


--@api-stub: LScrollBar:getContentSize
-- Returns the content size of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  local val = sp:getContentSize()
  lurek.log.info("LScrollPanel:getContentSize=" .. tostring(val), "ui")
end


--@api-stub: LScrollBar:setScrollPosition
-- Sets the scroll position of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setScrollPosition(0.0, 0.0)
  lurek.log.info("LScrollPanel:setScrollPosition applied", "ui")
end


--@api-stub: LScrollBar:getScrollPosition
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
  sep:setVertical(true)
  lurek.log.info("LSeparator:setVertical applied", "ui")
end


--@api-stub: LScrollBar:isVertical
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


--@api-stub: LSpinBox:setValue
-- Sets the value of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setValue(1.0)
  lurek.log.info("LSlider:setValue applied", "ui")
end


--@api-stub: LSpinBox:getValue
-- Returns the value of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  local val = slider:getValue()
  lurek.log.info("LSlider:getValue=" .. tostring(val), "ui")
end


--@api-stub: LSpinBox:setRange
-- Sets the range of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setRange(0.0, 0.0)
  lurek.log.info("LSlider:setRange applied", "ui")
end


--@api-stub: LSpinBox:setStep
-- Sets the step of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  slider:setStep(0.0)
  lurek.log.info("LSlider:setStep applied", "ui")
end


--@api-stub: LProgressBar:getMin
-- Returns the min of this slider.
do
  local slider = lurek.ui.newSlider(0, 100)
  local val = slider:getMin()
  lurek.log.info("LSlider:getMin=" .. tostring(val), "ui")
end


--@api-stub: LProgressBar:getMax
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


--@api-stub: LToolbar:getOrientation
-- Returns the orientation of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  local val = split:getOrientation()
  lurek.log.info("LSplitPanel:getOrientation=" .. tostring(val), "ui")
end


--@api-stub: LToolbar:setOrientation
-- Sets the orientation of this split panel.
do
  local split = lurek.ui.newSplitPanel("vertical")
  split:setOrientation("horizontal")
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


--@api-stub: LAccordion:addSection
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


--@api-stub: LAccordion:getSectionCount
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
  local section_widget = {}
  sbar:setSectionWidget(1, section_widget)
  lurek.log.info("LStatusBar:setSectionWidget applied", "ui")
end


-- LSwitch methods


--@api-stub: LSwitch:setOn
-- Sets the on of this switch.
do
  local sw = lurek.ui.newSwitch(false)
  sw:setOn(true)
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


--@api-stub: LTooltipPanel:setText
-- Sets the text of this text input.
do
  local input = lurek.ui.newTextInput()
  input:setText("Hello, world!")
  lurek.log.info("LTextInput:setText applied", "ui")
end


--@api-stub: LTooltipPanel:getText
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
  tb:setOrientation("horizontal")
  lurek.log.info("LToolbar:setOrientation applied", "ui")
end


--@api-stub: LDialog:addButton
-- Adds a button to this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:addButton("save", "Save")
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
  local val = tb:getButton("save")
  lurek.log.info("LToolbar:getButton=" .. tostring(val), "ui")
end


--@api-stub: LToolbar:setButtonEnabled
-- Sets whether this toolbar is enabled and accepts input.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:setButtonEnabled("save", true)
  lurek.log.info("LToolbar:setButtonEnabled applied", "ui")
end


--@api-stub: LToolbar:setButtonToggled
-- Sets the button toggled of this toolbar.
do
  local tb = lurek.ui.newToolbar("horizontal")
  tb:setButtonToggled("save", true)
  lurek.log.info("LToolbar:setButtonToggled applied", "ui")
end


--@api-stub: LToolbar:isButtonToggled
-- Returns true if this toolbar button toggled.
do
  local tb = lurek.ui.newToolbar("horizontal")
  local val = tb:isButtonToggled("save")
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
  tree:setNodeIcon(1, "folder")
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


--@api-stub: LAreaChart:type
-- Returns the Lua-visible type name string for this ui widget handle.
do
  local w = lurek.ui.newPanel()
  local val = w:type()
  lurek.log.info("LUiWidget:type=" .. tostring(val), "ui")
end


--@api-stub: LAreaChart:typeOf
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
  w:setVisible(true)
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
  w:setEnabled(true)
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
  w:setId("widget1")
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
  w:addChild(lurek.ui.newLabel("x"))
  lurek.log.info("LUiWidget:addChild done", "ui")
end


--@api-stub: LUiWidget:removeChild
-- Removes a child from this ui widget.
do
  local w = lurek.ui.newPanel()
  w:removeChild(lurek.ui.newLabel("x"))
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
  w:findById("widget1")
  lurek.log.info("LUiWidget:findById called", "ui")
end


--@api-stub: LMenuItem:setOnClick
-- Sets the on click of this ui widget.
do
  local w = lurek.ui.newPanel()
  w:setOnClick(function() end)
  lurek.log.info("LUiWidget:setOnClick callback set", "ui")
end


--@api-stub: LColorPicker:setOnChange
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

print("content/examples/ui.lua")

-- =============================================================================
-- STUBS: 13 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAreaChart methods
-- -----------------------------------------------------------------------------

--@api-stub: LBarChart:addSeries
-- Adds a named series to this bar chart.
do
  -- Track per-wave enemy kill counts to display in a post-round summary screen.
  local chart = lurek.ui.newBarChart({ width = 240, height = 160, title = "Wave Kills" })
  chart:addSeries("wave_1", 1.0, 0.3, 0.3)
  chart:addSeries("wave_2", 0.3, 1.0, 0.3)
  chart:addSeries("wave_3", 0.3, 0.3, 1.0)
  lurek.log.info("bar chart has 3 series for wave kills", "ui")
end

--@api-stub: LBarChart:drawToImage
-- Renders this bar chart to an image buffer.
do
  -- Render the DPS chart to an image for the combat log overlay.
  local chart = lurek.ui.newBarChart({ width = 200, height = 120, title = "DPS" })
  chart:addSeries("damage", 0.9, 0.2, 0.2)
  local target = lurek.image.newImageData(200, 120)
  chart:drawToImage(target)
  lurek.log.info("bar chart rendered to image: " .. tostring(target), "ui")
end

-- -----------------------------------------------------------------------------
-- LPieChart methods
-- -----------------------------------------------------------------------------

--@api-stub: LPieChart:drawToImage
-- Renders this pie chart to an image buffer.
do
  -- Show resource distribution (gold/wood/food) in the economy panel.
  local pie = lurek.ui.newPieChart({ width = 150, height = 150, title = "Resources" })
  local target = lurek.image.newImageData(150, 150)
  pie:drawToImage(target)
  lurek.log.info("pie chart rendered to image: " .. tostring(target), "ui")
end

-- -----------------------------------------------------------------------------
-- LScatterPlot methods
-- -----------------------------------------------------------------------------

--@api-stub: LScatterPlot:drawToImage
-- Renders this scatter plot to an image buffer.
do
  -- Visualize player hit accuracy (x=distance, y=damage) for aim analysis.
  local plot = lurek.ui.newScatterPlot({ width = 200, height = 150, title = "Accuracy" })
  local target = lurek.image.newImageData(200, 150)
  plot:drawToImage(target)
  lurek.log.info("scatter plot rendered to image: " .. tostring(target), "ui")
end

-- -----------------------------------------------------------------------------
-- LTheme methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 66 uncovered lurek.ui API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.ui.drawToImage ------------------------------------------
--@api-stub: lurek.ui.drawToImage
-- Renders the entire UI to an image buffer.
do
  -- Render a UI widget tree to an off-screen image for thumbnails or minimap overlays.
  local panel = lurek.ui.newPanel()
  panel:setTitle("Preview")
  local img = lurek.ui.drawToImage(200, 150)
  lurek.log.debug("UI drawn to image: " .. tostring(img ~= nil), "ui")
end

-- -----------------------------------------------------------------------------
-- LBarChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBarChart:type ------------------------------------------------
--@api-stub: LBarChart:type
-- Returns the type name of this object.
do
  local obj = lurek.ui.newBarChart({width=300, height=200})
  lurek.log.debug("type: " .. obj:type(), "example") -- "LBarChart"
end

-- ---- Stub: LBarChart:typeOf ----------------------------------------------
--@api-stub: LBarChart:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.ui.newBarChart({width=300, height=200})
  lurek.log.debug("typeOf LBarChart: " .. tostring(obj:typeOf("LBarChart")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LButton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LButton:setText -----------------------------------------------
--@api-stub: LButton:setText
-- Sets the display text on this button.
do
  local btn = lurek.ui.newButton("Play")
  btn:setText("Replay")
  lurek.log.debug("new label: " .. btn:getText(), "ui") -- "Replay"
end

-- ---- Stub: LButton:getText -----------------------------------------------
--@api-stub: LButton:getText
-- Returns the current display text of this button.
do
  local btn = lurek.ui.newButton("Start Game")
  local text = btn:getText()
  lurek.log.debug("button text: " .. text, "ui") -- "Start Game"
end

-- -----------------------------------------------------------------------------
-- LCheckbox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCheckbox:setChecked ------------------------------------------
--@api-stub: LCheckbox:setChecked
-- Sets the checked state of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Sound On")
  cb:setChecked(true)
  lurek.log.debug("checkbox toggled on", "ui")
end

-- ---- Stub: LCheckbox:isChecked -------------------------------------------
--@api-stub: LCheckbox:isChecked
-- Returns whether this checkbox is currently checked.
do
  local cb = lurek.ui.newCheckbox("Fullscreen")
  cb:setChecked(true)
  lurek.log.debug("checked: " .. tostring(cb:isChecked()), "ui") -- true
end

-- ---- Stub: LCheckbox:setText ---------------------------------------------
--@api-stub: LCheckbox:setText
-- Sets the label text displayed next to this checkbox.
do
  local cb = lurek.ui.newCheckbox("Old Label")
  cb:setText("New Label")
  lurek.log.debug("new checkbox text: " .. cb:getText(), "ui")
end

-- ---- Stub: LCheckbox:getText ---------------------------------------------
--@api-stub: LCheckbox:getText
-- Returns the label text of this checkbox.
do
  local cb = lurek.ui.newCheckbox("Show FPS")
  local text = cb:getText()
  lurek.log.debug("checkbox label: " .. text, "ui") -- "Show FPS"
end

-- -----------------------------------------------------------------------------
-- LComboBox methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LComboBox:addItem ---------------------------------------------
--@api-stub: LComboBox:addItem
-- Appends a new text item to this combo box's dropdown list.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Easy")
  cb:addItem("Normal")
  cb:addItem("Hard")
  lurek.log.debug("combobox items: " .. cb:getItemCount(), "ui") -- 3
end

-- ---- Stub: LComboBox:removeItem ------------------------------------------
--@api-stub: LComboBox:removeItem
-- Removes the item at the given 1-based index from this combo box.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Alpha")
  cb:addItem("Beta")
  cb:addItem("Gamma")
  cb:removeItem(2)
  lurek.log.debug("items after remove: " .. cb:getItemCount(), "ui") -- 2
end

-- ---- Stub: LComboBox:clearItems ------------------------------------------
--@api-stub: LComboBox:clearItems
-- Removes all items from this combo box.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Old Option")
  cb:clearItems()
  lurek.log.debug("items after clear: " .. cb:getItemCount(), "ui") -- 0
end

-- ---- Stub: LComboBox:getItemCount ----------------------------------------
--@api-stub: LComboBox:getItemCount
-- Returns the number of items in this combo box.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("x")
  cb:addItem("y")
  lurek.log.debug("count: " .. cb:getItemCount(), "ui") -- 2
end

-- ---- Stub: LComboBox:getItem ---------------------------------------------
--@api-stub: LComboBox:getItem
-- Returns the text of the item at the given 1-based index.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Option A")
  cb:addItem("Option B")
  local text = cb:getItem(1)
  lurek.log.debug("item 1: " .. text, "ui") -- "Option A"
end

-- ---- Stub: LComboBox:setSelectedIndex ------------------------------------
--@api-stub: LComboBox:setSelectedIndex
-- Sets the selected item by 1-based index.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Low")
  cb:addItem("Medium")
  cb:addItem("High")
  cb:setSelectedIndex(3)
  lurek.log.debug("selected index: " .. cb:getSelectedIndex(), "ui") -- 3
end

-- ---- Stub: LComboBox:getSelectedIndex ------------------------------------
--@api-stub: LComboBox:getSelectedIndex
-- Returns the 1-based index of the currently selected item, or 0 if none is selected.
do
  local cb = lurek.ui.newComboBox()
  cb:addItem("Easy")
  cb:addItem("Normal")
  cb:setSelectedIndex(2)
  lurek.log.debug("selected: " .. cb:getSelectedIndex(), "ui") -- 2
end

-- -----------------------------------------------------------------------------
-- LGuiWindow methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGuiWindow:getTitle -------------------------------------------
--@api-stub: LGuiWindow:getTitle
-- Returns the title bar text of this GUI window.
do
  local win = lurek.ui.newWindow("Settings")
  local title = win:getTitle()
  lurek.log.debug("window title: " .. title, "ui") -- "Settings"
end

-- ---- Stub: LGuiWindow:setTitle -------------------------------------------
--@api-stub: LGuiWindow:setTitle
-- Sets the title bar text of this GUI window.
do
  local win = lurek.ui.newWindow("Old Title")
  win:setTitle("Inventory")
  lurek.log.debug("new title: " .. win:getTitle(), "ui") -- "Inventory"
end

-- ---- Stub: LGuiWindow:setOnClose -----------------------------------------
--@api-stub: LGuiWindow:setOnClose
-- Registers a callback invoked when this window is closed.
do
  local win = lurek.ui.newWindow("Dialog")
  win:setOnClose(function()
    lurek.log.debug("window closed by player", "ui")
  end)
end

-- -----------------------------------------------------------------------------
-- LLabel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLabel:setText ------------------------------------------------
--@api-stub: LLabel:setText
-- Sets the display text on this label.
do
  local lbl = lurek.ui.newLabel("Score: 0")
  lbl:setText("Score: 1500")
  lurek.log.debug("updated label: " .. lbl:getText(), "ui")
end

-- ---- Stub: LLabel:getText ------------------------------------------------
--@api-stub: LLabel:getText
-- Returns the current display text of this label.
do
  local lbl = lurek.ui.newLabel("Score: 0")
  local text = lbl:getText()
  lurek.log.debug("label text: " .. text, "ui") -- "Score: 0"
end

-- -----------------------------------------------------------------------------
-- LLineChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLineChart:addSeries ------------------------------------------
--@api-stub: LLineChart:addSeries
-- Adds a named series of points to this line chart.
do
  local chart = lurek.ui.newLineChart({width=400, height=200})
  chart:addSeries("FPS", {{0,60},{1,58},{2,62},{3,59},{4,61}}, 0.0, 1.0, 0.0)
  lurek.log.debug("series added to line chart", "ui")
end

-- ---- Stub: LLineChart:setYMax --------------------------------------------
--@api-stub: LLineChart:setYMax
-- Sets the maximum Y-axis value for this line chart.
do
  local chart = lurek.ui.newLineChart({width=400, height=200})
  chart:setYMax(100)
  lurek.log.debug("y-axis max set to 100", "ui")
end

-- ---- Stub: LLineChart:drawToImage ----------------------------------------
--@api-stub: LLineChart:drawToImage
-- Renders this line chart to an image buffer.
do
  local chart = lurek.ui.newLineChart({width=400, height=200})
  chart:addSeries("ping", {{0,10},{1,15},{2,12},{3,8},{4,20}}, 0.5, 0.5, 1.0)
  local img = lurek.image.newImageData(400, 200)
  chart:drawToImage(img)
  lurek.log.debug("chart drawn to image: " .. tostring(img ~= nil), "ui")
end

-- ---- Stub: LLineChart:type -----------------------------------------------
--@api-stub: LLineChart:type
-- Returns the type name of this object.
do
  local obj = lurek.ui.newLineChart({width=400, height=200})
  lurek.log.debug("type: " .. obj:type(), "example") -- "LLineChart"
end

-- ---- Stub: LLineChart:typeOf ---------------------------------------------
--@api-stub: LLineChart:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.ui.newLineChart({width=400, height=200})
  lurek.log.debug("typeOf LLineChart: " .. tostring(obj:typeOf("LLineChart")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LMenuItem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMenuItem:getText ---------------------------------------------
--@api-stub: LMenuItem:getText
-- Returns the display text of this menu item.
do
  local item = lurek.ui.newMenuItem("File")
  local text = item:getText()
  lurek.log.debug("menu item: " .. text, "ui") -- "File"
end

-- ---- Stub: LMenuItem:setText ---------------------------------------------
--@api-stub: LMenuItem:setText
-- Sets the display text of this menu item.
do
  local item = lurek.ui.newMenuItem("Old")
  item:setText("New Game")
  lurek.log.debug("menu item updated: " .. item:getText(), "ui")
end

-- -----------------------------------------------------------------------------
-- LPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPanel:setTitle -----------------------------------------------
--@api-stub: LPanel:setTitle
-- Sets the title text displayed on this panel's header.
do
  local panel = lurek.ui.newPanel()
  panel:setTitle("Inventory")
  lurek.log.debug("panel title set", "ui")
end

-- ---- Stub: LPanel:getTitle -----------------------------------------------
--@api-stub: LPanel:getTitle
-- Returns the title text of this panel.
do
  local panel = lurek.ui.newPanel()
  panel:setTitle("Stats")
  local title = panel:getTitle()
  lurek.log.debug("panel title: " .. title, "ui") -- "Stats"
end

-- -----------------------------------------------------------------------------
-- LPieChart methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPieChart:type ------------------------------------------------
--@api-stub: LPieChart:type
-- Returns the type name of this object.
do
  local obj = lurek.ui.newPieChart({width=200, height=200})
  lurek.log.debug("type: " .. obj:type(), "example") -- "LPieChart"
end

-- ---- Stub: LPieChart:typeOf ----------------------------------------------
--@api-stub: LPieChart:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.ui.newPieChart({width=200, height=200})
  lurek.log.debug("typeOf LPieChart: " .. tostring(obj:typeOf("LPieChart")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LProgressBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LProgressBar:setValue -----------------------------------------
--@api-stub: LProgressBar:setValue
-- Sets the current fill value of this progress bar, clamped to its range.
do
  local pb = lurek.ui.newProgressBar()
  pb:setRange(0, 100)
  pb:setValue(42)
  lurek.log.debug("progress bar set to 42", "ui")
end

-- ---- Stub: LProgressBar:getValue -----------------------------------------
--@api-stub: LProgressBar:getValue
-- Returns the current value of this progress bar.
do
  local pb = lurek.ui.newProgressBar()
  pb:setRange(0, 200)
  pb:setValue(120)
  lurek.log.debug("value: " .. pb:getValue(), "ui") -- 120
end

-- ---- Stub: LProgressBar:getProgress --------------------------------------
--@api-stub: LProgressBar:getProgress
-- Returns the normalized progress as a fraction (0.0 to 1.0) of the current range.
do
  local pb = lurek.ui.newProgressBar()
  pb:setRange(0, 100)
  pb:setValue(75)
  local pct = pb:getProgress()
  lurek.log.debug("progress: " .. string.format("%.0f%%", pct * 100), "ui") -- 75%
end

-- ---- Stub: LProgressBar:setRange -----------------------------------------
--@api-stub: LProgressBar:setRange
-- Sets the minimum and maximum bounds for this progress bar.
do
  local pb = lurek.ui.newProgressBar()
  pb:setRange(0, 1000)
  pb:setValue(500)
  lurek.log.debug("half-way at 500/1000", "ui")
end

-- -----------------------------------------------------------------------------
-- LRadioButton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRadioButton:getText ------------------------------------------
--@api-stub: LRadioButton:getText
-- Returns the label text of this radio button.
do
  local rb = lurek.ui.newRadioButton("Option A")
  local text = rb:getText()
  lurek.log.debug("radio text: " .. text, "ui") -- "Option A"
end

-- ---- Stub: LRadioButton:setText ------------------------------------------
--@api-stub: LRadioButton:setText
-- Sets the label text of this radio button.
do
  local rb = lurek.ui.newRadioButton("Old")
  rb:setText("New Option")
  lurek.log.debug("radio updated: " .. rb:getText(), "ui")
end

-- ---- Stub: LRadioButton:setOnChange --------------------------------------
--@api-stub: LRadioButton:setOnChange
-- Registers a callback invoked when this radio button's selection changes.
do
  local rb = lurek.ui.newRadioButton("Enable shadows")
  rb:setOnChange(function(checked)
    lurek.log.debug("shadows: " .. tostring(checked), "ui")
  end)
end

-- -----------------------------------------------------------------------------
-- LScatterPlot methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LScatterPlot:type ---------------------------------------------
--@api-stub: LScatterPlot:type
-- Returns the type name of this object.
do
  local obj = lurek.ui.newScatterPlot({width=300, height=200})
  lurek.log.debug("type: " .. obj:type(), "example") -- "LScatterPlot"
end

-- ---- Stub: LScatterPlot:typeOf -------------------------------------------
--@api-stub: LScatterPlot:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.ui.newScatterPlot({width=300, height=200})
  lurek.log.debug("typeOf LScatterPlot: " .. tostring(obj:typeOf("LScatterPlot")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LScrollBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LScrollBar:setOnChange ----------------------------------------
--@api-stub: LScrollBar:setOnChange
-- Registers a callback invoked when this scroll bar's position changes.
do
  local sb = lurek.ui.newScrollBar(false)
  sb:setOnChange(function(val)
    lurek.log.debug("scroll: " .. tostring(val), "ui")
  end)
end

-- -----------------------------------------------------------------------------
-- LScrollPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LScrollPanel:setContentSize -----------------------------------
--@api-stub: LScrollPanel:setContentSize
-- Sets the virtual content dimensions of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(1000, 2000)
  lurek.log.debug("content size set", "ui")
end

-- ---- Stub: LScrollPanel:getContentSize -----------------------------------
--@api-stub: LScrollPanel:getContentSize
-- Returns the virtual content dimensions of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(600, 800)
  local w, h = sp:getContentSize()
  lurek.log.debug("content: " .. w .. "x" .. h, "ui") -- 600x800
end

-- ---- Stub: LScrollPanel:setScrollPosition --------------------------------
--@api-stub: LScrollPanel:setScrollPosition
-- Sets the scroll offset position of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(600, 800)
  sp:setScrollPosition(0, 400)
  lurek.log.debug("scrolled to middle", "ui")
end

-- ---- Stub: LScrollPanel:getScrollPosition --------------------------------
--@api-stub: LScrollPanel:getScrollPosition
-- Returns the current scroll offset of this scroll panel.
do
  local sp = lurek.ui.newScrollPanel()
  sp:setContentSize(600, 800)
  sp:setScrollPosition(50, 100)
  local x, y = sp:getScrollPosition()
  lurek.log.debug("scroll pos: " .. x .. "," .. y, "ui") -- 50, 100
end

-- -----------------------------------------------------------------------------
-- LSeparator methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSeparator:isVertical -----------------------------------------
--@api-stub: LSeparator:isVertical
-- Returns whether this separator is oriented vertically.
do
  local sep = lurek.ui.newSeparator(false)
  lurek.log.debug("is vertical: " .. tostring(sep:isVertical()), "ui") -- false
end

-- -----------------------------------------------------------------------------
-- LSlider methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSlider:setValue ----------------------------------------------
--@api-stub: LSlider:setValue
-- Sets the current value of this slider, clamped to its range.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(0, 100)
  sl:setValue(45)
  lurek.log.debug("slider at 45", "ui")
end

-- ---- Stub: LSlider:getValue ----------------------------------------------
--@api-stub: LSlider:getValue
-- Returns the current value of this slider.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(0, 100)
  sl:setValue(60)
  lurek.log.debug("value: " .. sl:getValue(), "ui") -- 60
end

-- ---- Stub: LSlider:setRange ----------------------------------------------
--@api-stub: LSlider:setRange
-- Sets the minimum and maximum bounds for this slider.
do
  local volume_slider = lurek.ui.newSlider()
  volume_slider:setRange(0, 100)
  volume_slider:setValue(70)
  lurek.log.debug("volume: " .. volume_slider:getValue(), "ui") -- 70
end

-- ---- Stub: LSlider:setStep -----------------------------------------------
--@api-stub: LSlider:setStep
-- Sets the step increment for this slider's value snapping.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(0, 100)
  sl:setStep(5) -- snap to multiples of 5
  lurek.log.debug("step set to 5", "ui")
end

-- ---- Stub: LSlider:getMin ------------------------------------------------
--@api-stub: LSlider:getMin
-- Returns the minimum value of this slider's range.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(10, 100)
  lurek.log.debug("min: " .. sl:getMin(), "ui") -- 10
end

-- ---- Stub: LSlider:getMax ------------------------------------------------
--@api-stub: LSlider:getMax
-- Returns the maximum value of this slider's range.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(0, 100)
  lurek.log.debug("max: " .. sl:getMax(), "ui") -- 100
end

-- -----------------------------------------------------------------------------
-- LSplitPanel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSplitPanel:getOrientation ------------------------------------
--@api-stub: LSplitPanel:getOrientation
-- Returns the orientation of this split panel ("horizontal" or "vertical").
do
  local sp = lurek.ui.newSplitPanel("horizontal")
  local ori = sp:getOrientation()
  lurek.log.debug("orientation: " .. ori, "ui") -- "horizontal"
end

-- ---- Stub: LSplitPanel:setOrientation ------------------------------------
--@api-stub: LSplitPanel:setOrientation
-- Sets the orientation of this split panel ("horizontal" or "vertical").
do
  local sp = lurek.ui.newSplitPanel("horizontal")
  sp:setOrientation("vertical")
  lurek.log.debug("now vertical", "ui")
end

-- -----------------------------------------------------------------------------
-- LStatusBar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStatusBar:addSection -----------------------------------------
--@api-stub: LStatusBar:addSection
-- Adds a labeled section to this status bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("FPS: 60", 100)
  sb:addSection("Map: Forest", 150)
  lurek.log.debug("sections: " .. sb:getSectionCount(), "ui")
end

-- ---- Stub: LStatusBar:getSectionCount ------------------------------------
--@api-stub: LStatusBar:getSectionCount
-- Returns the number of sections in this status bar.
do
  local sb = lurek.ui.newStatusBar()
  sb:addSection("Health", 80)
  sb:addSection("Mana", 80)
  lurek.log.debug("section count: " .. sb:getSectionCount(), "ui") -- 2
end

-- -----------------------------------------------------------------------------
-- LTextInput methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTextInput:setText --------------------------------------------
--@api-stub: LTextInput:setText
-- Sets the text content of this text input field and moves the cursor to the end.
do
  local ti = lurek.ui.newTextInput()
  ti:setText("placeholder text")
  lurek.log.debug("set text in input field", "ui")
end

-- ---- Stub: LTextInput:getText --------------------------------------------
--@api-stub: LTextInput:getText
-- Returns the current text content of this text input field.
do
  local ti = lurek.ui.newTextInput()
  ti:setText("hello world")
  local t = ti:getText()
  lurek.log.debug("input text: " .. t, "ui") -- "hello world"
end

-- -----------------------------------------------------------------------------
-- LTheme methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTheme:type ---------------------------------------------------
--@api-stub: LTheme:type
-- Returns the type name of this object.
do
  local obj = lurek.ui.newTheme()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LTheme"
end

-- ---- Stub: LTheme:typeOf -------------------------------------------------
--@api-stub: LTheme:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.ui.newTheme()
  lurek.log.debug("typeOf LTheme: " .. tostring(obj:typeOf("LTheme")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LToolbar methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LToolbar:addButton --------------------------------------------
--@api-stub: LToolbar:addButton
-- Adds a new button to this toolbar and returns its 1-based index.
do
  local tb = lurek.ui.newToolbar()
  tb:addButton("New", "Create a new file")
  tb:addButton("Save", "Save current file")
  lurek.log.debug("2 buttons added to toolbar", "ui")
end

-- -----------------------------------------------------------------------------
-- LUiWidget methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LUiWidget:type ------------------------------------------------
--@api-stub: LUiWidget:type
-- Returns the type name string of this widget (e.g. "LButton", "LSlider").
do
  local obj = lurek.ui.newLabel('widget')
  lurek.log.debug("type: " .. obj:type(), "example") -- "LUiWidget"
end

-- ---- Stub: LUiWidget:typeOf ----------------------------------------------
--@api-stub: LUiWidget:typeOf
-- Checks whether this widget matches the given type name, including base types "LWidget" and "Object".
do
  local obj = lurek.ui.newLabel('widget')
  lurek.log.debug("typeOf LUiWidget: " .. tostring(obj:typeOf("LUiWidget")), "example") -- true
end

-- ---- Stub: LUiWidget:setOnClick ------------------------------------------
--@api-stub: LUiWidget:setOnClick
-- Registers a callback function invoked when this widget is clicked.
do
  local btn = lurek.ui.newButton("OK")
  btn:setOnClick(function()
    lurek.log.debug("OK button clicked", "ui")
  end)
end

-- ---- Stub: LUiWidget:setOnChange -----------------------------------------
--@api-stub: LUiWidget:setOnChange
-- Registers a callback function invoked when this widget's value changes.
do
  local sl = lurek.ui.newSlider()
  sl:setRange(0, 100)
  sl:setOnChange(function(val)
    lurek.log.debug("slider changed to " .. tostring(val), "ui")
  end)
end
