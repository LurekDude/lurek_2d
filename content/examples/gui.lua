-- examples/gui.lua
-- Retained-mode widget GUI system for Luna2D
-- API: luna.ui
-- Constructors return widget tables; all forward events from game callbacks.
-- This file is documentation code, not a runnable game.

--------------------------------------------------------------------------------
-- Module-level setup and themes
--------------------------------------------------------------------------------

-- Create and apply a custom theme
local theme = luna.ui.newTheme()
luna.ui.setTheme(theme)
local t = luna.ui.getTheme()   -- returns theme table or nil

-- Access root context widget count
local n = luna.ui.getWidgetCount()  -- number

-- Toast notifications
luna.ui.addToast({ message = "Hello!", duration = 3.0 })
local tc = luna.ui.getToastCount()  -- number

-- Focus management
luna.ui.setFocus(nil)              -- clear focus
local focused = luna.ui.getFocus() -- number or nil
luna.ui.focusNext()
luna.ui.focusPrev()
luna.ui.clearFocus()

--------------------------------------------------------------------------------
-- Event forwarding (call from game callbacks)
--------------------------------------------------------------------------------

luna.mousepressed = function(x, y, btn)
    luna.ui.mousepressed(x, y, btn)
end

luna.mousereleased = function(x, y, btn)
    luna.ui.mousereleased(x, y, btn)
end

luna.mousemoved = function(x, y)
    local consumed = luna.ui.mousemoved(x, y)  -- returns boolean
end

luna.keypressed = function(key)
    local consumed = luna.ui.keypressed(key)   -- returns boolean
end

luna.textinput = function(text)
    luna.ui.textinput(text)
end

luna.wheelmoved = function(x, y)
    luna.ui.wheelmoved(x, y)
end

-- luna.process is called every frame; forward dt to the widget system
luna.process = function(dt)
    luna.ui.update(dt)
end

--------------------------------------------------------------------------------
-- Base widget methods (shared by ALL widget types)
--------------------------------------------------------------------------------

-- All widget constructors return a "widget table" with these shared methods:
-- :setPosition(x, y)       :getPosition() → x, y
-- :setSize(w, h)           :getSize()     → w, h
-- :setVisible(bool)        :isVisible()   → bool
-- :setEnabled(bool)        :isEnabled()   → bool
-- :setId(str)              :getId()       → str
-- :setTooltip(str)         :getTooltip()  → str
-- :getState()              → "normal" | "hover" | "pressed" | "disabled"
-- :addChild(child_tbl)     :removeChild(child_tbl)
-- :getChildCount()         → integer
-- :findById(id)            → widget table or nil
-- :setOnClick(fn)          :setOnChange(fn)    :setOnDraw(fn)
-- :containsPoint(x, y)    → boolean
-- :setPadding(top, right?, bottom?, left?)    :getPadding() → t,r,b,l
-- :setMargin(top, right?, bottom?, left?)     :getMargin()  → t,r,b,l
-- :setZOrder(z)            :getZOrder()   → z
-- :setMinSize(w, h)        :getMinSize()  → w, h
-- :setMaxSize(w, h)        :getMaxSize()  → w, h
-- :setAnchor(left?, top?, right?, bottom?)
-- :setAnchorCenter(cx?, cy?)   :clearAnchor()
-- :setFlexGrow(n)          :getFlexGrow() → n
-- :setFlexShrink(n)        :getFlexShrink() → n

--------------------------------------------------------------------------------
-- Button
--------------------------------------------------------------------------------

local btn = luna.ui.newButton("Click me")
btn:setText("Submit")
local txt = btn:getText()    -- "Submit"
btn:setOnClick(function() print("clicked!") end)
btn:setPosition(10, 10)
btn:setSize(100, 30)

--------------------------------------------------------------------------------
-- Label
--------------------------------------------------------------------------------

local lbl = luna.ui.newLabel("Hello, World!")
lbl:setText("Updated text")
local s = lbl:getText()    -- "Updated text"
lbl:setPosition(10, 50)

--------------------------------------------------------------------------------
-- TextInput
--------------------------------------------------------------------------------

local ti = luna.ui.newTextInput()
ti:setText("initial value")
ti:setPlaceholder("Type here...")
local ph = ti:getPlaceholder()    -- "Type here..."
ti:setMaxLength(100)
local focused = ti:isFocused()    -- boolean
local cursor = ti:getCursorPosition()  -- integer
ti:setOnChange(function() print("changed:", ti:getText()) end)

