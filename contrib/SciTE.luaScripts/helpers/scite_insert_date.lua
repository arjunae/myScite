
--When I need to insert the date and time into the current editing position, I'm looking for my smart phone or a calender, but it's not only a troublesome but also makes errata frequently. So I love this simple lua script SciteInsertDate.

-- Insert date string at current position
-- 2013.03.31 by lee.sheen at gmail dot com

scite_Command {
  'Insert Date|InsertDate|Alt+Shift+D',
}

function InsertDate ()
  local date_string = os.date("%Y.%m.%d %H:%M")
  -- Tags used by os.date:
  --   %a abbreviated weekday name (e.g., Wed)
  --   %A full weekday name (e.g., Wednesday)
  --   %b abbreviated month name (e.g., Sep)
  --   %B full month name (e.g., September)
  --   %c date and time (e.g., 09/16/98 23:48:10)
  --   %d day of the month (16) [01-31]
  --   %H hour, using a 24-hour clock (23) [00-23]
  --   %I hour, using a 12-hour clock (11) [01-12]
  --   %M minute (48) [00-59]
  --   %m month (09) [01-12]
  --   %p either "am" or "pm" (pm)
  --   %S second (10) [00-61]
  --   %w weekday (3) [0-6 = Sunday-Saturday]
  --   %x date (e.g., 09/16/98)
  --   %X time (e.g., 23:48:10)
  --   %Y full year (1998)
  --   %y two-digit year (98) [00-99]
  --   %% the character '%'

  editor:AddText(date_string)
end
