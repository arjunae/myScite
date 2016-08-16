
--Typografic quotes and auto section closing

--Load this script for .tex files and it will automatically insert \end{group} when you hit enter after a \begin{group}. It's not perfect, but it works most of the time for my LaTeX code formatting style. It will also replace the normal inch-symbols (") with the appropriate (German) symbol ("` and "').

prevquote="'";
nextquote="`";

function ReplaceQuote()
	at = editor.CurrentPos;
	editor:insert(at, nextquote);
	editor:GotoPos(at+1);
	prevquote, nextquote = nextquote, prevquote;
end;


function CheckBlock()
	local m_end = 0;
	local senv, env;
	
	line = editor:LineFromPosition(editor.CurrentPos);
	str = editor:GetLine(line-1);
	
	-- look for last \begin{foo}
	repeat
		senv = env;
		m_start, m_end, env = string.find(str, '\\begin{(.-)}', m_end);
	until m_start == nil;
	
	-- add \end{foo}
	if(senv) then
		local pos = editor.CurrentPos;
		editor:insert(pos,
			"\\end{"..senv..'}');
	end;
end;


function OnChar(char)
	if(char=='"') then
		ReplaceQuote();
	elseif(char=="\n") then
		CheckBlock();
	end;
end;

-- SebastianSteinlechner?

Command shortcuts
This is a framework for mapping e.g. \frac{}{} to a key combination. Sorry, no automation yet, you have to manually add the appropriate command entries in you latex.properties file.

function add_tags(a, b)
	if(editor:GetSelText() ~= '') then
		editor:ReplaceSel(a .. editor:GetSelText() .. b);
	else
		editor:insert(editor.CurrentPos, a..b);
		editor:GotoPos(editor.CurrentPos + string.len(a));
	end;
end

function tex_frac()
	add_tags('\\frac{', '}{}');
end;

function tex_up()
	add_tags('^{', '}');
end;

function tex_down()
	add_tags('_{', '}');
end;

-- SebastianSteinlechner?

--Tab arrays to Tex arrays
--If you copy&paste a table from e.g. Excel / OOo Calc, it will be tab separated. Mark the lines and run this --script over it, and it will come out with tabs (\t) replaced by \t&, and lines ended with \\.

function tex_makearray()
	if(editor:GetSelText() == '') then
		return;
	end;
	
	local mytext = editor:GetSelText();
	mytext = string.gsub(mytext, "\t", "\t& ");
	mytext = string.gsub(mytext, "\n", "\\\\\n");
	editor:ReplaceSel(mytext);
end;
