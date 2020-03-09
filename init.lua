------- delay 1s, init LFS, do main.lua ----------
do 
    -- wait a second to start, avoid non-stoppable restart-loop if something wrong
    tmr.create():alarm(500, tmr.ALARM_SINGLE,
        function()
            if file.exists("flash.img") then
                file.remove("flash.old")
                file.rename("flash.img", "flash.old")
                node.flashreload('flash.old')
                node.restart()
            end
                
            ---- init with no wifi, no enduser_setup
            enduser_setup.manual(true)
            wifi.setmode(wifi.NULLMODE, false)

            local fi=node.flashindex
            local ok,err=pcall(fi('_init'))
            if ok and file.exists("cfg.lua") then ok,err=pcall(dofile, "cfg.lua") end
            if ok  then ok,err=pcall(dofile, "main.lua") end
            if err then print(err) end
        end
    )
end

