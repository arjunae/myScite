--
-- spc2tabs.lua - a poor man's Lua prettifier. Converts spaces to tabs and applies Lua indentation based on keywords.
-- Version: 2020-14-04  enhanced by ThorstenKani arjunae@nurfuerspam.de
-- based on toTabs.lua

-- Main function triggered on a specific keypress (key code 18) ALT
function prettifyLua(key)
    -- Only proceed if the active document uses Lua syntax highlighting
    if editor.LexerLanguage ~= "lua" then return end
    -- Only respond to specific key (key code 18)
    if key ~= 18 then return end

    -- Get selected text range
    local selS, selE = editor.SelectionStart, editor.SelectionEnd
    if selS == selE then return end  -- No selection; do nothing

    -- Calculate line numbers from selection positions
    local startLn = editor:LineFromPosition(selS)
    local endLn = editor:LineFromPosition(selE)

    -- Get tab size setting (default to 4 if undefined)
    local tabSize = tonumber(props["indent.size"]) or 4
    local partialTabThreshold = 1  -- Threshold to round up to next tab

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
        return count
    end

    -- Backup original lines in the selected range
    local original = {}
    for ln = startLn, endLn do
        original[ln] = editor:GetLine(ln) or ""
    end

    editor:BeginUndoAction()  -- Begin batch undo

    -- Build a stack of code blocks (e.g., function, if, loops) to track nesting
    local function initStack(upto)
        local stack = {}
        for ln = 1, upto - 1 do
            local line = editor:GetLine(ln) or ""
            local trim = line:match("^%s*(.*%S)%s*$") or ""
            local first = trim:match("^%S+") or ""

            -- Push block type onto stack for recognized Lua constructs
            if first == 'function' or (first == 'local' and trim:match("^local%s+function")) then
                table.insert(stack, 'function')
            elseif first == 'if' then
                table.insert(stack, 'if_block')
            elseif first == 'for' or first == 'while' or first == 'repeat' or first == 'do' then
                table.insert(stack, 'general')
            end

            -- Handle block closers
            if first == 'end' or first == 'until' then
                table.remove(stack)
            end

            -- Special handling for else/elseif
            if first == 'else' or first == 'elseif' then
                if stack[#stack] == 'if_block' then
                    table.remove(stack)
                    table.insert(stack, 'if_block')
                end
            end
        end
        return stack
    end

    local blockStack = initStack(startLn)  -- Initial stack before processing selection
    local newLines = {}

    -- Process each selected line
    for ln = startLn, endLn do
        local text = original[ln]
        local lead = text:match('^[ \t]*') or ''
        local body = text:sub(#lead + 1)
        local trimmed = body:match('^%s*(.*%S)%s*$') or ''

        -- Strip comments before analyzing
        local beforeC = trimmed:gsub('%-%-.*', '')
        local tokens = {}
        for w in beforeC:gmatch('(%w+)') do
            tokens[#tokens + 1] = w
        end

        -- Count how many 'end' tokens appear consecutively
        local endCount = 0
        while tokens[endCount + 1] == 'end' do
            endCount = endCount + 1
        end

        -- Calculate intended indentation level
        local level = #blockStack - endCount
        if level < 0 then level = 0 end

        -- Convert leading whitespace to tabs based on indentation level
        local totalSpaces = getLeadingSpaceCount(text)
        local tabs = math.floor(totalSpaces / tabSize)
        local spaces = totalSpaces % tabSize
        if tabs < level then
            tabs = level
            spaces = 0
        end
        if spaces >= partialTabThreshold then
            tabs = tabs + 1
            spaces = 0
        end

        -- Compose new line with tabs and optional spaces
        newLines[ln] = string.rep('\t', tabs) .. string.rep(' ', spaces) .. body

        -- Adjust block stack for inline 'end' tokens
        for i = 1, endCount do
            if blockStack[#blockStack] == 'if_block' then
                table.remove(blockStack)
            end
        end

        -- Handle explicit "end" line
        if beforeC:match('^end$') then
            if #blockStack > 0 then
                table.remove(blockStack)
            end
        end

        -- Update block stack for opening constructs
        local first = trimmed:match('^(%w+)') or ''
        if first == 'function' or (first == 'local' and trimmed:match("^local%s+function")) then
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
                end
                local w = rest:match('^(%w+)')
                local k = {
                    ["if"] = 1, ["for"] = 1, ["while"] = 1, ["function"] = 1,
                    ["repeat"] = 1, ["do"] = 1, ["end"] = 1,
                    ["else"] = 1, ["elseif"] = 1, ["until"] = 1,
                    ["return"] = 1, ["break"] = 1, ["local"] = 1
                }
                if w and k[w] then push = false end
            end
            if push then table.insert(blockStack, 'if_block') end
        elseif first == 'for' or first == 'while' or first == 'repeat' or first == 'do' then
            table.insert(blockStack, 'general')
        elseif first == 'else' or first == 'elseif' then
            table.insert(blockStack, 'if_block')
        end
    end

    -- Replace lines in the editor with formatted versions
    for ln = startLn, endLn do
        local old = editor:GetLine(ln) or ''
        local new = newLines[ln]
        if old ~= new then
            local p = editor:PositionFromLine(ln)
            editor.TargetStart = p
            editor.TargetEnd = p + #old
            editor:ReplaceTarget(new)
        end
    end

    editor:EndUndoAction() 
end
