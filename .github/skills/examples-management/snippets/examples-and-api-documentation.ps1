# Check that all lurek.* calls in content/examples/ are documented in api_data.json
python tools/docs/gen_lua_api.py --check

# Generate Lua API reference including usage patterns from examples
python tools/docs/gen_lua_api.py
