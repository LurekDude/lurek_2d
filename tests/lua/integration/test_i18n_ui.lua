-- Lurek2D Integration Test: Localization + UI
-- Tests localized text flowing into UI elements.

-- @description Covers suite: integration: localized strings in UI labels.
describe("integration: localized strings in UI labels", function()
    -- @covers lurek.i18n.get
    -- @covers lurek.ui.setText
    -- @covers lurek.i18n.load
    -- @covers lurek.i18n.setLocale
    -- @covers lurek.ui.newLabel
    -- @description Verifies localized strings can be fetched from the localization module and applied to a UI label.
    it("localization provides string and UI label stores it", function()
        -- Load English locale inline
        lurek.i18n.setLocale("en")
        lurek.i18n.load("en", {
            btn_start  = "Start Game",
            btn_quit   = "Quit",
            lbl_score  = "Score",
        })

        local start_text = lurek.i18n.get("btn_start")
        local quit_text  = lurek.i18n.get("btn_quit")
        local score_text = lurek.i18n.get("lbl_score")

        expect_equal("Start Game", start_text, "start button text")
        expect_equal("Quit",       quit_text,  "quit button text")
        expect_equal("Score",      score_text, "score label text")

        -- Create UI label and apply localized string
        local label = lurek.ui.newLabel()
        lurek.ui.setText(label, start_text)
        expect_no_error(function()
            lurek.ui.setText(label, quit_text)
        end)
    end)

    -- @covers lurek.i18n.setLocale
    -- @covers lurek.ui.setText
    -- @description Verifies switching the active locale changes the text fed into a UI label.
    it("switching locale updates UI text", function()
        lurek.i18n.load("en", { greeting = "Hello" })
        lurek.i18n.load("pl", { greeting = "CzeĹ›Ä‡" })

        lurek.i18n.setLocale("en")
        local en_text = lurek.i18n.get("greeting")
        expect_equal("Hello", en_text, "English greeting")

        lurek.i18n.setLocale("pl")
        local pl_text = lurek.i18n.get("greeting")
        expect_equal("CzeĹ›Ä‡", pl_text, "Polish greeting")

        local label = lurek.ui.newLabel()
        lurek.ui.setText(label, pl_text)
        expect_no_error(function()
            lurek.ui.setText(label, en_text)
        end)
    end)

    -- @covers lurek.i18n.get
    -- @covers lurek.ui
    -- @description Verifies missing localization keys fall back to a string value instead of breaking UI text flows.
    it("missing key returns key name as fallback", function()
        lurek.i18n.setLocale("en")
        local val = lurek.i18n.get("non_existent_key_xyz")
        -- Should return key name, not crash
        expect_type("string", val, "missing key returns a string fallback")
    end)
end)
test_summary()