--------------------------------------------------------------------------------
-- CheckBox
--------------------------------------------------------------------------------

local cb = luna.ui.newCheckbox("Enable feature")
cb:setChecked(true)
local checked = cb:isChecked()   -- boolean
cb:setOnChange(function() print("checked:", cb:isChecked()) end)

--------------------------------------------------------------------------------
-- Slider
--------------------------------------------------------------------------------

local sl = luna.ui.newSlider(0, 100)
sl:setValue(50)
local v = sl:getValue()   -- 50
sl:setRange(0, 200)
sl:setStep(5)
local mn = sl:getMin()    -- 0
local mx = sl:getMax()    -- 200
sl:setOnChange(function() print("slider:", sl:getValue()) end)

--------------------------------------------------------------------------------
-- ProgressBar
--------------------------------------------------------------------------------

local pb = luna.ui.newProgressBar(0, 100)
pb:setValue(75)
local pv = pb:getValue()      -- 75
local pp = pb:getProgress()   -- 0.75 (normalized)
pb:setRange(0, 200)
local pm = pb:getMin()        -- 0
local pmx = pb:getMax()       -- 200

--------------------------------------------------------------------------------
-- ComboBox (dropdown)
--------------------------------------------------------------------------------

local combo = luna.ui.newComboBox()
combo:addItem("Option A")
combo:addItem("Option B")
combo:addItem("Option C")
combo:removeItem(1)    -- remove first item by index
local count = combo:getItemCount()    -- number
local item = combo:getItem(1)         -- string
combo:setSelectedIndex(2)
local idx = combo:getSelectedIndex()  -- integer
local sel = combo:getSelectedItem()   -- string
combo:setOnChange(function() print("selected:", combo:getSelectedItem()) end)
combo:clearItems()

--------------------------------------------------------------------------------
-- ListBox
--------------------------------------------------------------------------------

local lb = luna.ui.newList()
lb:addItem("Row 1")
lb:addItem("Row 2")
lb:addItem("Row 3")
lb:removeItem(1)
local lcount = lb:getItemCount()     -- number
local litem = lb:getItem(2)          -- string
lb:setSelectedIndex(1)
local lidx = lb:getSelectedIndex()   -- integer
lb:setItemHeight(20)
lb:clearItems()

--------------------------------------------------------------------------------
-- TabBar
--------------------------------------------------------------------------------

local tabs = luna.ui.newTabBar()
tabs:addTab("General")
tabs:addTab("Advanced")
tabs:addTab("Help")
tabs:removeTab(3)
local tab = tabs:getTab(1)      -- string
local tc2 = tabs:getTabCount()  -- number
tabs:setActiveTab(2)
local active = tabs:getActiveTab()  -- integer (1-based)

--------------------------------------------------------------------------------
-- Panel (container with optional title)
--------------------------------------------------------------------------------

local panel = luna.ui.newPanel()
panel:setTitle("Settings")
local pt = panel:getTitle()     -- "Settings"
panel:setScrollable(true)
panel:addChild(btn)
panel:addChild(lbl)

--------------------------------------------------------------------------------
-- Layout (flex-style auto-layout container)
--------------------------------------------------------------------------------

local layout = luna.ui.newLayout("horizontal")  -- or "vertical" (default)
layout:setDirection("vertical")
local dir = layout:getDirection()   -- "vertical"
layout:setSpacing(5)
local sp = layout:getSpacing()      -- 5
layout:setColumns(2)
layout:setWrap(true)
local wrap = layout:getWrap()       -- boolean
layout:setAlign("center")           -- "start" | "center" | "end" | "stretch"
local align = layout:getAlign()
layout:setJustify("space-between")  -- "start" | "end" | "center" | "space-between" | "space-around"
local just = layout:getJustify()
layout:addChild(btn)
layout:addChild(lbl)

--------------------------------------------------------------------------------
-- ScrollPanel
--------------------------------------------------------------------------------

local sp2 = luna.ui.newScrollPanel()
sp2:setContentSize(400, 800)
local cw, ch = sp2:getContentSize()  -- content dimensions
sp2:setScrollPosition(0, 100)
local sx, sy = sp2:getScrollPosition()
local maxX, maxY = sp2:getMaxScroll()
sp2:setScrollSpeed(3)
local speed = sp2:getScrollSpeed()  -- number

--------------------------------------------------------------------------------
-- Separator and Spacer
--------------------------------------------------------------------------------

