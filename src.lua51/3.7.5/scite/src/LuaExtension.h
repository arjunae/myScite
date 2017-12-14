// SciTE - Scintilla based Text Editor
// LuaExtension.h - Lua scripting extension
// Copyright 1998-2000 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

class LuaExtension : public Extension {
private:
	LuaExtension(); // Singleton

public:
	static LuaExtension &Instance();

	// Deleted so LuaExtension objects can not be copied.
	LuaExtension(const LuaExtension &) = delete;
	void operator=(const LuaExtension &) = delete;
 ~LuaExtension();

 bool Initialise(ExtensionAPI *host_);
 bool Finalise();
 bool Clear();
 bool Load(const char *filename);

 bool InitBuffer(int);
 bool ActivateBuffer(int);
 bool RemoveBuffer(int);

 bool OnOpen(const char *filename);
 bool OnSwitchFile(const char *filename);
 bool OnBeforeSave(const char *filename);
 bool OnSave(const char *filename);
 bool OnChar(char ch);
 bool OnExecute(const char *s);
 bool OnSavePointReached();
 bool OnSavePointLeft();
 bool OnStyle(unsigned int startPos, int lengthDoc, int initStyle, StyleWriter *styler);
 bool OnClick(int);
 bool OnDoubleClick();
 bool OnUpdateUI();
 bool OnMarginClick();
 bool OnUserListSelection(int listType, const char *selection);
 bool OnKey(int keyval, int modifiers);
 bool OnDwellStart(int pos, const char *word);
 bool OnClose(const char *filename);
 bool OnUserStrip(int control, int change);
 bool NeedsOnClose();
};
