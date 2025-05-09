  /* 
   * Test SQL
   *  long comment *
   */

select
    key1 as c1,
    data2 as c2
from
    table "some table with spaces" -- line comment
    where
    c1 = (1345 + 554 % 2)*(a/b)
    and c2 = 'abc'

alter table create trigger as
begin
 binary -- SQL
 comment -- pSQL
end
