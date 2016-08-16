
--This is a basic implementation of filebrowser for Scite. Control comes true through the output panel.

-- SciteFileBrwoser.lua
-- 15.06.2012
-- apasejkin at interzet dot ru

local cmd, dir, pat, up, sep, begPos, endPos

if props['PLAT_WIN'] == '1' then
    cmd = 'dir /b /o /a:-h '
    sep = '\\'
    pat = '\\[^\\]+$'
elseif props['PLAT_GTK'] == '1' then
    cmd = 'ls -1v'
    sep = '/'
    pat = '/[^/]+$'
end
up = '[..]'

local function updateContent()
    if begPos and endPos then
        output:remove(begPos, endPos)
    end
    begPos = output.CurrentPos
    local content = io.popen(cmd..'"'..dir..sep..'"')
    print(dir..sep)
    print(up)
    print(content:read '*a')
    content:close()
    endPos = output.CurrentPos
end

function createContent()
    dir = props['FileDir']
    updateContent()
end

local oldOnDoubleClick = OnDoubleClick or function()end
function OnDoubleClick()
    oldOnDoubleClick()
    local name, path
    name = output:GetCurLine():sub(1, -2)
    if not dir
    or not output.Focus
    or name == '' or name == dir..sep
    or endPos <= output.CurrentPos
    or output.CurrentPos <= begPos then
        return
    end
    if name == up then
        path = dir:gsub(pat, '')
    else
        path = dir..sep..name
    end
    local file = io.open(path)
    if io.type(file) then
        file:close()
        scite.Open(path)
    else
        dir = path
        updateContent()
    end
end

--To configure it type in your *.properties file the following:

--command.name.3.*=FileBrowser
--command.mode.3.*=subsystem:lua,savebefore:no
--command.3.*=dostring createContent()

