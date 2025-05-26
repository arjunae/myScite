--
-- prettyLua.lua - a poor man's Lua prettifier. Converts spaces to tabs and applies Lua indentation based on keywords.
-- Version: 2020-14-04  enhanced by ThorstenKani arjunae@nurfuerspam.de
-- based on toTabs.lua

local DEBUG = false

local function debugPrint(...)
	if DEBUG then
		print(...)
	end
end

function prettify_lua(luaCode, tabSize)
	tabSize = tabSize or 4 -- Default tab size to 4 if not provided
	
	local lines = {}
	for line in luaCode:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	
	debugPrint("Starting prettify_lua with tabSize:", tabSize)
	
	-- Count the number of spaces and tabs at the beginning of a line
	local function getLeadingSpaceCount(s)
		local leading = s:match("^[ \t]*") or ""
		local count = 0
		for c in leading:gmatch(".") do
			if c == ' ' then
				count = count + 1
				elseif c == '\t' then
				count = count + tabSize
			end
		end
		debugPrint("  getLeadingSpaceCount('", s:gsub("\t", "\\t"):gsub(" ", "_"), "') -> ", count)
		return count
	end

	-- Build a stack of code blocks (e.g., function, if, loops) to track nesting
	local function initStack(upto)
		debugPrint("Initializing stack up to line:", upto)
		local stack = {}
		for ln = 1, upto - 1 do
			local line = lines[ln] or ""
			local trim = line:match("^%s*(.*%S)%s*$") or ""
			local first = trim:match("^%S+") or ""
			debugPrint("  initStack - Processing line ", ln, ": '", trim, "'")
		
			-- Push block type onto stack for recognized Lua constructs
			if first == 'function' or (first == 'local' and trim:match("^local%s+function")) then
				table.insert(stack, 'function')
				debugPrint("    initStack - Pushed 'function'")
			elseif first == 'if' then
				table.insert(stack, 'if_block')
				debugPrint("    initStack - Pushed 'if_block'")
			elseif first == 'for' or first == 'while' or first == 'repeat' or first == 'do' then
				table.insert(stack, 'general')
				debugPrint("    initStack - Pushed 'general'")
			end
	
			-- Handle block closers
			if first == 'end' or first == 'until' then
				if #stack > 0 then
					debugPrint("    initStack - Popping '", stack[#stack], "' for '", first, "'")
					table.remove(stack)
				else
					debugPrint("    initStack - Stack empty, cannot pop for '", first, "'")
				end
			end

			-- Special handling for else/elseif
			if first == 'else' or first == 'elseif' then
				if stack[#stack] == 'if_block' then
					debugPrint("    initStack - Popping and re-pushing 'if_block' for '", first, "'")
					table.remove(stack)
					table.insert(stack, 'if_block')
				else
					debugPrint("    initStack - No 'if_block' on top for '", first, "'")
				end
			end
			debugPrint("  initStack - Stack after line ", ln, ": ", table.concat(stack, ", "))
		end
		debugPrint("initStack finished. Final stack size: ", #stack)
		return stack
	end

	local newLines = {}
	local blockStack = {}

	-- Process each line
	for ln = 1, #lines do
		local text = lines[ln]
		local lead = text:match('^[ \t]*') or ''
		local body = text:sub(#lead + 1)
		local trimmed = body:match('^%s*(.*%S)%s*$') or ''
	
		debugPrint("\n--- Processing Line ", ln, ": '", text:gsub("\t", "\\t"):gsub(" ", "_"), "' (trimmed: '", trimmed, "')")
		debugPrint("BlockStack before adjustments: ", table.concat(blockStack, ", "), " (size: ", #blockStack, ")")
	
		-- Strip comments before analyzing
		local beforeC = trimmed:gsub('%-%-.*', '')
		local tokens = {}
		for w in beforeC:gmatch('(%w+)') do
			tokens[#tokens + 1] = w
		end
		debugPrint("  Tokens from uncommented line: ", table.concat(tokens, ", "))
	
		-- Count how many 'end' tokens appear consecutively
		local endCount = 0
		while tokens[endCount + 1] == 'end' do
			endCount = endCount + 1
		end
		debugPrint("  Consecutive 'end' count: ", endCount)
	
		-- Calculate intended indentation level
		local level = #blockStack - endCount
		if level < 0 then level = 0 end
		debugPrint("  Calculated indentation level (from stack and endCount): ", level)
	
		-- Convert leading whitespace to tabs based on indentation level
		local totalSpaces = getLeadingSpaceCount(text)
		local tabs = math.floor(totalSpaces / tabSize)
		local spaces = totalSpaces % tabSize
		local partialTabThreshold = 1 -- Threshold to round up to next tab
		debugPrint("  Original leading spaces: ", totalSpaces, ", Tabs: ", tabs, ", Spaces: ", spaces)
	
	
		if tabs < level then
			debugPrint("  Adjusting tabs to calculated level: ", level, " (from ", tabs, ")")
			tabs = level
			spaces = 0
		end
		if spaces >= partialTabThreshold then
			debugPrint("  Rounding up partial tab: ", spaces, " spaces >= ", partialTabThreshold, " threshold")
			tabs = tabs + 1
			spaces = 0
		end
		debugPrint("  Final tabs: ", tabs, ", spaces: ", spaces, " for new line")

		-- Compose new line with tabs and optional spaces
		newLines[ln] = string.rep('\t', tabs) .. string.rep(' ', spaces) .. body
		debugPrint("  New line composed: '", newLines[ln]:gsub("\t", "\\t"):gsub(" ", "_"), "'")

		-- Adjust block stack for inline 'end' tokens
		if endCount > 0 then
			debugPrint("  Processing ", endCount, " inline 'end' tokens")
		end
		for i = 1, endCount do
			if blockStack[#blockStack] == 'if_block' then
				debugPrint("  DEBUG: Popping 'if_block' due to inline 'end'")
				table.remove(blockStack)
			else
				debugPrint("  DEBUG: Inline 'end' but top of stack is not 'if_block' (", blockStack[#blockStack], "), popping anyway.")
				table.remove(blockStack) -- Should ideally handle other block types too if needed
			end
		end

		-- Handle explicit "end" line
		if beforeC:match('^end$') then
			if #blockStack > 0 then
				debugPrint("  DEBUG: Popping '", blockStack[#blockStack], "' due to 'end' line")
				table.remove(blockStack)
			else
				debugPrint("  DEBUG: 'end' line but blockStack is empty.")
			end
		end

		-- Update block stack for opening constructs
		local first = trimmed:match('^(%w+)') or ''
		debugPrint("  First word of trimmed line: '", first, "'")

		if first == 'function' or (first == 'local' and trimmed:match("^local%s+function")) then
			debugPrint("  DEBUG: Pushing 'function'")
			table.insert(blockStack, 'function')
		elseif first == 'if' then
			-- Detect inline if-then-end patterns
			local thenPos = trimmed:find('%f[%w]then%f[%W]')
			local push = true
			if thenPos then
				local rest = trimmed:sub(thenPos + 4)
				rest = rest:gsub('%-%-.*', ''):gsub('^%s*', '')
				if rest:match('%f[%w]end%f[%W]') then
					push = false
					debugPrint("  DEBUG: Not pushing 'if_block' due to inline 'if-then-end'")
				end
				local w = rest:match('^(%w+)')
				local k = {
					["if"] = 1, ["for"] = 1, ["while"] = 1, ["function"] = 1,
					["repeat"] = 1, ["do"] = 1, ["end"] = 1,
					["else"] = 1, ["elseif"] = 1, ["until"] = 1,
					["return"] = 1, ["break"] = 1, ["local"] = 1
				}
				if w and k[w] then
					push = false
					debugPrint("  DEBUG: Not pushing 'if_block' due to keyword '", w, "' after 'then' in inline 'if'")
				end
			end
			if push then
				debugPrint("  DEBUG: Pushing 'if_block' for 'if'")
				table.insert(blockStack, 'if_block')
			end
		elseif first == 'for' or first == 'while' or first == 'repeat' or first == 'do' then
			debugPrint("  DEBUG: Pushing 'general' for loop/do block")
			table.insert(blockStack, 'general')
		elseif first == 'else' or first == 'elseif' then
			-- This is the crucial part for elseif indentation
			if #blockStack > 0 and blockStack[#blockStack] == 'if_block' then
				debugPrint("  DEBUG: Popping existing 'if_block' for '", first, "' (to re-adjust indentation)")
				table.remove(blockStack)
			else
				debugPrint("  DEBUG: '", first, "' encountered, but no 'if_block' on top of stack. Current stack: ", table.concat(blockStack, ", "))
			end
			debugPrint("  DEBUG: Pushing 'if_block' for '", first, "'")
			table.insert(blockStack, 'if_block')
		elseif first == 'until' then -- 'until' only closes 'repeat' blocks, no push
			debugPrint("  DEBUG: 'until' encountered, no block push.")
		end
		debugPrint("BlockStack after adjustments: ", table.concat(blockStack, ", "), " (size: ", #blockStack, ")")
	end

	debugPrint("Prettification complete. Returning joined lines.")
	return table.concat(newLines, "\n")
end

function prettifyLua(key)
	
	indent=props["indent.size"] or 4
	
	if key == 18 then -- ALT key
			local sel = editor:GetSelText()
		if sel and #sel > 0 then
			if editor.LexerLanguage == "lua" then
				debugPrint("prettifyLua triggered for Lua code.")
				local pretty = prettify_lua(sel, indent)
					editor:ReplaceSel(pretty)
				else
					print("prettify only supports lua code, not: ", editor.LexerLanguage)
				end
		else
			debugPrint("No selection found, prettifyLua not executed.")
		end
	return true
	end
	debugPrint("prettifyLua key not 18, returning false.")
	return false

end
