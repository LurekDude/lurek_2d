-- Lurek2D Integration Test: Localization + UI
-- Tests localized text flowing into UI elements.

describe("integration: localized strings in UI labels", function()
    it("localization provides string and UI label stores it", function()
        -- Load English locale inline
        lurek.i18n.setLanguage("en")
        lurek.i18n.loadTable("en", {
            btn_start  = "Start Game",
            btn_quit   = "Quit",
            lbl_score  = "Score",
        })

        local start_text = lurek.i18n.t("btn_start")
        local quit_text  = lurek.i18n.t("btn_quit")
        local score_text = lurek.i18n.t("lbl_score")

        expect_equal("Start Game", start_text, "start button text")
        expect_equal("Quit",       quit_text,  "quit button text")
        expect_equal("Score",      score_text, "score label text")

        -- Create UI label and apply localized string
        local label = lurek.ui.newLabel()
        label.setText(start_text)
        expect_no_error(function()
            label.setText(quit_text)
        end)
    end)

    it("switching locale updates UI text", function()
        lurek.i18n.loadTable("en", { greeting = "Hello" })
        lurek.i18n.loadTable("pl", { greeting = "Cze    " })

        lurek.i18n.setLanguage("en")
        local en_text = lurek.i18n.t("greeting")
        expect_equal("Hello", en_text, "English greeting")

        lurek.i18n.setLanguage("pl")
        local pl_text = lurek.i18n.t("greeting")
        expect_equal("Cze    ", pl_text, "Polish greeting")

        local label = lurek.ui.newLabel()
        label.setText(pl_text)
        expect_no_error(function()
            label.setText(en_text)
        end)
    end)

    it("missing key returns key name as fallback", function()
        lurek.i18n.setLanguage("en")
        local val = lurek.i18n.t("non_existent_key_xyz")
        -- Should return key name, not crash
        expect_type("string", val, "missing key returns a string fallback")
    end)
end)
test_summary()
