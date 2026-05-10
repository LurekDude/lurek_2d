-- Integration: i18n text source serialized with data and consumed by UI layout.
-- @describe integration: ui + i18n + data
describe("integration: ui + i18n + data", function()
    -- @integration lurek.data.pack
    -- @integration lurek.data.unpack
    -- @integration lurek.i18n.loadTable
    -- @integration lurek.i18n.setLanguage
    -- @integration lurek.i18n.t
    -- @integration lurek.ui.loadLayout
    it("builds a localized UI label from serialized bytes", function()
        local src = "Hello"
        local packed = lurek.data.pack("s", src)
        local title = lurek.data.unpack("s", packed)
        expect_equal("Hello", title, "packed text should roundtrip")

        lurek.i18n.loadTable("en", { ui_title = title })
        lurek.i18n.setLanguage("en")
        local localized = lurek.i18n.t("ui_title")
        expect_equal("Hello", localized, "localized text should resolve")

        local root = lurek.ui.loadLayout({
            type = "panel",
            children = {
                { type = "label", text = localized },
            },
        })

        expect_type("number", root, "ui layout should return root id")
    end)
end)

test_summary()
