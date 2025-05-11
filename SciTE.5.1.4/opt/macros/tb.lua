local ok, mod = pcall(require, "w32tb")
if not ok then
    print("Error loading:", mod)
else
    print("DLL says:", mod.msg)
end



-- Load the DLL (this triggers DllMain, which subclasses SciTE)
local ok,err = pcall(function() require("w32tb") end)
if not ok then
    print("Failed to load w32tb.dll : ",err)
    return
end

if not Create("Hallo",100,80) then
	print ("Failed to Create Toolbar")
end

-- Toolbar constants
local button_id_1 = 101
local button_id_2 = 102

-- Add buttons (icon or text)
AddTextButton("Say Hi", button_id_1, "Greet the user")
AddTextButton("Exit", button_id_2, "Close SciTE")

-- Callback from the DLL's subclassed message handler
function handleToolbarButtonClick(id)
    if id == button_id_1 then
        print("Hello from the toolbar!")
        scite.SendEditor(SCI_INSERTTEXT, 0, "Hello from toolbar!\n")
    elseif id == button_id_2 then
        print("Exiting SciTE.")
        os.exit()
    else
        print("Unhandled button ID: " .. tostring(id))
    end
end
