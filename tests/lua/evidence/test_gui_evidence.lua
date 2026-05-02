-- Evidence tests: gui module
-- Produces PNG artifacts from lurek.ui layout rendering.

describe("evidence: gui", function()
    before_each(function()
        ensure_evidence_dir("gui")
    end)

    -- @evidence file
    it("renders a basic vertical layout to PNG", function()
        local dir  = evidence_output_dir("gui")
        local path = dir .. "basic_layout.png"
        lurek.ui.loadLayout({
            type = "layout",
            direction = "vertical",
            padding = 10,
            children = {
                { type = "label",  text = "Hello, Lurek2D!" },
                { type = "button", text = "Click Me", id = "btn1" },
                { type = "slider", min = 0, max = 100, value = 42, id = "sl1" },
            },
        })
        lurek.ui.renderToImage(320, 200, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders a horizontal two-panel layout to PNG", function()
        local dir  = evidence_output_dir("gui")
        local path = dir .. "horizontal_layout.png"
        lurek.ui.loadLayout({
            type = "layout",
            direction = "horizontal",
            padding = 8,
            children = {
                {
                    type = "panel",
                    width = 140,
                    children = {
                        { type = "label",  text = "Left Panel" },
                        { type = "button", text = "Option A" },
                        { type = "button", text = "Option B" },
                    },
                },
                {
                    type = "panel",
                    children = {
                        { type = "label", text = "Right Panel" },
                        { type = "label", text = "Details here." },
                    },
                },
            },
        })
        lurek.ui.renderToImage(480, 240, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("renders a form layout with multiple widget types to PNG", function()
        local dir  = evidence_output_dir("gui")
        local path = dir .. "form_layout.png"
        lurek.ui.loadLayout({
            type = "layout",
            direction = "vertical",
            padding = 12,
            children = {
                { type = "label",    text = "User Settings" },
                { type = "checkbox", text = "Enable sound",  checked = true  },
                { type = "checkbox", text = "Full screen",   checked = false },
                { type = "slider",   min = 0, max = 10, value = 7, id = "vol" },
                { type = "button",   text = "Save",   id = "save"   },
                { type = "button",   text = "Cancel", id = "cancel" },
            },
        })
        lurek.ui.renderToImage(360, 280, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
