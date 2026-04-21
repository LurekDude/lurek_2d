function lurek.init()
    local args = lurek.runtime.getArgs()
    if args["--smoke"] then
        lurek.event.quit()
    end
end
