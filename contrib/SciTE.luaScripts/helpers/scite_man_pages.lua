

    -- Compatibility: Lua-5.1
    function man_select(sel)
        sel=string.gsub(sel, '[<> ,*()\n\t]','')
        local ext = props['FileExt']
        -- open lua manual on selected word
        if(ext=="lua") then -- todo: customize help for each file type
            os.execute("gnome-terminal -e 'lynx \"file:///usr/share/doc/lua-5.1.4/manual.html#pdf-"..sel.."\"'")
        else -- open c manual on selected word
            local tmpfile="/tmp/man_"..sel..".c"
            local cmd="man "..sel..">/dev/null&&man -S 3:3p:2:2p:4:5:6:7:8:0p:1:1p "..sel.."|col -b > "..tmpfile
            if Execute then
                Execute(cmd)
            else
                os.execute(cmd)
            end
            if(io.open(tmpfile)) then
                scite.Open(tmpfile)
                os.remove(tmpfile)
            end
        end
    end

