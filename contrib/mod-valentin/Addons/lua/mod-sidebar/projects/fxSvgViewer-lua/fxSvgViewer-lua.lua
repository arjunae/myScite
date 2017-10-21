require 'qtcore'
require 'qtgui'
require 'qtsvg'

-- config

local appName = "fxSvgViewer"
local appVersion = "0.1"

local svgLoaded = false
local ratio = 1.0

-- functions

----------------------------------------
-- action "makro": creates an action
----------------------------------------
local addAction = function(menu, title, icon, shortcut, tip, triggerCallback)
  action = QAction.new(menu)
  action:setText(title)
	if icon~= nil then action:setIcon("assets/actions/"..icon) end
	if shortcut~=nil then action:setShortcut(QKeySequence(shortcut)) end
	--if tip~=nil then action:setStatusTip(tip) end
	if triggerCallback~=nil then action:connect('2triggered()', triggerCallback) end
  menu:addAction(action)
end

----------------------------------------
--
----------------------------------------
local unescape = function (url)
  return url:gsub("%%(%x%x)", function(x)
	  return string.char(tonumber(x, 16))
	end)
end

----------------------------------------
-- setupMenus
----------------------------------------
local setupMenus = function()

  -- menu file
  m = menuBar:addMenu("&File")
  addAction(m, "&Open File",nil,"Ctrl+O","Open a SVG file", slotOpen)
  m:addSeparator()
  addAction(m, "E&xit",nil,"Ctrl+Q","Exit the application", function()
  	mainWindow:close()
	end)
	
  -- menu help
  m = menuBar:addMenu("&Help")
  addAction(m, "About",nil,nil,nil, function()
		QMessageBox.about(mainWindow, 'About', '<b>'..appName..' v'..appVersion..'</b><br><br>A simple SVG viewer.<br><br>This application is based on <a href="https://www.lua.org/">Lua</a>, <a href="http://qt.apidoc.info/4.7.4/">Qt 4.7.4</a> and <a href="https://github.com/mkottman/lqt">lqt</a>.<br><br>License: <a href="http://en.wikipedia.org/wiki/WTFPL">WTFPL 2.0</a>')
  end)
  m:addSeparator()
  addAction(m, "About Qt",nil,nil,nil, function()
  	QMessageBox.aboutQt(mainWindow, 'About Qt')
  end)

end

----------------------------------------
-- setupMainWindow
----------------------------------------
local setupMainWindow = function()	
  mainWindow:setWindowTitle(appName)
  mainWindow:setWindowIcon(QIcon("assets/icons/app.png"))
  mainWindow:setMenuBar(menuBar)
  mainWindow:setMinimumSize(100, 100)
  mainWindow:resize(800, 480)
	mainWindow:setAcceptDrops(true)
	
  -- optional: create white background
  pal = QPalette.new()
  pal:setColor(10, QColor(255,255,255)) -- QPalette::Background=10
  mainWindow:setPalette(pal)
    
  hbox = QHBoxLayout.new()
  canvasWidget:setLayout(hbox)
  hbox:setContentsMargins (0,0,0,0)
  hbox:addWidget(svgWidget)

	mainWindow:setCentralWidget(canvasWidget)

	-- add event handlers

  function mainWindow:resizeEvent(e)
		local size = mainWindow:size()
		local cw = canvasWidget:width()-20
		local ch = canvasWidget:height()-20
		local w, h
		if cw/ch < ratio then
			h = cw/ratio
			w = cw
		else			
			w = ch*ratio
			h = ch
		end
		svgWidget:resize(w, h)
		svgWidget:move(math.floor(10+cw/2-w/2), math.floor(10+ch/2-h/2))
  end

  function mainWindow:mouseDoubleClickEvent(e)
		if (svgLoaded) then
			if mainWindow:isFullScreen() then
				mainWindow:showNormal()
				else
					mainWindow:showFullScreen()
				end
		end
  end
  
	function mainWindow:dragEnterEvent(e)
		e:acceptProposedAction()
	end
	
	function mainWindow:dropEvent(e)		
		if not e:mimeData():hasFormat('text/uri-list') then return end
		local data = tostring(e:mimeData():data('text/uri-list'))
   	for path in string.gmatch(data, "([^\r\n]+)") do
			if path:sub(1, 8)=='file:///' then path = path:sub(9, path:len()) end
			return loadFile(unescape(path))
    end
	end
  
end

----------------------------------------
-- Loads SVG file
----------------------------------------
function loadFile (path)
  svgWidget:load(path)
	svgLoaded = true
	local renderer = svgWidget:renderer()
	local size = renderer:defaultSize()
	local ratio = size:width()/size:height()
	mainWindow:resizeEvent()
end

----------------------------------------
-- @callback
----------------------------------------
function slotOpen ()
  local fn = QFileDialog.getOpenFileName(mainWindow, "Open SVG File", nil, "*.svg")
  if fn~=nil then loadFile(fn) end
end

-- start
app = QApplication.new(select('#',...)+1, {'lua',...})

-- create widgets
mainWindow = QMainWindow.new()
menuBar = QMenuBar.new(mainWindow)
canvasWidget = QWidget.new(mainWindow)
svgWidget = QSvgWidget.new(mainWindow)

-- setup
setupMenus()
setupMainWindow()

-- show
mainWindow:show()

-- handle command line args
if arg[1]~=nil then loadFile(arg[1]) end

-- run app
app.exec()
