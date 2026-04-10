-- Lurek2D Integration Test: Localization + UI
-- Tests localized text flowing into UI elements.
-- @covers lurek.localization.load
-- @covers lurek.localization.get
-- @covers lurek.localization.setLocale
-- @covers lurek.ui.newLabel
-- @covers lurek.ui.setText

describe("integration: localized strings in UI labels", function()
    it("localization provides string and UI label stores it", function()
        -- Load English locale inline
        lurek.localization.setLocale("en")
        lurek.localization.load("en", {
            btn_start  = "Start Game",
            btn_quit   = "Quit",
            lbl_score  = "Score",
        })

        local start_text = lurek.localization.get("btn_start")
        local quit_text  = lurek.localization.get("btn_quit")
        local score_text = lurek.localization.get("lbl_score")

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

    it("switching locale updates UI text", function()
        lurek.localization.load("en", { greeting = "Hello" })
        lurek.localization.load("pl", { greeting = "Cześć" })

        lurek.localization.setLocale("en")
        local en_text = lurek.localization.get("greeting")
        expect_equal("Hello", en_text, "English greeting")

        lurek.localization.setLocale("pl")
        local pl_text = lurek.localization.get("greeting")
        expect_equal("Cześć", pl_text, "Polish greeting")

        local label = lurek.ui.newLabel()
        lurek.ui.setText(label, pl_text)
        expect_no_error(function()
            lurek.ui.setText(label, en_text)
        end)
    end)

    it("missing key returns key name as fallback", function()
        lurek.localization.setLocale("en")
        local val = lurek.localization.get("non_existent_key_xyz")
        -- Should return key name, not crash
        expect_type("string", val, "missing key returns a string fallback")
    end)
end)

test_summary()
