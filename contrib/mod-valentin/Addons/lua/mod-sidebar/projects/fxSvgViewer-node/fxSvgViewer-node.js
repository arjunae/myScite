//!encoding=utf-8
'use strict';

/**
 * fxSvgViewer 0.1
 *
 * Comments in JSDoc 3 format
 *
 * @file Core app file for fxSvgViewer
 * @author Valentin Schmidt
 * @copyright Valentin Schmidt 2014
 * @version 0.0.1
 */

(function () {

process.chdir(__dirname);

// here private static vars

//################################################
// REQUIRE
//################################################

// built-in modules
var fs = require('fs');
var qs = require('querystring');

// external modules
var qt = require('node-qt');

/**
 * App Object
 *
 * @constructor
 */
var App = function(){
	var self = this;

	self.appName = 'fxSvgViewer'; 
	self.appOrg = 'fx';
	self.appVersion = '0.0.1';
	self.actions = {};
	self.svgLoaded = false;
	
	// create app
	self.qtApp = new qt.QApplication();
	self.qtApp.setApplicationName(self.appName);
	self.qtApp.setOrganizationName(self.appOrg);
	self.qtApp.setApplicationVersion(self.appVersion);
	
	// create widgets
	self.mainWindow = new qt.QMainWindow(0, true);
	self.mainWindow.setMinimumWidth(100);
	self.mainWindow.setMinimumHeight(100);
	self.mainWindow.resize(800, 480);
	
	// optional: create white background
	var pal = new qt.QPalette();
	pal.setColor(10, new qt.QColor(255,255,255)); // QPalette::Background=10
	self.mainWindow.setPalette(pal);
	self.mainWindow.on('resizeEvent', function(size, oldSize){
		if (size){
			var cw = self.canvasWidget.width()-20;
			var ch = self.canvasWidget.height()-20;
			var w, h;
			if (cw/ch < self.ratio){
				h = cw/self.ratio;
				w = cw;
			}else{				
				w = ch*self.ratio;
				h = ch;
			}
			self.svgWidget.resize(w, h);
			self.svgWidget.move(10+cw/2-w/2, 10+ch/2-h/2);
		}
	});
	self.mainWindow.on('mouseDoubleClickEvent', function(){
		if (self.svgLoaded){
			self.mainWindow.setWindowState(self.mainWindow.windowState()^4); // toggle fullscreen view
		}
	});
	
	self.menuBar = new qt.QMenuBar(self.mainWindow);	
	self.canvasWidget = new qt.QWidget(self.mainWindow);		
	self.svgWidget = new qt.QSvgWidget(self.mainWindow, true);
	
	// setup
	self.setupActions();
	self.setupMenus();	
	self.setupMainWindow();
	self.mainWindow.show();
	
	// handle command line args
	var argv = process.argv;
	if (argv.length>2) {
		var path = argv.pop();
		var stats = fs.statSync(path);
		if (stats.isFile()){
			self.loadFile(path);
		}
	}
	
	// join node's event loop
	setInterval(self.qtApp.processEvents, 0);
};

//################################################
// SETUP FUNCTIONS
//################################################

// action "makro": creates an action
function _a(title, icon, shortcut, tip, triggerCallback){
	var action = new qt.QAction(title);
	if (icon) action.setIcon(__dirname+'/assets/actions/'+icon);
	if (shortcut) action.setShortcut(shortcut);
	if (tip) action.setStatusTip(tip);
	if (triggerCallback) action.on('triggered', triggerCallback);
	return action;
}

/**
 * setupActions
 *
 * @this {App}
 */
App.prototype.setupActions = function(){
	var self = this;

	// MENU FILE ###################

	// open
	self.actions.open = _a('&Open File','new.png','Ctrl+O','Open a SVG file', function(){		
		var fn = qt.QFileDialog.getOpenFileName(self.mainWindow, 'Open SVG file','','*.svg');
		if (fn) self.loadFile(fn);
	});

	// exit
	self.actions.exit = _a('E&xit','','Ctrl+Q','Exit the application', function(){
		self.exit();
	});
	
	// MENU HELP ###################
		
	// about
	self.actions.about = _a('About','','','',function(){
		qt.QMessageBox.about(self.mainWindow, 'About', '<b>'+self.appName+' v'+self.appVersion+'</b><br><br>A simple SVG viewer.<br><br>This application is based on <a href="http://nodejs.org/">Node.js</a>, <a href="http://qt-project.org/doc/qt-4.8/">Qt 4.8</a> and a customized and extended version of the <a href="https://github.com/arturadib/node-qt#readme">Node-Qt Addon</a> and was written in pure <a href="https://en.wikipedia.org/wiki/JavaScript">JavaScript</a>.<br><br>License: <a href="http://en.wikipedia.org/wiki/WTFPL">WTFPL 2.0</a>');
	});
	
	// about qt
	self.actions.aboutQt = _a('About Qt','','','',function(){
		qt.QMessageBox.aboutQt(self.mainWindow, 'About Qt');
	});
};

/**
 * setupMenus
 *
 * @this {App}
 */
App.prototype.setupMenus = function(){
	var self = this;

	var m;
	
	// MENU FILE ###################
	m = self.menuBar.addMenu('&File');
	m.addAction(self.actions.open);
	m.addSeparator();
	m.addAction(self.actions.exit);
	
	// MENU HELP ###################
	m = self.menuBar.addMenu('&Help');
	m.addAction(self.actions.about);
	m.addSeparator();
	m.addAction(self.actions.aboutQt);
	
	// dev only, remove in release version
	if (process.execArgv.indexOf('--expose-gc')>-1){
		m.addSeparator();
		self.actions.gc = m.addAction('Force Garbage Collection').on('triggered', global.gc);
	}
};

/**
 * setupMainWindow
 *
 * @this {App}
 */
App.prototype.setupMainWindow = function(){
	var self = this;

	self.mainWindow.setWindowTitle(self.appName);
	self.mainWindow.setWindowIcon(__dirname + '/assets/icons/app.png');
	self.mainWindow.setMenuBar(self.menuBar);
	
	var hlayout = new qt.QHBoxLayout();
	hlayout.addWidget(self.svgWidget);
	self.canvasWidget.setLayout(hlayout);
	self.mainWindow.setCentralWidget(self.canvasWidget);

	// setup event callbacks
	self.mainWindow.setAcceptDrops(true);
	self.mainWindow.on('closeEvent', self.exit);
	self.mainWindow.on('dropEvent', function(e){
		var data = e.mimeData();
		if (!data['text/uri-list']) return;
		var flist = data['text/uri-list'].toString().split('\r\n');
		flist.pop();
		flist.forEach(function(path){
			if (path.substr(0,8)=='file:///') path = path.substr(8);
			path = qs.unescape(path);
			var stats = fs.statSync(path);
			if (stats.isFile()){
				return self.loadFile(path);
			}
		});
	});
};

/**
 * Loads SVG file
 *
 * @this {App}
 * @param {string} path
 */
App.prototype.loadFile = function(path){
	var self = this;
	self.svgWidget.load(path);
	self.svgLoaded = true;
	var size = self.svgWidget.defaultSize();
	self.ratio = size.width()/size.height();
	self.mainWindow.emit('resizeEvent', self.mainWindow.size()); // force resize call
}

/**
 * Handles 'exit' action
 *
 * @callback
 * @this {object} - QAction that was triggered by user!
 */
 App.prototype.exit = function(){
	var self = this;
	process.exit();
}

// run app
new App();

})();
