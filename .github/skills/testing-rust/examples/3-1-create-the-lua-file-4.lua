-- Template: replace <name>, <module>, <fn> with real values.
describe("<name> contract", function()
    it("rejects invalid argument type", function()
        expect_error(function()
            lurek.mymodule.myfunc("not_a_number")
        end)
    end)
end)
test_summary()