local sep = luna.ui.newSeparator(false)  -- false = horizontal (default)
sep:setVertical(true)
local vert = sep:isVertical()   -- boolean
sep:setThickness(2)
local thick = sep:getThickness()   -- number

local spacer = luna.ui.newSpacer(10, 20)   -- fixed w, h
spacer:setSize(30, 30)

--------------------------------------------------------------------------------
-- TreeView
--------------------------------------------------------------------------------

local tree = luna.ui.newTreeView()
tree:addNode("Root")                 -- returns node index (1-based)
tree:addNode("Child A", 1)           -- add child of node 1
tree:addNode("Child B", 1)
tree:setNodeText(2, "Updated Child")
local text = tree:getNodeText(2)     -- "Updated Child"
tree:setNodeIcon(1, "folder")
tree:expandNode(1)
tree:collapseNode(1)
tree:toggleNode(1)
local expanded = tree:isNodeExpanded(1)  -- boolean
local isExp = tree:isExpanded(1)          -- alias
tree:expandAll()
tree:collapseAll()
local count3 = tree:getNodeCount()   -- total nodes
tree:setSelectedNode(2)
local selNode = tree:getSelectedNode()   -- index or nil
local children = tree:getChildNodes(1)   -- table of indices
local parent = tree:getParentNode(2)     -- parent index or nil
local depth = tree:getNodeDepth(2)       -- 0-based depth
tree:removeNode(3)
tree:clearNodes()

--------------------------------------------------------------------------------
-- RadioButton
--------------------------------------------------------------------------------

local rb = luna.ui.newRadioButton("Option 1", "group_a")
rb:setGroup("group_a")
local g = rb:getGroup()      -- "group_a"
rb:setSelected(true)
local sel2 = rb:isSelected() -- boolean
rb:setOnChange(function() print("radio changed:", rb:isSelected()) end)

--------------------------------------------------------------------------------
-- ScrollBar
--------------------------------------------------------------------------------

local sb = luna.ui.newScrollBar(false)  -- false = horizontal
sb:setScrollPosition(50)
local spos = sb:getScrollPosition()   -- number
sb:setContentSize(500)
local csize = sb:getContentSize()     -- number
sb:setViewSize(200)
local vsize = sb:getViewSize()        -- number
local isV = sb:isVertical()           -- boolean
sb:setOnChange(function() print("scroll:", sb:getScrollPosition()) end)

--------------------------------------------------------------------------------
-- GUIWindow (floating dialog-style window)
--------------------------------------------------------------------------------

local win = luna.ui.newWindow("My Window")
win:setTitle("Updated Title")
local wt = win:getTitle()       -- string
win:setCloseable(true)
local close = win:isCloseable() -- boolean
win:setDraggable(true)
local drag = win:isDraggable()  -- boolean
win:setResizable(true)
local resize = win:isResizable()  -- boolean
win:setOnClose(function() print("window closed") end)
win:addChild(lbl)

--------------------------------------------------------------------------------
-- SplitPanel (resizable two-pane split)
--------------------------------------------------------------------------------

local split = luna.ui.newSplitPanel("horizontal")  -- or "vertical"
split:setOrientation("vertical")
local orient = split:getOrientation()  -- "vertical"
split:setSplitPosition(0.5)
local pos = split:getSplitPosition()   -- 0.5
split:setMinPanelSize(50)
local minSize = split:getMinPanelSize()  -- 50
split:setFirstChild(panel)
split:setSecondChild(layout)
local fc = split:getFirstChild()   -- widget table
local sc = split:getSecondChild()  -- widget table

--------------------------------------------------------------------------------
-- DockPanel (dockable child panels)
--------------------------------------------------------------------------------

local dock = luna.ui.newDockPanel()
dock:dock(panel, "left")      -- sides: "left", "right", "top", "bottom"
dock:dock(layout, "bottom")
dock:undock(panel)
local dc = dock:getDockedCount()  -- number
dock:setSplitSize(200)
local ds = dock:getSplitSize()    -- number

--------------------------------------------------------------------------------
-- Toolbar
--------------------------------------------------------------------------------

local toolbar = luna.ui.newToolbar("horizontal")
toolbar:setOrientation("vertical")
local to = toolbar:getOrientation()   -- "vertical"
toolbar:addButton("save", "Save file")
toolbar:addButton("open", "Open file")
local tbBtn = toolbar:getButton("save")  -- widget table or nil
toolbar:setButtonEnabled("save", true)
toolbar:setButtonToggled("save", false)
local toggled = toolbar:isButtonToggled("save")  -- boolean

