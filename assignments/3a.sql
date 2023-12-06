create table rows_with_index (i int, value text);

-- Add row numbers
insert into rows_with_index (i, value)
select
    (row_number() over(order by (select null)) - 1),
    value
from
    assignment_3a;

-- Parse rows into cells
create table cells (x int, y int, value text);
insert into cells (x, y, value)
select
    (row_number() over (order by g.i) - 1) % (select length(value) from assignment_3a limit 1),
    g.i,
    s.token
from
    rows_with_index as g
cross join lateral unnest(string_to_array(g.value, NULL)) as s(token);

-- Pick a cell if its a number and it has at least one special character around it.
-- X X X
-- X _ X
-- X X X
create table cells_picked (x int, y int, value text);
insert into cells_picked (x, y, value)
select
    x,
    y,
    value
from
    cells as a
where
    (  (select value from cells where x = a.x - 1 and y = a.y - 1 limit 1) ~ '[^\\0-9.]'
    or (select value from cells where x = a.x     and y = a.y - 1 limit 1) ~ '[^\\0-9.]'
    or (select value from cells where x = a.x + 1 and y = a.y - 1 limit 1) ~ '[^\\0-9.]'

    or (select value from cells where x = a.x - 1 and y = a.y     limit 1) ~ '[^\\0-9.]'
    or (select value from cells where x = a.x + 1 and y = a.y     limit 1) ~ '[^\\0-9.]'

    or (select value from cells where x = a.x - 1 and y = a.y + 1 limit 1) ~ '[^\\0-9.]'
    or (select value from cells where x = a.x     and y = a.y + 1 limit 1) ~ '[^\\0-9.]'
    or (select value from cells where x = a.x + 1 and y = a.y + 1 limit 1) ~ '[^\\0-9.]')
    and value ~ '[0-9]';

-- Select one cell left from already picked cells and add it to the picked cells if it has a number in it
-- --->
-- <---
do $$
    declare
        i int;
    begin
    for i in 1..5 loop -- Assuming integers have a maximum length of 5 digits
        insert into cells_picked (x, y, value)
        select unpicked.x, unpicked.y, unpicked.value from cells_picked as picked
        inner join cells as unpicked
            on (unpicked.x = picked.x - 1 and unpicked.y = picked.y)
            or (unpicked.x = picked.x + 1 and unpicked.y = picked.y)
        where
            unpicked.value ~ '[0-9]'
            and (select count(*) from cells_picked where x = unpicked.x and y = unpicked.y) = 0;
    end loop;
end $$;

-- Add cells
insert into cells_picked (x, y, value)
select
    x,
    y,
    ' '
from
    cells
where
    (select count(*) from cells_picked where x = cells.x and y = cells.y) = 0;

create table values_as_strings (value text);

-- Merge cell rows into strings
insert into values_as_strings (value)
select
    concat(string_agg(value, '' order by x), ' ') as result
from
    cells_picked
group by
    y
order by
    y;

select * from values_as_strings;

-- 1. Merge rows into one string
-- 2. Split it into integers
-- 3. Sum the integers
select
    sum(cast(value as int))
from (
    select
        unnest(
            string_to_array(
                btrim(
                    regexp_replace(
                        string_agg(value, ''),
                        '\s+',
                        ' ',
                        'g'
                    )
                )
                ,
                ' '
            )
        ) as value
    from
        values_as_strings
) as a;
