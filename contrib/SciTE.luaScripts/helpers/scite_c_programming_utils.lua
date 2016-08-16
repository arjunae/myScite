--A few simple scripts for C programmers from a lua newbie. Work in Progress!

--To do: more expand functions (for, while, if, switch, structs), correct indentation for expand (right now everything must start at the first column), svn support, etc.

    --Author: Christoph Schreiber <c.schreiber at rindergesundheit dot at>
    local function tokenize(str, delim)
        result = {}

        while true do
            local cp = string.find(str, delim)

            if not cp then
                table.insert(result, str)
                return result
            end

            table.insert(result, string.sub(str, 1, cp - 1))
            str = string.sub(str, cp + 1)
        end
    end

    local function expand_cstd_headers(hdrs)
        if not hdrs[2] or hdrs[2] == "" then
            print("error: please supply at least one header")
            return
        end

        for i = 2, table.getn(hdrs) do
            editor:AddText("#include <"..hdrs[i]..".h>\n")
        end
    end

    local function expand_c_headers(hdrs)
        if not hdrs[2] or hdrs[2] == "" then
            print("error: please supply at least one header")
            return
        end

        for i = 2, table.getn(hdrs) do
            editor:AddText("#include \""..hdrs[i]..".h\"\n")
        end
    end

    local function expand_c_main(offset)
        local c_main = {}

        table.insert(c_main, "int main(int argc, char* argv[])")
        table.insert(c_main, "{")
        table.insert(c_main, "\t")
        table.insert(c_main, "")
        table.insert(c_main, "\treturn 0;")
        table.insert(c_main, "}")

        editor:AddText(table.concat(c_main, "\n"))
        editor:GotoPos(offset + 36)
    end

    local function expand_c_once(name, line)
        if not name or name == "" then
            print("error: please supply a header name")
            return
        end

        local once = {}
        local uname = string.upper(name)

        table.insert(once, "#ifndef __"..uname.."_H__")
        table.insert(once, "#define __"..uname.."_H__")
        table.insert(once, "");
        table.insert(once, "");
        table.insert(once, "");
        table.insert(once, "#endif /* __"..uname.."_H__ */")

        editor:AddText(table.concat(once, "\n"))
        editor:GotoLine(line + 3)
    end

    local function expand_bsd_license(author, year)
        if not author or author == "" then
            if props["author.full_name"] then
                author = props["author.full_name"]
            else
                print("error: please supply the author's name")
                return
            end
        end

        local bsd = {}

        table.insert(bsd, "/*")

        if year == nil then
            table.insert(bsd, " * Copyright (c) "..os.date("%Y").." "..author..". All rights reserved.")
        else
            table.insert(bsd, " * Copyright (c) "..year.." "..author..". All rights reserved.")
        end

        table.insert(bsd, " *")
        table.insert(bsd, " * Redistribution and use in source and binary forms, with or without")
        table.insert(bsd, " * modification, are permitted provided that the following conditions")
        table.insert(bsd, " * are met:")
        table.insert(bsd, " *")
        table.insert(bsd, " * 1. Redistributions of source code must retain the above copyright")
        table.insert(bsd, " *    notice, this list of conditions and the following disclaimer.")
        table.insert(bsd, " *")
        table.insert(bsd, " * 2. Redistributions in binary form must reproduce the above copyright")
        table.insert(bsd, " *    notice, this list of conditions and the following disclaimer in the")
        table.insert(bsd, " *    documentation and/or other materials provided with the distribution.")
        table.insert(bsd, " *")
        table.insert(bsd, " * THIS SOFTWARE IS PROVIDED BY "..string.upper(author).." \"AS IS\'' AND")
        table.insert(bsd, " * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE")
        table.insert(bsd, " * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE")
        table.insert(bsd, " * ARE DISCLAIMED. IN NO EVENT SHALL "..string.upper(author).." BE LIABLE")
        table.insert(bsd, " * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL")
        table.insert(bsd, " * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS")
        table.insert(bsd, " * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)")
        table.insert(bsd, " * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT")
        table.insert(bsd, " * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY")
        table.insert(bsd, " * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF")
        table.insert(bsd, " * SUCH DAMAGE.")
        table.insert(bsd, " */")


        editor:AddText(table.concat(bsd, "\n"))
    end

    function expand()
        local line = editor:LineFromPosition(editor.CurrentPos)
        local from = editor:PositionFromLine(line)
        local to = editor.CurrentPos
        local sel = editor:textrange(from, to)

        if not sel or sel == "" then
            print("error: nothing to expand")
            print("valid commands are:")
            print("\tmain - C\'s main()")
            print("\tstdinc,Header[,Header...] - Standard header files")
            print("\tinc,Header[,Header...] - User header files")
            print("\tonce,HeaderName - Header guard")
            print("\tbsd,Author[,Date] - BSD copyright statement")
            return
        end

        local args = tokenize(sel, ',')

        editor:SetSel(from, to)
        editor:ReplaceSel("")

        if args[1] == "stdinc" then
            expand_cstd_headers(args)
        elseif args[1] == "inc" then
            expand_c_headers(args)
        elseif args[1] == "main" then
            expand_c_main(from)
        elseif args[1] == "once" then
            expand_c_once(args[2], line)
        elseif args[1] == "bsd" then
            expand_bsd_license(args[2], args[3])
        else
            print("error: invalid command")
        end
    end

    function hexify_number()
        local sel = editor:GetSelText()

        if not sel or sel == "" then
            return
        end

        editor:ReplaceSel(string.format('0x%08x', tonumber(sel)))
    end

    function calculate()
        local expr = editor:GetSelText()

        if not expr or expr == "" then
            return
        end

        local fn, unused = loadstring("return "..expr)

        if not fn then
            print("error: invalid expression") return
        end

        editor:ReplaceSel(tostring(fn()))
    end

