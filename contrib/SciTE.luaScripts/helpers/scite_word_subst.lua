
--This is code for a simple replace-on-the-fly facility for SciTE; it's similar to Word's ability to automatically substitute 'the' for 'teh'. Whatever you think about its usefulness (you may agree with Phillipe that makes people lazy) it shows how a SciTE Lua extension can access each word as it is typed. We don't use the same word list for every file type ('fun' expands to 'function' for Lua and Pascal files, not for text!); this is done by watching when the active file changes, either by opening (use OnOpen) or by switching buffers (use OnSwitchFile)

    -- doing word substitutions on the fly!

    local txt_words = {
     teh='the', wd='would',cd='could'   
    }

    local pascal_words = {
     fun='function',lfun='local function',
     proc='procedure',virt='virtual',ctor='constructor',
     dtor='destructor',prog='program',
     int='integer',dbl='double',str='string'
    }

    local words

    function switch_substitution_table()
      local ext = props['FileExt']
      if ext == 'pas' or ext == 'lua' then 
        words = pascal_words  
      elseif ext == 'txt' then
        words = txt_words
      else
        words = nil
      end
    end

    local function word_substitute(word)
      return words and words[word] or word
    end

    local word_start,in_word,current_word
    local find = string.find

    function OnChar(s)
     if not in_word then
        if find(s,'%w') then 
          -- we have hit a word!
          word_start = editor.CurrentPos
          in_word = true
          current_word = s
        end
     else -- we're in a word
       -- and it's another word character, so collect
       if find(s,'%w') then   
          current_word = current_word..s
       else
        -- leaving a word; see if we have a substitution
          local word_end = editor.CurrentPos
          local subst = word_substitute(current_word)
          if subst ~= current_word then
             editor:SetSel(word_start-1,word_end-1)
             -- this is somewhat ad-hoc logic, but
             -- SciTE is handling space differently.
             local was_whitespace = find(s,'%s')
             if was_whitespace then
                subst = subst..s
             end
    	 editor:ReplaceSel(subst)
             word_end = editor.CurrentPos
             if not was_whitespace then
                editor:GotoPos(word_end + 1)
             end
          end
          in_word = false
       end   
      end 
      -- don't interfere with usual processing!
      return false
    end  

    function OnOpen(f)
      switch_substitution_table()
    end

    function OnSwitchFile(f)
      switch_substitution_table()
    end

--SteveDonovan 