-- main.lua: catch all unhandled errors before the engine error screen
function lurek.errorhandler(msg)
    -- Log to file + console before showing error screen
    print("UNHANDLED ERROR: " .. tostring(msg))
    lurek.fs.append("errors.log", msg .. "\n")
    return msg   -- return the message to display on error screen
end