--------------------------------------------------------------------------------
-- MenuBar
--------------------------------------------------------------------------------

local menu = luna.ui.newMenuBar()
local fileMenu = luna.ui.newMenuItem("File")
local editMenu = luna.ui.newMenuItem("Edit")
menu:addChild(fileMenu)
menu:addChild(editMenu)

--------------------------------------------------------------------------------
-- Specialized widgets
--------------------------------------------------------------------------------

-- Dialog (modal workflow)
local dlg = luna.ui.newDialog("Confirm?")
dlg:setTitle("Are you sure?")
dlg:addChild(luna.ui.newLabel("This cannot be undone."))
dlg:addChild(luna.ui.newButton("OK"))
dlg:addChild(luna.ui.newButton("Cancel"))

-- StatusBar
local status = luna.ui.newStatusBar()
status:addChild(luna.ui.newLabel("Ready"))

-- Accordion (collapsing sections)
local accord = luna.ui.newAccordion()
accord:addChild(luna.ui.newPanel())

-- TooltipPanel
local tip = luna.ui.newTooltipPanel("Helpful hint here")

-- NinePatch (scalable 9-slice image)
local nine = luna.ui.newNinePatch()
nine:setInsets(10, 10, 10, 10)    -- top, right, bottom, left
local t2, r2, b2, l2 = nine:getInsets()
nine:setImageDimensions(64, 64)
local nw, nh = nine:getImageDimensions()
local slices = nine:getSlices()   -- table of patch rects

-- Toast (auto-dismissing notification)
local toast = luna.ui.newToast("Saved!", 2.0)
toast:setMessage("File saved.")
local msg = toast:getMessage()    -- string
toast:setDuration(3)
local dur = toast:getDuration()   -- number
local prog = toast:getProgress()  -- 0.0–1.0 elapsed
local exp = toast:isExpired()     -- boolean

-- ColorPicker
local picker = luna.ui.newColorPicker()
picker:setOnChange(function() print("color changed") end)

-- Table widget (grid data view)
local tblWidget = luna.ui.newTable()
tblWidget:addChild(luna.ui.newLabel("Header"))

-- ImageWidget
local imgW = luna.ui.newImageWidget()
imgW:setSize(128, 128)

--------------------------------------------------------------------------------
-- Root container usage pattern
--------------------------------------------------------------------------------

local root = luna.ui.getRoot()   -- main root panel widget
root:addChild(panel)
root:addChild(toolbar)

-- luna.render_ui draws widgets on top of the game scene each frame
luna.render_ui = function()
    -- GUI is rendered automatically via the engine — no explicit draw call needed
end

--------------------------------------------------------------------------------
-- Accordion  (collapsible section container)
--------------------------------------------------------------------------------
-- addSection(title, [content_widget]) registers a named panel. By default all
-- sections are collapsed; click the header or call toggleSection() to open one.
-- setExclusive(true) gives classic "accordion" behaviour — only one open panel.

local acc = luna.ui.newAccordion()
acc:addSection("Gameplay")               -- bare section, toggle to reveal content
acc:addSection("Graphics", gfx_pnl)     -- section pre-populated with a widget
acc:addSection("Controls")
local acc_n    = acc:getSectionCount()   -- → 3
local acc_t    = acc:getSectionTitle(2)  -- → "Graphics"
local acc_open = acc:isSectionExpanded(2)  -- → false (collapsed by default)
acc:setExclusive(true)                   -- only one section may be expanded
local acc_excl = acc:isExclusive()       -- → true
acc:toggleSection(1)                     -- expand/collapse "Gameplay"

--------------------------------------------------------------------------------
-- Color_Picker  (colour chooser with mode switching)
--------------------------------------------------------------------------------
-- Lets the player pick a colour in RGB, RGBA, or HSV mode. setShowAlpha(false)
-- hides the alpha slider for games that don't need transparency control.

local pal      = luna.ui.newColorPicker()
local pal_col  = pal:getColor()          -- {r, g, b, a} current colour
local pal_mode = pal:getColorMode()      -- "rgba" | "rgb" | "hsv"
local pal_show = pal:getShowAlpha()      -- boolean
pal:setColor({r=0.8, g=0.4, b=0.2, a=1.0})  -- set programmatically
pal:setColorMode("hsv")                  -- switch to HSV sliders
pal:setShowAlpha(false)                  -- hide the alpha channel slider
pal:setOnChange(function()
    local c = pal:getColor()
    print(("r=%.2f g=%.2f b=%.2f"):format(c.r, c.g, c.b))
end)

