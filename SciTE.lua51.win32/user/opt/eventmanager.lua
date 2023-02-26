--[[-----------------------------------------------------------------
eventmanager.lua
Authors: T Gubayev
version: 1.1.0
---------------------------------------------------------------------
  Description:
	simple event manager realization for SciTE.
	exported functions (self-descriptive):
	  * AddEventHandler ( EventName, Handler[, RunOnce] ) => Handler
	  * RemoveEventHandler ( EventName, Handler )
	
  simple event manager for SciTE
---------------------------------------------------------------------
History:
	* 1.0.0 initial release
	* 1.0.1 RemoveEventHandler bug fix
	* 1.0.2  Dispatch bug fix (non-existent event raised error)
			 RunOnce bug fix
	* 1.0.3 Dispatch bug workaround (rare OnOpen event bug)
	* 1.0.4 Rearrange `_remove` table (doesn't affect managers behavior)
	* 1.1.0 `AddEventHandler` now returns added function handler.
			Use this value to remove handler added with RunOnce option.
--]]-----------------------------------------------------------------


local events  = {}
local _remove = {}

-- At the end, resets the "to delete" list
local function RemoveAllOutstandingEventHandlers()
	for i = 1, #_remove do
		local ename, h_rem = next(_remove[i])
		local t_rem = events[ename]
		for j = 1, #t_rem do
			if t_rem[j]==h_rem then
				table.remove(t_rem, j)
				break -- remove only one handler instance
			end
		end
	end -- @todo: feel free to optimize this cycle
	_remove = {} -- clear it
end

--- Start event handling
-- Returns whatever the handler returned, not just the first argument (stop flag)
local function Dispatch (name, ...)
	RemoveAllOutstandingEventHandlers() -- first remove all from _remove
	local event = events[name]
	local res
	for i = 1, #event do
		local h = event[i]
		if h then --@ this is a workaround for eventhandler-disappear bug (see v.1.0.3)
			res = { h(...) } -- store whole handler return in a table
			if res[1] then -- first returned value is a interruption flag
				return unpack(res)
			end
		end
	end
	return res and unpack(res) -- just for the case of error-handling
end

--- Create a new handler to be called by the editor kernel
-- In case such function already exists (i.e. was created without using AddEventHandler),
-- then it is put first in the queue
local function NewDispatcher(EventName)
	
	local dispatch = function (...) -- `shortcut`
		return Dispatch(EventName, ...)
	end
	
	-- just for the case some handler was defined in other way before
	local old_handler = _G[EventName]
	if old_handler then
		AddEventHandler(EventName, old_handler) -- @todo: can this recurse?
	end
	
	_G[EventName] = dispatch
end

--- Connects a custom handler to a SciTE event (last one)
-- RunOnce parameter is optional, default is false
function AddEventHandler(EventName, Handler, RunOnce)
	local event = events[EventName]
	if not event then
		-- create new event array
		events[EventName] = {}
		event = events[EventName]
		-- register base event dispatcher
		NewDispatcher(EventName)
	end
	
	local OnceHandler
	if not RunOnce then
		event[#event+1] = Handler
	else
		OnceHandler = function(...)
			RemoveEventHandler(EventName, OnceHandler)
			return Handler(...)
		end
		event[#event+1] = OnceHandler
	end
	
	return OnceHandler or Handler
end -- AddEventHandler

--- Remove event handler
-- If one handler is connected to the same event twice, then delete it twice
function RemoveEventHandler(EventName, Handler)
	_remove[#_remove+1]={[EventName]=Handler}
end
