-- Sidebar for SciTE v0.3 (Lua version)
-- (c) Valentin Schmidt 2016

require 'bit'
require 'ftp'
require 'ini'
require 'io'
require 'math'
require 'os'
require 'qtcore'
require 'qtgui'
require 'scite'
require 'utils'
require 'winapi'
require 'winapiex'

-- settings
local sidebarSettings

-- path to sidebar folder
local sidebarDir

-- maps tab name to tab index in tabWidget
local tabMap

-- windows / hwnds
local winSidebar
local hwndSidebar
local winScite
local hwndScite
local winScintilla

-- core widgets
local dialog
local tabWidget

-- widgets in tabs
local explorerTree
local ftpTree
local functionList
local bookmarkList
local projectTree

-- button widgets
local projectEditBtn
local projectPublishMacBtn
local projectPublishWinBtn

-- ftp vars
local ftpAccounts

-- sidebar's TMP subfolder used for editing files on FTP servers
local tmpDir

-- map that associates temporary FTP downloads with their origin
local tmpFileMap

-- project vars
local projectCurrentFile
local projectCurrentSettings
local projectCurrentPath
local projectCurrentPublishDir

-- publish process
local publishProc

-- system metrics
local CXSIZEFRAME
local CYSIZEFRAME
local CXVSCROLL
local CYCAPTION
local CYBORDER

----------------------------------------
-- Get icon for file/folder
----------------------------------------
local function getIcon (filename, flagMightExist)

  if filename=="folder" then return QFileIconProvider():icon(QFileIconProvider.IconType.Folder) end

  -- try to get icon from existing file?
  if flagMightExist==true then
    local ico = QFileIconProvider():icon(QFileInfo(filename))
    if not ico:isNull() then return ico end
  end

  local pixmap = QPixmap()

  if filename=='server' then
    if not QPixmapCache.find("server", pixmap) then
      pixmap = QPixmap(sidebarDir.."icons/server.png")
      QPixmapCache.insert("server", pixmap)
    end
    return QIcon(pixmap)
  end

  local fileType = QFileInfo(filename):suffix():toUtf8() -- "png"

  if not QPixmapCache.find(fileType, pixmap) then
    local iconData = winapiex.getIconForFileType(fileType)
    pixmap:loadFromData(iconData, "bmp")
    QPixmapCache.insert(fileType, pixmap)
  end

  return QIcon(pixmap)

end

----------------------------------------
-- Loads explorer.ini
----------------------------------------
local function loadExplorerIni ()
  local info = ini.load(sidebarDir.."explorer.ini")
  local root = info.Settings.root
  if root==nil then root="My Computer" end
  local model = QFileSystemModel.new()
  model:setRootPath(root)
  explorerTree:setModel(model)
  explorerTree:setRootIndex(model:index(root))
end

----------------------------------------
-- Loads functions.ini
----------------------------------------
local function loadFunctionsIni ()
  local info = ini.load(sidebarDir.."functions.ini")
  sidebarSettings.Sidebar.functions_sort = info.Settings.sort=="1"
end

----------------------------------------
-- Loads bookmarks.ini
----------------------------------------
local function loadBookmarksIni ()

  -- remove previous bookmarks
  bookmarkList:clear()

  local info, keys = ini.load(sidebarDir.."bookmarks.ini")
  local bookmarks = info["Bookmarks"]

  if bookmarks==nil then return end

  -- keeping original order
  local path
  for _,name in pairs(keys["Bookmarks"]) do
    path = bookmarks[name]
    listItem = QListWidgetItem.new()
    listItem:setText(name)
    listItem:setData(Qt.ItemDataRole.UserRole, path)

    -- icon
    local ico = getIcon(path, true)
    if not ico:isNull() then listItem:setIcon(ico) end

    bookmarkList:addItem(listItem)
  end

end

