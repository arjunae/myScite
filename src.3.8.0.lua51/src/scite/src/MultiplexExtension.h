// SciTE - Scintilla based Text Editor
/** @file MultiplexExtension.h
 ** Extension that manages / dispatches messages to multiple extensions.
 **/
// Copyright 1998-2003 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#ifndef MULTIPLEXEXTENSION_H
#define MULTIPLEXEXTENSION_H

#include "Extender.h"

// MultiplexExtension manages multiple Extension objects, similar to
// what is proposed in the SciTE Extension documentation.  Each
// message is sent to each contained extension object in turn until
// one indicates that the message has been handled and does not need
// to be processed further.  Certain messages (Initialise, Finalise
// Clear, and SendProperty) are sent to all contained extensions
// regardless of return code.
//
// The Director extension incorrectly returns true for all messages,
// meaning that other extensions will never see the message if
// DirectorExtension comes before them in the list.  This has been
// fixed at source.
//
// Extensions are added to the multiplexer by calling RegisterExtension.
// The extensions are prioritized with the first one added having the
// highest priority.  If more flexibility is needed in order to support
// dynamic discovery of extensions and assignment of priority, that will
// be added later.  If the ability to remove extensions becomes important,
// that can be added as well (later).
//
// The multiplexer does not manage the lifetime of the extension objects
// that are registered with it.  If that functionality later turns out
// to be needed, it will be added at that time.  (Broken record?  Do the
// simplest thing...)  However, the option to "not" manage the lifecycle
// is a valid one, since it often makes sense to implement extensions as
// singletons.

class MultiplexExtension: public Extension {
public:
	MultiplexExtension();
	// Copying is unsupported.
	MultiplexExtension(const MultiplexExtension & copy) = delete;
	MultiplexExtension & operator=(const MultiplexExtension & copy) = delete;
	~MultiplexExtension();

	bool RegisterExtension(Extension &ext_);

	bool Initialise(ExtensionAPI *host_);
	bool Finalise();
	bool Clear();
	bool Load(const char *filename);
	intptr_t QueryLuaState();

	bool InitBuffer(int);
	bool ActivateBuffer(int);
	bool RemoveBuffer(int);

	bool OnOpen(const char *);
	bool OnSwitchFile(const char *);
	bool OnBeforeSave(const char *);
	bool OnSave(const char *);
	bool OnChar(char);
	bool OnExecute(const char *);
	bool OnSavePointReached();
	bool OnSavePointLeft();
	bool OnStyle(unsigned int, int, int, StyleWriter *);
	bool OnClick(int);
	bool OnDoubleClick();
	bool OnUpdateUI();
	bool OnMarginClick();
	bool OnMacro(const char *, const char *);
	bool OnUserListSelection(int, const char *);

	bool SendProperty(const char *);

	bool OnKey(int, int);
	bool OnDwellStart(int, const char *);
	bool OnClose(const char *);
	bool OnUserStrip(int control, int change);
	bool NeedsOnClose();

private:
	std::vector<Extension *> extensions;
	ExtensionAPI *host;
};

#endif
