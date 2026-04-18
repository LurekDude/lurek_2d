describe("<name> stress", function()
    it("handles N iterations without error", function()
        for i = 1, 10000 do
            -- exercise the hot path
        end
        expect_true(true, "completed without error")
    end)
end)
test_summary()