--------------------------------------------------------------------------------
-- Dialog  (modal overlay requiring explicit user action)
--------------------------------------------------------------------------------
-- Wrap confirmations in a Dialog. setModal(true) blocks all input for other
-- widgets while visible. Call open()/close() to show/hide it.

local confirm  = luna.ui.newDialog("Confirm Exit?")
local dlg_body = luna.ui.newLabel("All unsaved progress will be lost.")
confirm:setContent(dlg_body)
confirm:setModal(true)
confirm:open()                           -- show modal overlay
local dlg_modal   = confirm:isModal()   -- → true
local dlg_open    = confirm:isOpen()    -- → true
local dlg_content = confirm:getContent() -- → the Label widget
confirm:close()                          -- remove from scene

--------------------------------------------------------------------------------
-- Gui_Table  (sortable data grid)
--------------------------------------------------------------------------------
-- addColumn(title) defines headers; addRow({cell, …}) appends data.
-- setSortable lets users click headers to sort. Use getSelectedRow() in
-- setOnSelect callback to react to row selection.

local gtbl     = luna.ui.newTable()
gtbl:addColumn("Name")
gtbl:addColumn("Score")
gtbl:addRow({"Alice", "1500"})
gtbl:addRow({"Bob",   "820"})
gtbl:addRow({"Carol", "2230"})
local gtbl_ncols = gtbl:getColumnCount()  -- → 2
local gtbl_nrows = gtbl:getRowCount()     -- → 3
gtbl:setSortable(true)
local gtbl_srt = gtbl:isSortable()        -- → true
gtbl:setCell(1, 2, "9999")               -- update row 1, col 2
local gtbl_cell = gtbl:getCell(1, 2)     -- → "9999"
gtbl:setSelectedRow(1)
local gtbl_sel  = gtbl:getSelectedRow()  -- → 1
gtbl:setOnSelect(function()
    local row = gtbl:getSelectedRow()
    print("selected row", row, "name:", gtbl:getCell(row, 1))
end)

--------------------------------------------------------------------------------
-- Image_Widget  (image display panel and nested GUI context)
--------------------------------------------------------------------------------
-- Renders a texture scaled to its bounds. Also acts as a full GUI context
-- so child widgets can be created relative to this viewport — useful for HUD
-- panels, in-game screens, or sub-interfaces inside modal dialogs.

local imgCtx = luna.ui.newImageWidget()
imgCtx:setSize(256, 256)
local img_scl   = imgCtx:getScaleMode()   -- "fit" | "fill" | "stretch" | "none"
local img_tint  = imgCtx:getTint()        -- {r, g, b, a} colour multiplier

-- Create child widgets in the sub-context (all relative to imgCtx bounds)
local iw_btn    = imgCtx:newButton("Fire")
local iw_lbl    = imgCtx:newLabel("HUD: Ready")
local iw_panel  = imgCtx:newPanel()
local iw_layout = imgCtx:newLayout("vertical")
local iw_cb     = imgCtx:newCheckbox("Auto-aim")
local iw_combo  = imgCtx:newComboBox()
local iw_dlg    = imgCtx:newDialog("Quit?")
local iw_acc    = imgCtx:newAccordion()
local iw_dock   = imgCtx:newDockPanel()
local iw_img    = imgCtx:newImageWidget()
local iw_list   = imgCtx:newList()
local iw_menu   = imgCtx:newMenuBar()
local iw_mi     = imgCtx:newMenuItem("File")
local iw_nine   = imgCtx:newNinePatch()
local iw_pb     = imgCtx:newProgressBar(0, 100)
local iw_pick   = imgCtx:newColorPicker()
local iw_gtbl   = imgCtx:newTable()

-- Forward input so nested widgets receive events
local iw_k = imgCtx:keypressed("space")
local iw_mm = imgCtx:mousemoved(120, 80)
local iw_mp = imgCtx:mousepressed(120, 80, 1)
local iw_mr = imgCtx:mousereleased(120, 80, 1)

-- Sub-context management
imgCtx:addToast({ message = "Level complete!", duration = 2.0 })
local iw_root    = imgCtx:getRoot()
local iw_nw      = imgCtx:getWidgetCount()
local iw_nt      = imgCtx:getToastCount()
local iw_focused = imgCtx:getFocus()
imgCtx:clearFocus()
imgCtx:focusNext()
imgCtx:focusPrev()
local iw_theme   = imgCtx:getTheme()

