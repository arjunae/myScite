   /* 
   Test SQL
   */

select
    c1 as c1,
    c2 as c2
from
    table "some table with spaces" -- comment
    /* long
        comment */
where
    t.x = (1345 + 554 % 2)*(a/b)
    and t.y = 'abc\nd'
	
alter table create trigger as
begin

end

