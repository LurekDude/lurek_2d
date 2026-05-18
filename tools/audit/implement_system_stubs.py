"""Implement lurek.system.* stub blocks in system.lua (flat format, no separators)."""
import re, os

path = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..',
                                     'content', 'examples', 'system.lua'))

with open(path, encoding='utf-8') as f:
    content = f.read()

IMPLS = {
    'getOS': 'do\n  local os_name = lurek.system.getOS()\n  local mod_key = (os_name == "macOS") and "cmd" or "ctrl"\n  lurek.log.info("OS: " .. os_name .. " modifier: " .. mod_key, "system")\nend',
    'getVersion': 'do\n  local v = lurek.system.getVersion()\n  lurek.log.info("engine version: " .. v, "system")\nend',
    'getProcessorCount': 'do\n  local cores = lurek.system.getProcessorCount()\n  lurek.log.info("logical CPUs: " .. cores, "system")\nend',
    'getMemorySize': 'do\n  local mb = lurek.system.getMemorySize()\n  lurek.log.info("RAM: " .. mb .. " MiB", "system")\nend',
    'openURL': 'do\n  assert(type(lurek.system.openURL) == "function", "openURL must be callable")\n  lurek.log.info("openURL available", "system")\nend',
    'getPreferredLocales': 'do\n  local locales = lurek.system.getPreferredLocales()\n  lurek.log.info("preferred locale: " .. tostring(locales[1]), "system")\nend',
    'getPowerInfo': 'do\n  local pwr = lurek.system.getPowerInfo()\n  lurek.log.info("power: " .. tostring(pwr), "system")\nend',
    'getInfo': 'do\n  local info = lurek.system.getInfo()\n  lurek.log.info("engine info loaded", "system")\nend',
    'getMessage': 'do\n  local cnt = lurek.system.getMessageCount()\n  if cnt and cnt > 0 then\n    local msg = lurek.system.getMessage(1)\n    lurek.log.info("msg 1: " .. tostring(msg), "system")\n  end\nend',
    'hasMessage': 'do\n  local has = lurek.system.hasMessage(1)\n  lurek.log.debug("has message 1: " .. tostring(has), "system")\nend',
    'getMessageCount': 'do\n  local n = lurek.system.getMessageCount()\n  lurek.log.info("message count: " .. tostring(n), "system")\nend',
    'setClipboardText': 'do\n  lurek.system.setClipboardText("Copied!")\n  lurek.log.info("text copied to clipboard", "system")\nend',
    'getClipboardText': 'do\n  lurek.system.setClipboardText("hello")\n  local text = lurek.system.getClipboardText()\n  lurek.log.info("clipboard: " .. tostring(text), "system")\nend',
    'reloadConfig': 'do\n  lurek.system.reloadConfig()\n  lurek.log.info("config reload scheduled", "system")\nend',
    'getConfig': 'do\n  local cfg = lurek.system.getConfig()\n  lurek.log.info("config loaded", "system")\nend',
    'setDebugOverlay': 'do\n  lurek.system.setDebugOverlay(false)\n  lurek.log.debug("overlay off", "system")\n  lurek.system.setDebugOverlay(true)\nend',
    'getDebugOverlay': 'do\n  local on = lurek.system.getDebugOverlay()\n  lurek.log.debug("overlay: " .. tostring(on), "system")\nend',
    'setLogLevel': 'do\n  lurek.system.setLogLevel("debug")\n  lurek.log.debug("log level set to debug", "system")\nend',
    'getLogLevel': 'do\n  lurek.system.setLogLevel("info")\n  local level = lurek.system.getLogLevel()\n  lurek.log.debug("log level: " .. level, "system")\nend',
    'log': 'do\n  lurek.system.log("info", "hello from lurek.system.log")\nend',
    'getLastError': 'do\n  local err = lurek.system.getLastError()\n  lurek.log.debug("last error: " .. tostring(err), "system")\nend',
    'errorSnapshot': 'do\n  local snap = lurek.system.errorSnapshot("test_error")\n  lurek.log.debug("snapshot: " .. tostring(snap ~= nil), "system")\nend',
    'getArch': 'do\n  local arch = lurek.system.getArch()\n  lurek.log.info("CPU arch: " .. arch, "system")\nend',
    'getEnv': 'do\n  local val = lurek.system.getEnv("PATH")\n  lurek.log.debug("PATH defined: " .. tostring(val ~= nil), "system")\nend',
    'getArgs': 'do\n  local args = lurek.system.getArgs()\n  lurek.log.info("arg count: " .. #args, "system")\nend',
    'parseArgs': 'do\n  local parsed = lurek.system.parseArgs({"--width=1280", "--fullscreen"})\n  lurek.log.info("parseArgs done", "system")\nend',
    'runBatch': 'do\n  local results = lurek.system.runBatch({\n    check_os = function() return lurek.system.getOS() ~= nil end,\n  })\n  lurek.log.info("batch done", "system")\nend',
    'getBatchResults': 'do\n  local results = lurek.system.runBatch({\n    always_pass = function() return true end,\n  })\n  local summary = lurek.system.getBatchResults(results)\n  lurek.log.info("batch summary: " .. tostring(summary), "system")\nend',
}

STUB_PAT = re.compile(
    r'(--@api-stub: lurek\.system\.(\w+)\n'   # (1) header, (2) method
    r'-- [^\n]+\n)'                            # description line
    r'-- TODO:[^\n]+\n'
    r'(?:-- [^\n]+\n)*'                        # extra comment lines
    r'lurek\.system\.\w+[^\n]*\n'             # bare call line
)

replaced = 0
def replace(m):
    global replaced
    method = m.group(2)
    header = m.group(1)
    impl = IMPLS.get(method)
    if impl is None:
        print(f'  MISSING impl: {method}')
        return m.group(0)
    replaced += 1
    return header + impl + '\n'

new = STUB_PAT.sub(replace, content)
print(f'Replaced: {replaced}')
print(f'Remaining TODO: {new.count("-- TODO:")}')

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(new)
print('Written.')
