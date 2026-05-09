# IDEA — src/input

## Niezrobione TODO/WIP

- TODO(FEAT): dodać callbacki Lua dla hot-plug gamepadów (connect/disconnect event), nie tylko polling stanu.
- TODO(TEST-FUZZ): dodać fuzz target dla parsera `GamepadMappings::load_from_string` (uszkodzone mapowania SDL).
- TODO(dedup): doprecyzować granicę między przechwytywaniem eventów w `event` i `input::recorder`.
- TODO(dedup): ujednolicić odpowiedzialność za kursor (`window` vs `input::mouse`).
- TODO(helper): helper `virtual_dpad` dla gier opartych o dotykowe sterowanie ekranowe.