--------------------------------------------------------------------------------
-- Widget base API  (generic methods on all widgets — luna.gui namespace)
--------------------------------------------------------------------------------
-- These methods exist on every widget instance. They are also registered under
-- luna.gui.* for direct access to the "current widget" context pattern.

local wg_anchor   = luna.gui.getAnchor()
local wg_nchild   = luna.gui.getChildCount()
local wg_fgrow    = luna.gui.getFlexGrow()
local wg_fshrink  = luna.gui.getFlexShrink()
local wg_id       = luna.gui.getId()
local wg_margin   = luna.gui.getMargin()          -- top, right, bottom, left
local wg_maxsz    = luna.gui.getMaxSize()
local wg_minsz    = luna.gui.getMinSize()
local wg_padding  = luna.gui.getPadding()
local wg_pos      = luna.gui.getPosition()        -- x, y
local wg_sz       = luna.gui.getSize()            -- w, h
local wg_state    = luna.gui.getState()           -- "normal"|"hover"|"pressed"|"disabled"
local wg_tip      = luna.gui.getTooltip()
local wg_z        = luna.gui.getZOrder()
local wg_enabled  = luna.gui.isEnabled()
local wg_visible  = luna.gui.isVisible()
luna.gui.removeChild(iw_lbl)
luna.gui.setAnchor(0.0, 0.0, 1.0, 1.0)           -- stretch-fill parent edges
luna.gui.setAnchorCenter(0.5, 0.5)                -- offset from parent center
luna.gui.setEnabled(false)
luna.gui.setFlexGrow(1.0)
luna.gui.setFlexShrink(0.0)
luna.gui.setId("main_hud")
luna.gui.setMargin(4, 4, 4, 4)                    -- CSS-like t, r, b, l (px)
luna.gui.setMaxSize(800, 600)
luna.gui.setMinSize(100, 30)
luna.gui.setOnChange(function() end)
luna.gui.setOnClick(function() print("widget clicked") end)
luna.gui.setOnDraw(function() end)
luna.gui.setPadding(8, 12, 8, 12)
luna.gui.setPosition(20, 20)
luna.gui.setSize(200, 40)
luna.gui.setTooltip("Click to confirm action")
luna.gui.setVisible(true)
luna.gui.setZOrder(10)


--------------------------------------------------------------------------------
-- Image_Widget — setScaleMode / setTint
--------------------------------------------------------------------------------
-- setScaleMode controls how the image fills its bounding box. "fit" keeps the
-- aspect ratio and adds letterbox bars. "fill" crops to fill completely.
-- "stretch" distorts to fill exactly. "none" draws at native pixel size.

imgCtx:setScaleMode("fit")   -- keeps aspect ratio; letterboxes excess space
-- imgCtx:setScaleMode("fill")    -- crops to fill; no letterbox
-- imgCtx:setScaleMode("stretch") -- distorts to fill exactly
-- imgCtx:setScaleMode("none")    -- native pixel size, may clip

-- setTint multiplies every pixel colour by (r, g, b, a). Default is (1,1,1,1)
-- (no tint). Use it for damage flash, night-vision overlay, or greyscale.
imgCtx:setTint(0.9, 0.9, 0.9, 1.0)          -- slight de-saturating grey wash
-- imgCtx:setTint(1.0, 0.3, 0.3, 1.0)        -- red flash (damage feedback)
-- imgCtx:setTint(1.0, 1.0, 1.0, 0.5)        -- 50 % transparent ghost panel

--------------------------------------------------------------------------------
-- Image_Widget — child-widget factory methods
--------------------------------------------------------------------------------
-- An Image_Widget also acts as a full GUI context: every newXxx() method spawns
-- a child widget positioned relative to the Image_Widget's own bounds. This
-- lets you build HUD sub-panels, in-game inventory screens, or embedded mini-UIs
-- without creating a separate top-level GUI context.

-- Text input field (e.g. a search bar inside a HUD panel)
local iw_ti  = imgCtx:newTextInput()
iw_ti:setSize(180, 28)
iw_ti:setPosition(8, 8)

-- Horizontal slider (e.g. a volume knob scoped to a settings sub-panel)
local iw_sl  = imgCtx:newSlider(0, 100)    -- min=0, max=100
iw_sl:setValue(75)                          -- start at 75

