--
-- prettyLua.lua - a poor man's Lua prettifier. Converts spaces to tabs and applies Lua indentation based on keywords.
-- Version: 2020-10-11  enhanced by ThorstenK arjunae at nurfuerspam.de
-- based on toTabs.lua
-- Modified to fix elseif indentation issues

DEBUG = false

local function debugPrint(...)
    if DEBUG then
        print(...)
    end
end

function prettifyLua(luaCode, tabSize)
    tabSize = tabSize or 4 -- Default tab size to 4 if not provided

    local lines = {}
    for line in luaCode:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    debugPrint("Starting prettify_lua with tabSize:", tabSize)

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
         return count
    end

    local newLines = {}
    local blockStack = {}
    local ifBlockLevels = {} -- Stack to track indentation levels for if/elseif/else blocks

    for ln = 1, #lines do
        local text = lines[ln]
        local lead = text:match('^[ \t]*') or ''
        local body = text:sub(#lead + 1)
        local trimmed = body:match('^%s*(.*%S)%s*$') or ''

        debugPrint("\n--- Processing Line ", ln, ": ", text:gsub("\t", "\\t"):gsub(" ", "_"))
 
        -- Strip comments before analyzing
        local beforeC = trimmed:gsub('%-%-.*', '')
        local tokens = {}
        for w in beforeC:gmatch('(%w+)') do
            tokens[#tokens + 1] = w
        end
        --debugPrint("  Tokens: ", table.concat(tokens, ", "))

        -- Count how many 'end' tokens appear consecutively
        local endCount = 0
        while tokens[endCount + 1] == 'end' do
            endCount = endCount + 1
        end

        -- Calculate intended indentation level
        local level = #blockStack - endCount
        if level < 0 then level = 0 end
        debugPrint("  Calculated indentation level (from stack and endCount): ", level)

        -- Convert leading whitespace to tabs based on indentation level
        local totalSpaces = getLeadingSpaceCount(text)
        local tabs = math.floor(totalSpaces / tabSize)
        local spaces = totalSpaces % tabSize
        local partialTabThreshold = 1 -- Threshold to round up to next tab
       -- Handle special cases for if/elseif/else blocks
        local first = trimmed:match('^(%w+)') or ''

        if first == 'elseif' or first == 'else' then
            -- Use the stored if-block level if available
            if #ifBlockLevels > 0 then
                tabs = ifBlockLevels[#ifBlockLevels]
                spaces = 0
                debugPrint("  Using stored if-block level: ", tabs)
            else
                -- Fallback to calculated level if no stored level
                tabs = level
                spaces = 0
                debugPrint("  No stored if-block level, using calculated level: ", level)
            end

            -- Do not adjust block stack for elseif/else to prevent incorrect level increase
        else
            -- Normal indentation adjustment
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
        end

        -- Compose new line with tabs and optional spaces
        newLines[ln] = string.rep('\t', tabs) .. string.rep(' ', spaces) .. body
        debugPrint("  New line composed: '", newLines[ln]:gsub("\t", "\\t"):gsub(" ", "_"), "'")

        -- Adjust block stack for inline 'end' tokens
        if endCount > 0 then
            debugPrint("  Processing ", endCount, " inline 'end' tokens")
        end
        for i = 1, endCount do
            if #blockStack > 0 then
                local popped = blockStack[#blockStack]
                debugPrint(" Popping '", popped, "' due to inline 'end'")
                table.remove(blockStack)
                debugPrint(" BlockStack after inline pop: ", table.concat(blockStack, ", "), " (size: ", #blockStack, ")")
                if popped == 'if_block' and #ifBlockLevels > 0 then
                    table.remove(ifBlockLevels)
                end
            else
            end
        end

        -- Handle explicit "end" line
        if beforeC:match('^end$') then
            if #blockStack > 0 then
                local popped = blockStack[#blockStack]
                debugPrint(" Popping '", popped, "' due to 'end' line")
                table.remove(blockStack)
                debugPrint(" BlockStack after 'end' line pop: ", table.concat(blockStack, ", "), " (size: ", #blockStack, ")")
                if popped == 'if_block' and #ifBlockLevels > 0 then
                    table.remove(ifBlockLevels)
                end
            else
                debugPrint(" 'end' line but blockStack is empty.")
            end
        end

        -- Update block stack for opening constructs

        if first == 'function' or (first == 'local' and trimmed:match("^local%s+function")) then
            debugPrint(" Pushing 'function'")
            table.insert(blockStack, 'function')
            debugPrint(" BlockStack after 'function' push: ", table.concat(blockStack, ", "), " (size: ", #blockStack, ")")
        elseif first == 'if' then
            -- Detect inline if-then-end patterns
            local thenPos = trimmed:find('%f[%w]then%f[%W]')
            local push = true
            if thenPos then
                local rest = trimmed:sub(thenPos + 4)
                rest = rest:gsub('%-%-.*', ''):gsub('^%s*', '')
                if rest:match('%f[%w]end%f[%W]') then
                    push = false
                    debugPrint(" Not pushing 'if_block' due to inline 'if-then-end'")
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
                    debugPrint(" Not pushing 'if_block' due to keyword '", w, "' after 'then' in inline 'if'")
                end
            end
            if push then
                debugPrint(" Pushing 'if_block' for 'if'")
                table.insert(blockStack, 'if_block')
					-- Store the indentation level for this if block
                table.insert(ifBlockLevels, tabs)
                debugPrint(" Stored if-block level: ", tabs)
            end
        elseif first == 'for' or first == 'while' or first == 'repeat' or first == 'do' then
            debugPrint(" Pushing 'general' for loop/do block")
            table.insert(blockStack, 'general')
        elseif first == 'until' then
            debugPrint(" 'until' encountered, no block push.")
        end
    end

    debugPrint("Prettification complete. Returning joined lines.")
    return table.concat(newLines, "\n")
end

function prettify_lua(key)
    indent = props["indent.size"] or 4

    if key == 18 then -- ALT key
        local sel = editor:GetSelText()
        if sel and #sel > 0 then
            if editor.LexerLanguage == "lua" then
                local pretty = prettifyLua(sel, indent)
                editor:ReplaceSel(pretty)
            else
                print("prettify only supports lua code, not: ", editor.LexerLanguage)
            end
        else
        end
        return true
    end
    return false
end
