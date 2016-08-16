--The output should look like that of grep or findstr and so F4 'Next Message' should work as expected. 

function SciteListAllOccurances()
  if props.CurrentSelection ~= "" then
    for m in editor:match( "^.*" .. props.CurrentSelection .. ".*$", SCFIND_REGEXP, 0) do
      print(props.FileNameExt .. ":" .. (editor:LineFromPosition(m.pos)+1) .. ":" .. m.text);
    end
  else
    alert("The InternalGrep script only searchs for selected text");
  end
end