-- Scrollable container for overflowing content (e.g. an item list in a shop)
local iw_sp  = imgCtx:newScrollPanel()
iw_sp:setSize(240, 120)

-- Tab bar — switch between "Stats", "Inventory", "Map" inside one panel
local iw_tab = imgCtx:newTabBar()
iw_tab:addTab("Stats")
iw_tab:addTab("Inventory")
iw_tab:addTab("Map")

-- Visual dividers and spacing in a flex layout
local iw_sep = imgCtx:newSeparator()        -- thin horizontal rule
local iw_spc = imgCtx:newSpacer()           -- flexible empty gap

-- Tree view (e.g. a skill tree or file hierarchy)
local iw_tv  = imgCtx:newTreeView()
local tv_root  = iw_tv:addItem(nil,     "Character")
local tv_melee = iw_tv:addItem(tv_root, "Melee")
local tv_magic = iw_tv:addItem(tv_root, "Magic")

-- Radio buttons — only one of a group may be selected at a time
local iw_rb  = imgCtx:newRadioButton("Option A")
-- pair with more in the same group: imgCtx:newRadioButton("Option B")

-- Explicit scrollbar (used when managing scroll position manually)
local iw_scb = imgCtx:newScrollBar()
iw_scb:setRange(0, 500)    -- content height 500 px
iw_scb:setPageSize(120)    -- visible area height 120 px

-- Embedded child window with its own title bar and close button
local iw_win = imgCtx:newWindow("Character Stats")
iw_win:setSize(200, 150)

-- Split panel — two resizable panes side by side (e.g. list + detail view)
local iw_spl = imgCtx:newSplitPanel()
iw_spl:setSplit(0.35)       -- left pane gets 35 % of available width

-- Toolbar with icon buttons (e.g. file operations in a level editor panel)
local iw_tlb = imgCtx:newToolbar()
iw_tlb:addButton("New",  function() end)
iw_tlb:addButton("Open", function() end)
iw_tlb:addButton("Save", function() end)

-- Status bar showing live info at the bottom of the sub-panel
local iw_stb = imgCtx:newStatusBar()
iw_stb:addSection("Ready")
iw_stb:addSection("")      -- right-aligned timestamp slot

-- Tooltip panel that pops up when hovering over a child widget
local iw_ttp = imgCtx:newTooltipPanel()
iw_ttp:setText("Hover for help")
iw_ttp:setDelay(0.4)        -- appears after 0.4 s of hover

-- Theme object — customise colours and fonts for this sub-context only
local iw_thm = imgCtx:newTheme()
-- modify iw_thm properties, then apply:
imgCtx:setTheme(iw_thm)     -- swap theme for this Image_Widget context

-- Toast notification that self-dismisses after its duration
local iw_tst = imgCtx:newToast()
-- triggered by addToast (already shown above in the sub-context section)

-- Move keyboard focus to a specific child widget programmatically
imgCtx:setFocus(iw_ti)      -- iw_ti receives keyboard events immediately

--------------------------------------------------------------------------------
-- Image_Widget — input forwarding callbacks
--------------------------------------------------------------------------------
-- When an Image_Widget is embedded inside a game scene (not a native window),
-- you must forward OS input events to it manually so its child widgets respond.
-- Call these from the matching luna.* event callbacks.

-- luna.textinput (text entry): forward typed characters to focused child
imgCtx:textinput("a")           -- as if user typed "a" with iw_ti focused

-- luna.wheelmoved: forward scroll wheel to the hovered scroll panel / list
imgCtx:wheelmoved(0, -3)        -- scroll down 3 units

-- luna.process(dt): advance any animated widgets (e.g. progress bars, toasts)
imgCtx:update(0.016)            -- call every frame with delta-time

--------------------------------------------------------------------------------
-- Menu_Bar  (top-level application menu strip)
--------------------------------------------------------------------------------
-- Menu_Bar sits at the top of an application window and holds drop-down menus.
-- Each menu is created with addMenu(title) which returns a Menu object you can
-- populate with MenuItem instances. removeMenu() removes a menu by its title.

local menubar2  = luna.ui.newMenuBar()
local file_menu = menubar2:addMenu("File")   -- → Menu object
local edit_menu = menubar2:addMenu("Edit")   -- → Menu object
local view_menu = menubar2:addMenu("View")

-- Remove a menu that is no longer relevant
menubar2:removeMenu("View")

-- Inspect the current menu list
local menus_arr = menubar2:getMenus()         -- {file_menu, edit_menu}
local menu_cnt  = menubar2:getMenuCount()     -- → 2

