-- tests/lua/unit/test_serial_xml.lua
-- BDD tests for lurek.codec.decodeXml

describe("lurek.codec.decodeXml", function()
  it("parses a simple element", function()
    local xml = "<root/>"
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.tag, "root")
  end)

  it("captures text content", function()
    local xml = "<greeting>Hello World</greeting>"
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.tag, "greeting")
    expect_equal(tbl.text, "Hello World")
  end)

  it("captures attributes", function()
    local xml = '<player id="1" name="hero"/>'
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.tag, "player")
    expect_equal(tbl.attrs.id, "1")
    expect_equal(tbl.attrs.name, "hero")
  end)

  it("captures child elements", function()
    local xml = "<items><item>sword</item><item>shield</item></items>"
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.tag, "items")
    expect_equal(#tbl.children, 2)
    expect_equal(tbl.children[1].tag, "item")
    expect_equal(tbl.children[1].text, "sword")
    expect_equal(tbl.children[2].text, "shield")
  end)

  it("omits attrs table when element has no attributes", function()
    local xml = "<root><child/></root>"
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.attrs, nil)
    expect_equal(tbl.children[1].attrs, nil)
  end)

  it("omits children table when element has no child elements", function()
    local xml = "<leaf>text</leaf>"
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.children, nil)
  end)

  it("handles a nested document", function()
    local xml = [[<map version="1"><layer name="ground"><tile id="3"/></layer></map>]]
    local tbl = lurek.codec.decodeXml(xml)
    expect_equal(tbl.tag, "map")
    expect_equal(tbl.attrs.version, "1")
    local layer = tbl.children[1]
    expect_equal(layer.tag, "layer")
    expect_equal(layer.attrs.name, "ground")
    expect_equal(layer.children[1].tag, "tile")
    expect_equal(layer.children[1].attrs.id, "3")
  end)

  it("errors on malformed XML", function()
    expect_error(function() lurek.codec.decodeXml("<unclosed") end)
  end)

  it("errors on mismatched tags", function()
    expect_error(function() lurek.codec.decodeXml("<a></b>") end)
  end)
end)

test_summary()
