function lurek.init()
    local args = lurek.platform.getArgs()
    if args["--smoke"] then
        lurek.signal.quit()
    end
end