--------------------------------------------------------------------------------
-- Menu_Item  (command entry with optional shortcut and sub-menu)
--------------------------------------------------------------------------------
-- Menu items are placed inside Menu objects. getText/setText control the label.
-- setShortcut sets the keyboard accelerator shown at the right of the entry.
-- addSubItem builds a cascading sub-menu; getSubItems returns the sub-list.

local run_item  = luna.ui.newMenuItem("Run")
run_item:setText("Run Script")               -- rename label after creation
local cur_label = run_item:getText()         -- → "Run Script"

local cur_key   = run_item:getShortcut()     -- → "" (no shortcut yet)
run_item:setShortcut("Ctrl+R")               -- show "Ctrl+R" at entry right

-- Cascading sub-menu: "Run ▶  Step Into / Step Over / Continue"
local sub_into  = luna.ui.newMenuItem("Step Into")
local sub_over  = luna.ui.newMenuItem("Step Over")
local sub_cont  = luna.ui.newMenuItem("Continue")
sub_cont:setShortcut("F5")

run_item:addSubItem(sub_into)
run_item:addSubItem(sub_over)
run_item:addSubItem(sub_cont)

local sub_list  = run_item:getSubItems()     -- {sub_into, sub_over, sub_cont}

-- Attach a click handler — fires when the user selects the item
run_item:setOnClick(function()
    luna.log.info("Running script…")
end)

-- Add the item to the File menu
file_menu:addItem(run_item)

--------------------------------------------------------------------------------
-- Status_Bar  (multi-section information strip)
--------------------------------------------------------------------------------
-- Status_Bar sits at the bottom of a window and shows non-interactive live
-- data. addSection(label) appends a new slot. setSectionText(idx, text) updates
-- a slot at runtime (1-based index). Use it for mode indicators, coordinates,
-- error summaries, or FPS counters.

local sbar = luna.ui.newStatusBar()
sbar:addSection("Mode")         -- section 1
sbar:addSection("Position")     -- section 2
sbar:addSection("")             -- section 3  (right-aligned, initially blank)

-- Update sections at runtime (e.g. inside luna.process)
sbar:setSectionText(1, "Normal")              -- "Mode: Normal"
sbar:setSectionText(2, "x=320  y=240")        -- live cursor position
sbar:setSectionText(3, "FPS: 60")             -- right-aligned perf counter

local st_text = sbar:getSectionText(1)        -- → "Normal"
local st_n    = sbar:getSectionCount()        -- → 3

--------------------------------------------------------------------------------
-- Tooltip_Panel  (hover tooltip with configurable delay and target widget)
--------------------------------------------------------------------------------
-- Create a Tooltip_Panel, set its text and delay, then pin it to a widget with
-- setTarget. When the pointer hovers over the target widget for longer than the
-- delay, the tooltip appears automatically. setTarget(nil) detaches it.

local ttp2       = luna.ui.newTooltipPanel()

-- How long the pointer must dwell before the tooltip appears (seconds)
local ttp_delay  = ttp2:getDelay()            -- → 0.5 (default)
ttp2:setDelay(0.4)                            -- snappier tooltip

-- Pin to a specific widget so it positions relative to that widget's bounds
local ttp_target = ttp2:getTarget()           -- → nil (not yet pinned)
ttp2:setTarget(run_item)                      -- tooltip follows run_item

-- The text shown inside the tooltip popup
local ttp_txt    = ttp2:getText()             -- → "" (empty until set)
ttp2:setText("Run the current script (Ctrl+R)")

-- Detach from current target without destroying the tooltip
-- ttp2:setTarget(nil)

--------------------------------------------------------------------------------
-- Widget base API  (supplemental methods — all apply to every widget type)
--------------------------------------------------------------------------------
-- addChild/removeChild attach or detach a widget from the tree at runtime (for
-- dynamic layouts). findById("id") searches the whole tree for a widget whose
-- id was set with setId(). containsPoint(x, y) is useful for custom drag-drop
-- hit-testing. clearAnchor() removes a stretch anchor previously set via
-- setAnchor() so the widget reverts to manual position/size.

luna.gui.addChild(iw_lbl)                     -- re-attach a previously removed child
local found_wg  = luna.gui.findById("main_hud")    -- nil if no match
local in_bounds = luna.gui.containsPoint(150, 80)  -- true when (150,80) inside widget
luna.gui.clearAnchor()                        -- stop stretching, return to manual size