----------------------------------------
-- Loads ftp.ini
----------------------------------------
local function loadFtpIni ()

  -- remove previous account nodes
  local root = ftpTree:invisibleRootItem()

  local cnt = root:childCount()
  if cnt>0 then
    for i = cnt, 1, -1 do
      root:removeChild(root:child(i-1))
    end
  end

  ftpAccounts = ini.load(sidebarDir.."ftp.ini")
  if ftpAccounts==nil then return end

  for name,account in pairs(ftpAccounts) do

    local home = account["home"]
    if home==nil then
      account["home"] = "/"
    elseif home:sub(-1)~="/" then --.char[h.length then
      account["home"] = home.."/"
    end

    childTreeItem = QTreeWidgetItem.new()
    childTreeItem:setData(0, Qt.ItemDataRole.UserRole, 2) -- was 0!
    childTreeItem:setText(0, name)

    -- icon
    local ico = getIcon("server")
    if not ico:isNull() then childTreeItem:setIcon(0, ico) end

    ftpTree:addTopLevelItem(childTreeItem)

  end

  -- sort alphabetically
  ftpTree:sortItems(0, 0)

end

----------------------------------------
-- Loads .project file into projects tab
----------------------------------------
local function loadProject (projectFile)

  projectCurrentFile = projectFile
  projectCurrentPath = getPath(projectCurrentFile)

  -- remove previous project
  local root = projectTree:invisibleRootItem()
  local cnt = root:childCount()
  if cnt>0 then
    for i = cnt, 1, -1 do
      root:removeChild(root:child(i-1))
    end
  end

  -- read project settings
  projectCurrentSettings = ini.load(projectCurrentFile)
  if projectCurrentSettings==nil then return end

  projectEditBtn:setDisabled(false)
  projectPublishMacBtn:setDisabled(projectCurrentSettings.PublishMac==nil)
  projectPublishWinBtn:setDisabled(projectCurrentSettings.PublishWin==nil)

  local projectTreeItem = QTreeWidgetItem.new()
  projectTreeItem:setText(0, projectCurrentSettings.Settings.Name)
  projectTree:addTopLevelItem(projectTreeItem)
  projectTreeItem:setExpanded(true)

  -- groups (folders)
  local dirMap = {}

  for i,dir in ipairs(projectCurrentSettings.Group) do
    local parts = dir:split("/")
    local dirTreeItem = QTreeWidgetItem.new()
    dirTreeItem:setText(0, parts[#parts])
    dirTreeItem:setData(0, Qt.ItemDataRole.UserRole, projectCurrentPath..dir.."\\")

    -- icon
    local ico = getIcon('folder')
    if not ico:isNull() then dirTreeItem:setIcon(0, ico) end

    if #parts>1 then
      table.remove(parts)
      parentTreeItem = dirMap[join(parts, "/")]
      parentTreeItem:addChild(dirTreeItem)
    else
      projectTreeItem:addChild(dirTreeItem)
    end

    dirMap[dir] = dirTreeItem

  end

  -- files in root folder
  for i,f in ipairs(projectCurrentSettings.Files) do
    local fileTreeItem = QTreeWidgetItem.new()
    fileTreeItem:setText(0, f) -- name
    fileTreeItem:setData(0, Qt.ItemDataRole.UserRole, QVariant(projectCurrentPath..f))

    -- icon
    local ico = getIcon(projectCurrentPath..f, true)
    if not ico:isNull() then fileTreeItem:setIcon(0, ico) end

    projectTreeItem:addChild(fileTreeItem)
  end

  -- files in subfolders (groups)
  for dir,item in pairs(dirMap) do
    if projectCurrentSettings["Files "..dir]~=nil then
      for i,f in ipairs(projectCurrentSettings["Files "..dir]) do

        local fileTreeItem = QTreeWidgetItem.new()
        fileTreeItem:setText(0, f) -- name
        fileTreeItem:setData(0, Qt.ItemDataRole.UserRole, projectCurrentPath..dir.."\\"..f)

        -- icon
        local ico = getIcon(projectCurrentPath..dir.."\\"..f, true)
        if not ico:isNull() then fileTreeItem:setIcon(0, ico) end

        item:addChild(fileTreeItem)
      end
    end
  end

end

----------------------------------------
-- Shows selected treeWidgetItem in "FTP/SFTP" tab
----------------------------------------
local function showFtpResult (treeWidgetItem, folders, files)

  -- folders
  for i,f in ipairs(folders) do
    local childTreeItem = QTreeWidgetItem.new()
    childTreeItem:setText(0, f)
    childTreeItem:setData(0, Qt.ItemDataRole.UserRole, 0) -- store in item if file (1) or folder (0)

    -- icon
    local ico = getIcon("folder")
    if not ico:isNull() then childTreeItem:setIcon(0, ico) end

    treeWidgetItem:addChild(childTreeItem)
  end

  -- files
  for i,f in ipairs(files) do
    local childTreeItem = QTreeWidgetItem.new()
    childTreeItem:setText(0, f)
    childTreeItem:setData(0, Qt.ItemDataRole.UserRole, 1) -- store in item if file (1) or folder (0)

    -- icon
    local ico = getIcon(f)
    if not ico:isNull() then childTreeItem:setIcon(0, ico) end

    treeWidgetItem:addChild(childTreeItem)
  end

  -- expand
  --treeWidgetItem:setExpanded(true) -- not working

  -- => use timer?
  treeWidgetUpdateTimer = QTimer.new()
  treeWidgetUpdateTimer:setSingleShot(true)
  treeWidgetUpdateTimer:connect("2timeout()", function()
    treeWidgetItem:setExpanded(true)
  end)
  treeWidgetUpdateTimer:start(100)

end

----------------------------------------
--
----------------------------------------
local function showInSidebarExplorer (fn)

  tabWidget:setCurrentIndex(0) -- OK
  local model = explorerTree:model()
  local index = model:index(fn)
  explorerTree:setExpanded(index, true)
  explorerTree:setCurrentIndex(index)

  -- explorerTree:scrollTo(index, Qt.QAbstractItemView.PositionAtTop)
  -- to actually scroll to the directory, we need a timeout
  sidebarUpdateTimer = QTimer.new()
  sidebarUpdateTimer:setSingleShot(true)
  sidebarUpdateTimer:connect("2timeout()", function()
    explorerTree:scrollTo(index, 1) -- Qt.QAbstractItemView.PositionAtTop
  end)
  sidebarUpdateTimer:start(1000)
end

----------------------------------------
--
----------------------------------------
local function showTab (tabName)
  if tabMap[tabName]~=nil then
    tabWidget:setCurrentIndex(tabMap[tabName])
    winSidebar:show(4) -- SW_SHOWNOACTIVATE = 4
 end
end

----------------------------------------
-- must be global!
-- @callback
----------------------------------------
function slotMessage (hwnd, uMsg, wParam, lParam, data)

  if data==nil then return end

  -- remove :hwnd:
  local msg = data:sub(#(tostring(hwndSidebar))+3)

  -- functions:
  if msg:starts("functions:") then
    if sidebarSettings.Tabs.functions=="1" then
      msg = msg:sub(11)
      local functions = msg:split(",")
      if sidebarSettings.Sidebar.functions_sort then table.sort(functions) end

      -- update the function list
      functionList:clear()
      for i,str in ipairs(functions) do
        functionList:addItem(str)
      end
    end

  elseif msg:starts("closed:") then
    if sidebarSettings.Tabs.ftp=="1" then
      msg = msg:sub(8)
      if msg:starts(tmpDir.."\\") then

        -- remove from map
        if tmpFileMap[msg]~=nil then tmpFileMap[msg]=nil end

        -- delete associated tmp file and subfolder
        local dir = getPath(msg):sub(1, -2)
        winapi.execute('rmdir /s /q "'..dir..'"', 0)
      end
    end

  elseif msg:starts("saved:") then

    msg = msg:sub(7)
    local fn = msg

    if fn==sidebarDir.."explorer.ini" then
      -- explorer.ini was edited, reload Explorer tab
      loadExplorerIni()

    elseif fn==sidebarDir.."ftp.ini" then
      -- ftp.ini was edited, reload FTP tab
      loadFtpIni()

    elseif fn==sidebarDir.."bookmarks.ini" then
      -- bookmarks.ini was edited, reload bookmarks tab
      loadBookmarksIni()

    elseif fn==projectCurrentFile then
      -- current project INI was edited, reload projects tab
      loadProject(fn)

    elseif fn:starts(tmpDir.."\\") then
      -- FTP/SFTP tmp file was changed, upload changes to server
      local info = tmpFileMap[fn]
      if info~=nil then
        local acct = ftpAccounts[info.acct]

        local ftp = Ftp:new()
        ftp:setHost(acct["protocol"], acct["host"], acct["user"], acct["pass"], acct["port"]) --, acct["key"])
        scite.put("Trying to connect to "..acct["host"].."...")

        local ok, err = ftp:upload(fn, acct["home"]..info.path)
        if ok then
          scite.put("File changes saved on server")
        else
          scite.err("Error saving file on server: "..err)
        end
      end
    end

  elseif msg:starts("show:") then
    msg = msg:sub(6)
    showInSidebarExplorer(msg)

  elseif msg:starts("showTab:") then
    msg = msg:sub(9)
    showTab(msg)

  else
    scite.err("Unknown message received: "..msg)
  end

end

----------------------------------------
-- alternative: forward (all?) key events to SciTE?
-- @callback
----------------------------------------
local function slotKeyPress (code, modifiers) -- widget, code, modifier

  -- F7: publish for mac
  if code==16777270 and projectCurrentSettings["PublishMac"]~=nil then
    return slotPublishProjectMac()
  end

  -- F8: publish for win
  if code==16777271 and projectCurrentSettings["PublishWin"]~=nil then
    return slotPublishProjectWin()
  end

  -- Alt+E: hide Sidebar
  if code==69 and modifiers==4 then
    return winSidebar:show(winapi.SW_HIDE)
  end

  if code==69 and modifiers==5 then -- Alt+Shift+E
    return showTab("explorer")
  end
  if code==84 and modifiers==5 then -- Alt+Shift+T
    return showTab("ftp")
  end
  if code==70 and modifiers==5 then -- Alt+Shift+F
    return showTab("functions")
  end
  if code==66 and modifiers==5 then -- Alt+Shift+B
    return showTab("bookmarks")
  end
  if code==80 and modifiers==5 then -- Alt+Shift+P
    return showTab("projects")
  end

end

----------------------------------------
-- @callback
----------------------------------------
slotPublishComplete = function(exitCode)
  if exitCode==0 then
    scite.put("Project was succesfully published.")
    -- open in Windows Explorer?
    if projectSettings["openFolderAfterPublish"]=="1" then
      --shell_exec (verb, file, parms, dir, show)
      winapi.shell_exec(nil, "explorer.exe", projectCurrentPublishDir)
    end
  else
    scite.err("Errors occured while trying to publish: exitCode="..exitCode)
  end
end

----------------------------------------
-- @callback
----------------------------------------
local function slotPublishProjectMac ()

  -- just in case
  if publishProc~=nil then publishProc:kill() end

  scite.cmd("extender:onClearOutput")

  local publishSettings = projectCurrentSettings["PublishMac"]
  local bat = sidebarDir.."publish\\modules\\"..projectCurrentSettings["Type"].."\\make_mac.bat"

  if not fileExists(bat) then
    scite.err("No publish module found.")
    return false
  end

  local cmd = bat..'"'..projectCurrentSettings["Name"]..'"'

  local args = publishSettings["Args"]:split(" ")
  for i,arg in ipairs(args) do
    cmd = cmd..' "'..publishSettings[arg]..'"'
  end

  local f
  publishProc,f = winapi.spawn_process(cmd, projectCurrentPath)

  while true do
    str,err = f:read()
    if str==nil then break end
    scite.put(str)
  end

  local exitCode = publishProc:get_exit_code()

  projectCurrentPublishDir = projectCurrentPath.."..\\"..projectCurrentSettings.Settings.Name.."_standalone_mac"

  slotPublishComplete(exitCode)
end

----------------------------------------
-- @callback
----------------------------------------
local function slotPublishProjectWin (me)

  -- just in case
  if publishProc~=nil then publishProc:kill() end

  scite.cmd("extender:onClearOutput")

  local publishSettings = projectCurrentSettings["PublishWin"]
  local bat = sidebarDir.."publish\\modules\\"..projectCurrentSettings.Settings.Type.."\\make_win.bat"

  if not fileExists(bat) then
    scite.err("No publish module found.")
    return false
  end

  local cmd = bat..' "'..projectCurrentSettings.Settings.Name..'"'

  local args = publishSettings["Args"]:split(" ")
  for i,arg in ipairs(args) do
    cmd = cmd..' "'..publishSettings[arg]..'"'
  end

  local f
  publishProc,f = winapi.spawn_process(cmd, projectCurrentPath)

  while true do
    str,err = f:read()
    if str==nil then break end
    scite.put(str)
  end

  local exitCode = publishProc:get_exit_code()

  projectCurrentPublishDir = projectCurrentPath.."..\\"..projectCurrentSettings.Settings.Name.."_standalone_win"

  slotPublishComplete(exitCode)
end

----------------------------------------
-- Returns path (as lingo list) for specified treeWidgetItem
----------------------------------------
local function pathListFromTreeItem (treeWidgetItem)
  local pathList = {}
  local name
  local itemData

  while true do
    name = treeWidgetItem:text(0):toUtf8()
    table.insert(pathList, 1, name)

    -- check type
    itemData = treeWidgetItem:data(0, Qt.ItemDataRole.UserRole):toByteArray()
    if itemData=="2" then return pathList end -- account node

    treeWidgetItem = treeWidgetItem:parent()
  end
  return pathList
end

----------------------------------------
-- Re-position sidebar
-- @callback
----------------------------------------
local function repositionSidebar ()
  if not winScintilla:is_visible() then return end

  -- get scintilla rect
  local sx, sy = winScintilla:get_position()
  local sw, sh = winScintilla:get_bounds()

  local w = dialog:width()
  local h = sh - 2*CYSIZEFRAME + 2*CYBORDER
  local x = sx+sw - w - CXVSCROLL - CXSIZEFRAME
  local y = sy + CYSIZEFRAME - CYBORDER

  dialog:setGeometry(x, y, w, h)
  dialog:setFixedHeight(h)
end

----------------------------------------
-- START
----------------------------------------
local function __main () end -- just as editor marker (in function list)

app = QApplication.new(select('#',...) + 1, {'lua', ...})

----------------------------------------
-- get scite hwnds
----------------------------------------
winScite = winapi.find_window("SciTEWindow", nil)
hwndScite = winScite:get_handle()

winScintilla = scite.getScintilla()

----------------------------------------
-- init vars, load settings
----------------------------------------
sidebarDir = getPath( debug.getinfo(1, "S").source )
sidebarSettings = ini.load(sidebarDir.."sidebar.ini")

-- get number of activated tabs
local tabCnt = 0
for _,v in pairs(sidebarSettings.Tabs) do
  if v=="1" then tabCnt=tabCnt+1 end
end

tabMap = {}
tmpFileMap = {}

math.randomseed(os.time())

-- make sidebar tmp dir (and remove pevious tmp files)
tmpDir = os.getenv("TMP").."\\~sidebar"
winapi.execute('rmdir /s /q '..tmpDir..' & mkdir '..tmpDir, 0)
tmpDir = winapiex.getLongPathName(tmpDir)

-- get system metrics
CXSIZEFRAME = winapiex.getSystemMetrics(32) -- CXSIZEFRAME = 32
CYSIZEFRAME = winapiex.getSystemMetrics(33) -- CYSIZEFRAME = 33
CXVSCROLL = winapiex.getSystemMetrics(2) -- SM_CXVSCROLL = 2
CYCAPTION = winapiex.getSystemMetrics(4) -- SM_CYCAPTION = 4
CYBORDER = winapiex.getSystemMetrics(6) -- SM_CYBORDER = 6


----------------------------------------
-- DIALOG
----------------------------------------
dialog = QDialog.new()
dialog:setWindowTitle("Sidebar")
--dialog:setWindowIcon(QIcon(sidebarDir.."icons\\scite.png"))

local w = sidebarSettings.Sidebar.width
if w==nil then w = math.max(tabCnt*50, 160)
else w=tonumber(w) end

dialog:setMinimumSize(40, 0)

local flags
if sidebarSettings.Sidebar.position==nil then sidebarSettings.Sidebar.position='fixed' end

-- get scintilla rect
local sx, sy = winScintilla:get_position()
local sw, sh = winScintilla:get_bounds()
  
-- position=fixed: no title bar, automatically repositioned
-- position=floating: with title bar, moveable by user
if sidebarSettings.Sidebar.position=="fixed" then

  -- window without any buttons in titlebar
  flags = Qt.WindowType.CustomizeWindowHint

  local h = sh - 2*CYSIZEFRAME + 2*CYBORDER
  local x = sx+sw - w - CXVSCROLL - CXSIZEFRAME
  local y = sy + CYSIZEFRAME - CYBORDER

  dialog:setGeometry(x, y, w, h)
  dialog:setFixedHeight(h)

else

	-- window with tile bar, but without buttons
  flags = Qt.WindowType.Window
  flags = bit.bor(flags, Qt.WindowType.WindowTitleHint)
  flags = bit.bor(flags, Qt.WindowType.CustomizeWindowHint)

  local x = sx+sw - w-CXVSCROLL-2*CXSIZEFRAME
  local h = sh - CYCAPTION -   2*CYSIZEFRAME

  dialog:setGeometry(x, sy, w, h)

end

dialog:setWindowFlags(flags)

dialog:show()

-- get sidebar window/hwnd
winSidebar = winapi.find_window("QWidget", "Sidebar")
hwndSidebar = winSidebar:get_handle()

----------------------------------------
-- TABWIDGET
----------------------------------------
tabWidget = QTabWidget.new(dialog)
tabWidget:setStyleSheet("QTabBar::tab{padding:3px 8px;} QTabWidget::pane{;}")

-- callbacks
tabWidget:connect("2currentChanged(int)", function(self, index)
  if sidebarSettings.Tabs.functions=="1" then
    tabName = tabWidget:tabText(index):toUtf8()
    if tabName=="Functions" then
      scite.cmd("extender:sidebarUpdateFunctions")
    end
  end
end)

----------------------------------------
-- LAYOUT
----------------------------------------
local hbox = QHBoxLayout.new()
dialog:setLayout(hbox)
hbox:setContentsMargins (0,0,0,0)
hbox:addWidget(tabWidget)

local tabNum = 0

----------------------------------------
-- FILE EXPLORER TREEWIDGET
----------------------------------------
if sidebarSettings.Tabs.explorer=="1" then

  -- create a container frame
  local frame = QFrame.new(tabWidget)
  --frame:setAcceptDrops(true) -- TODO

  explorerTree = QTreeView.new(frame)

  -- create layout, so treeWidget expands to full width and height
  local vbox = QVBoxLayout.new()
  frame:setLayout(vbox)
  frame:setStyleSheet("QPushButton{margin:0px 5px 7px;padding:3px 2px}")

  vbox:setContentsMargins (0,0,0,0)

  vbox:addWidget(explorerTree)

  -- add Button
  explorerEditBtn = QPushButton.new(frame)
  explorerEditBtn:setText("Edit Explorer Settings")
  explorerEditBtn:connect('2clicked()', function(self)
    scite.cmd("open:"..sidebarDir.."explorer.ini")
  end)

  vbox:addWidget(explorerEditBtn)

  loadExplorerIni()

  -- hide header
  explorerTree:setHeaderHidden(true)

  -- hide all colums other than "name"
  explorerTree:setColumnHidden(1, true)
  explorerTree:setColumnHidden(2, true)
  explorerTree:setColumnHidden(3, true)

  -- callbacks

  function explorerTree:keyPressEvent(e) slotKeyPress(e:key(), e:nativeModifiers()) end

  explorerTree:connect('2doubleClicked(QModelIndex)', function(self, index)
    model = index:parent():model()
    info = model:fileInfo(index)
    if info:isDir() then return end -- ignore folders
    fn = info:filePath():toUtf8():gsub("/", "\\")

    -- open .project files in projects tab
    local fileType = info:suffix():toUtf8()
    if fileType=="project" and sidebarSettings.Tabs.projects=="1" then 
    	loadProject(fn)
    	showTab("projects")
    	return
    end
    
    -- check if file type has an external editor
    if sidebarSettings.Editors[fileType]~=nil then
      if sidebarSettings.Editors[fileType]=="" then
        winapi.shell_exec(nil, fn)
      else
        winapi.shell_exec(nil, sidebarSettings.Editors[fileType], fn)
      end
      return
    end

    -- open selected file in SciTE
    scite.cmd("open:"..fn)

    -- give keyboard focus back to SciTE
    winapiex.setForegroundWindow(hwndScite)

  end)

  tabWidget:addTab(frame, "Explorer")
  --tabWidget:setTabToolTip(tabNum, "File Explorer")

  tabMap["explorer"] = tabNum
  tabNum = tabNum+1
end

----------------------------------------
-- FTP TREEWIDGET
----------------------------------------
if sidebarSettings.Tabs.ftp=="1" then

  -- create a container frame
  local frame = QFrame.new(tabWidget)
  --frame:setAcceptDrops(true) -- TODO

  ftpTree = QTreeWidget.new(frame)
  ftpTree:setHeaderHidden(true)

  -- create layout, so treeWidget expands to full width and height
  local vbox = QVBoxLayout.new()
  frame:setLayout(vbox)
  frame:setStyleSheet("QPushButton{margin:0px 5px 7px;padding:3px 2px}")

  vbox:setContentsMargins (0,0,0,0)

  vbox:addWidget(ftpTree)

  -- add Button
  ftpEditBtn = QPushButton.new(frame)
  ftpEditBtn:setText("Edit FTP-Accounts")
  ftpEditBtn:connect('2clicked()', function(self)
    scite.cmd("open:"..sidebarDir.."ftp.ini")
  end)

  vbox:addWidget(ftpEditBtn)

  loadFtpIni()

  -- callbacks

  function ftpTree:keyPressEvent(e) slotKeyPress(e:key(), e:nativeModifiers()) end

  ftpTree:connect('2doubleClicked(QModelIndex)', function(self, index)
    local treeWidgetItem = ftpTree:currentItem()
    local itemData = treeWidgetItem:data(0, Qt.ItemDataRole.UserRole):toByteArray()

    -- get path
    local pathList = pathListFromTreeItem(treeWidgetItem)
    local acctName = pathList[1]
    table.remove(pathList, 1)

    local acct = ftpAccounts[acctName]

    if itemData=="1" then -- it's a file

      local path = table.concat(pathList, "/")

      -- check if file is already downloaded / opened in scite
      for tmpFileName,info in pairs(tmpFileMap) do
        if info.acct==acctName and info.path==path then
          -- re-open/activate tmp file in scite
          scite.cmd("open:"..tmpFileName)
          return
        end
      end

      -- otherwise download as new tmp file

      -- create its own subfolder with (hopefully unique, todo) random name
      local tmpSubDir = tmpDir.."\\"..tostring( math.random() ) --random(the maxinteger)
      winapi.make_dir(tmpSubDir)

       -- save as tmp file in tmpSubDir
      local name = pathList[#pathList]
      local tmpFileName = tmpSubDir.."\\"..name

      ftp = Ftp:new()
      ftp:setHost(acct["protocol"], acct["host"], acct["user"], acct["pass"], acct["port"]) --, acct["key"])

      scite.put("Trying to connect to "..acct["host"].."...")
      local ok, err = ftp:download(acct["home"]..path, tmpFileName)

      if ok then
        scite.put("OK")

        -- open tmp file in scite
        scite.cmd("open:"..tmpFileName)

        -- add downloaded file to map
        tmpFileMap[tmpFileName] = {acct=acctName, path=path}

      else
        -- error occured
        scite.err(err)
      end

    else -- it's a folder (0 or 2)

      -- remove previous children (=reload)
      local cnt = treeWidgetItem:childCount()
      if cnt>0 then
        for i = cnt, 1, -1 do
          treeWidgetItem:removeChild(treeWidgetItem:child(i-1))
        end
      end

      ftp = Ftp:new()
      ftp:setHost(acct["protocol"], acct["host"], acct["user"], acct["pass"], acct["port"]) --, acct["key"])

      local dir = acct["home"]..join(pathList, "/")

      scite.put("Trying to connect to "..acct["host"].."...")
      local ok, folders, files = ftp:list(dir)

      if ok then
        scite.put("OK")
        showFtpResult(treeWidgetItem, folders, files)
      else scite.err(folders) end

    end

  end)

  tabWidget:addTab(frame, "FTP")
  --tabWidget:setTabToolTip(tabNum, "Edit file on FTP/SFTP server")

  tabMap["ftp"] = tabNum
  tabNum = tabNum+1
end

----------------------------------------
-- FUNCTIONS LISTWIDGET
----------------------------------------
if sidebarSettings.Tabs.functions=="1" then

  loadFunctionsIni()

  -- create a container frame
  local frame = QFrame.new(tabWidget)

  functionList = QListWidget.new(frame)

  -- create layout, so treeWidget expands to full width and height
  local vbox = QVBoxLayout.new()
  frame:setLayout(vbox)
  frame:setStyleSheet("QPushButton{margin:0px 5px 7px;padding:3px 2px}")

  vbox:setContentsMargins (0,0,0,0)

  vbox:addWidget(functionList)

  -- add Button
  funcEditBtn = QPushButton.new(frame)
  funcEditBtn:setText("Edit Function Patterns")
  funcEditBtn:connect('2clicked()', function(self)
    scite.cmd("open:"..sidebarDir.."functions_cfg.lua")
  end)

  vbox:addWidget(funcEditBtn)

  -- callbacks
  functionList:connect('2doubleClicked(QModelIndex)', function(self, index)
    local functionName = functionList:item(index:row()):text():toUtf8()
    scite.cmd("extender:onFunctionSelected "..functionName)

    -- give keyboard focus back to SciTE
    winapiex.setForegroundWindow(hwndScite)
  end)

  --me.functionList.connect($.Qt.Event.KeyPress, me, #slotKeyPress)
  function functionList:keyPressEvent(e) slotKeyPress(e:key(), e:nativeModifiers()) end

  tabWidget:addTab(frame, "Functions")
  --tabWidget:setTabToolTip(tabNum, "Function List")

  tabMap["functions"] = tabNum
  tabNum = tabNum+1

end

----------------------------------------
-- BOOKMARKS LISTWIDGET
----------------------------------------
if sidebarSettings.Tabs.bookmarks=="1" then

  -- create a container frame
  local frame = QFrame.new(tabWidget)
  --frame:setAcceptDrops(true) -- TODO

  bookmarkList = QListWidget.new(frame)
  --bookmarkList:setSortingEnabled(true)

  -- create layout, so treeWidget expands to full width and height
  local vbox = QVBoxLayout.new()
  frame:setLayout(vbox)
  frame:setStyleSheet("QPushButton{margin:0px 5px 7px;padding:3px 2px}")
  vbox:setContentsMargins (0,0,0,0)

  vbox:addWidget(bookmarkList)

  -- add Button
  bookmarkEditBtn = QPushButton.new(frame)
  bookmarkEditBtn:setText("Edit Bookmarks")
  bookmarkEditBtn:connect('2clicked()', function(self)
    scite.cmd("open:"..sidebarDir.."bookmarks.ini")
  end)

  vbox:addWidget(bookmarkEditBtn)

  loadBookmarksIni()

  -- callbacks
  bookmarkList:connect('2doubleClicked(QModelIndex)', function(self, index)
    local fn = bookmarkList:item(index:row()):data(Qt.ItemDataRole.UserRole):toByteArray()
    local fileInfo = QFileInfo(fn)		
		if not fileInfo:exists() then
			return scite.err("File '"..fn.."' doesn't exist")
		end
		
		if fileInfo:isDir() then
       -- open it in explorer tab
      showInSidebarExplorer(fn)

    else -- assume it's a file

      -- check if file type has an external editor
      local fileType = fileInfo:suffix():toUtf8()
      if sidebarSettings.Editors[fileType]~=nil then
        if sidebarSettings.Editors[fileType]=="" then
          winapi.shell_exec(nil, fn)
        else
          winapi.shell_exec(nil, sidebarSettings.Editors[fileType], fn)
        end
      else
      	-- otherwise open selected file in SciTE
      	scite.cmd("open:"..fn)
      end
    end

    -- give keyboard focus back to SciTE
    winapiex.setForegroundWindow(hwndScite)

  end)

  function bookmarkList:keyPressEvent(e) slotKeyPress(e:key(), e:nativeModifiers()) end

  tabWidget:addTab(frame, "Favs") -- Bookmarks
  --tabWidget:setTabToolTip(tabNum, "Bookmark List")

  tabMap["bookmarks"] = tabNum
  tabNum = tabNum+1
end

----------------------------------------
-- PROJECTS TREEWIDGET
----------------------------------------
if sidebarSettings.Tabs.projects=="1" then

  -- create a container frame (to allow dropping files from windows desktop)
  local frame = QFrame.new(tabWidget)
  frame:setAcceptDrops(true)

  projectTree = QTreeWidget.new(frame)
  projectTree:setHeaderHidden(true)

  -- create layout, so treeWidget expands to full width and height
  local vbox = QVBoxLayout.new()
  frame:setLayout(vbox)
  frame:setStyleSheet("QPushButton{margin:0px 5px;padding:3px 2px}")
  vbox:setContentsMargins (0,0,0,0)

  vbox:addWidget(projectTree)

  -- add Buttons

  projectEditBtn = QPushButton.new(frame)
  projectEditBtn:setText("Edit Project")
  projectEditBtn:setDisabled(true)

  projectEditBtn:connect('2clicked()', function(self)
    scite.cmd("open:"..projectCurrentFile)
  end)

  vbox:addWidget(projectEditBtn)

  projectPublishMacBtn = QPushButton.new(frame)
  projectPublishMacBtn:setText("Publish for Mac (F7)")
  projectPublishMacBtn:setDisabled(true)
  projectPublishMacBtn:connect('2clicked()', slotPublishProjectMac)
  vbox:addWidget(projectPublishMacBtn)

  projectPublishWinBtn = QPushButton.new(frame)
  projectPublishWinBtn:setStyleSheet("margin-bottom:7px;")
  projectPublishWinBtn:setText("Publish for Win (F8)")
  projectPublishWinBtn:setDisabled(true)
  projectPublishWinBtn:connect('2clicked()', slotPublishProjectWin)

  vbox:addWidget(projectPublishWinBtn)

  -- callbacks
  projectTree:connect('2itemDoubleClicked(QTreeWidgetItem*,int)', function(self, treeWidgetItem, col)
    local fn = treeWidgetItem:data(0, Qt.ItemDataRole.UserRole):toByteArray()
    if fn==nil then return end
    fn = getWinPath(fn)

    -- ignore folder double clicks
    if fn:sub(-1)=="\\" then return end

    -- check if file type has an external editor
    local fileType = getFileType(fn)
    if sidebarSettings.Editors[fileType]~=nil then
      if sidebarSettings.Editors[fileType]=="" then
        winapi.shell_exec(nil, fn)
      else
        winapi.shell_exec(nil, sidebarSettings.Editors[fileType], fn)
      end
      return
    end

    -- check if file exists, otherwise try to create it
    local ok = fileExists(fn)
    if not ok then
      local f=io.open(fn, "wb")
      if f~=nil then
        f:close()
        ok = true
      end
    end
    if ok then
      scite.cmd("open:"..fn) -- open selected file in SciTE
    else
      scite.err("File '"..fn.."' doesn't exist and couldn't be created")
    end

    -- give keyboard focus back to SciTE
    winapiex.setForegroundWindow(hwndScite)

  end)

  function projectTree:keyPressEvent(e) slotKeyPress(e:key(), e:nativeModifiers()) end

  function frame:dragEnterEvent(e)
    e:acceptProposedAction()
  end

  function frame:dropEvent(e)
    if not e:mimeData():hasFormat('text/uri-list') then return end
    local data = tostring(e:mimeData():data('text/uri-list'))
    for path in string.gmatch(data, "([^\r\n]+)") do
      if path:sub(1, 8)=='file:///' then path = path:sub(9, path:len()) end
      loadProject(getWinPath(path:unescape()))
    end
  end

  tabWidget:addTab(frame, "Projects")
  --tabWidget:setTabToolTip(tabNum, "Project Browser")

  tabMap["projects"] = tabNum
  tabNum = tabNum+1

  -- autoload *.project file?
  projectSettings = ini.load(sidebarDir.."projects.ini").Settings
  if projectSettings.project~=nil then
    local p = projectSettings.project
    if projectSettings.projectRelativePath=="1" then
      p = sidebarDir..p
    end
    loadProject(p)
  end

end

-- set (internal) keyboard focus to first tab
local w = tabWidget:widget(0)
w:setFocus()

-- make sidebar modal to scite
winapiex.setWindowLong(hwndSidebar, -8, hwndScite)

-- give (global) keyboard focus back to SciTE
winapiex.setForegroundWindow(hwndScite) -- crash???

-- check occasionally if SciTE is still running, otherwise exit
timer = QTimer.new()
local f
if sidebarSettings.Sidebar.position=="fixed" then
  f = function()
    if winapi.find_window("SciTEWindow", nil):get_handle()==0 then os.exit(0)
    else repositionSidebar() end
  end
else
  f = function()
    if winapi.find_window("SciTEWindow", nil):get_handle()==0 then os.exit(0) end
  end
end
timer:connect("2timeout()", f)
timer:start(1000)

-- start listening for WM_COPYDATA messages sent by backend
scite.listen(hwndSidebar, "slotMessage")

if sidebarSettings.Tabs.functions=="1" then
  -- force update of function list for the active buffer in SciTE
  scite.cmd("extender:sidebarUpdateFunctions")
end

----------------------------------------
-- RUN APP
----------------------------------------
app.exec()
