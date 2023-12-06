create table rows_with_index (i int, value text);

-- Add row numbers
insert into rows_with_index (i, value)
select
    (row_number() over(order by (select null)) - 1),
    value
from
    assignment_3b;

-- Parse rows into cells
create table cells (x int, y int, value text);
insert into cells (x, y, value)
select
    (row_number() over (order by g.i) - 1) % (select length(value) from assignment_3b limit 1),
    g.i,
    s.token
from
    rows_with_index as g
cross join lateral unnest(string_to_array(g.value, NULL)) as s(token);

-- Pick a cell if its a number and it has at least one special character around it.
-- X X X
-- X _ X
-- X X X
create table multipliers (x int, y int, value text);
insert into multipliers (x, y, value)
select
    x,
    y,
    value
from
    cells as a
where
    (  (select value from cells where x = a.x - 1 and y = a.y - 1 limit 1) ~ '[0-9]'
    or (select value from cells where x = a.x     and y = a.y - 1 limit 1) ~ '[0-9]'
    or (select value from cells where x = a.x + 1 and y = a.y - 1 limit 1) ~ '[0-9]'

    or (select value from cells where x = a.x - 1 and y = a.y     limit 1) ~ '[0-9]'
    or (select value from cells where x = a.x + 1 and y = a.y     limit 1) ~ '[0-9]'

    or (select value from cells where x = a.x - 1 and y = a.y + 1 limit 1) ~ '[0-9]'
    or (select value from cells where x = a.x     and y = a.y + 1 limit 1) ~ '[0-9]'
    or (select value from cells where x = a.x + 1 and y = a.y + 1 limit 1) ~ '[0-9]')
    and value = '*';

create table multiplier_numbers (x int, y int, value text, multiplier_x int, multiplier_y int, source_x int, source_y int);

-- Find all numbers adjacent to mulitpliers
insert into multiplier_numbers (x, y, value, multiplier_x, multiplier_y, source_x, source_y)
select c.x, c.y, c.value, m.x, m.y, c.x, c.y
from multipliers as m
join cells as c on
       (c.x = m.x - 1 and c.y = m.y - 1)
    or (c.x = m.x     and c.y = m.y - 1)
    or (c.x = m.x + 1 and c.y = m.y - 1)
    or (c.x = m.x - 1 and c.y = m.y    )
    or (c.x = m.x + 1 and c.y = m.y    )
    or (c.x = m.x - 1 and c.y = m.y + 1)
    or (c.x = m.x     and c.y = m.y + 1)
    or (c.x = m.x + 1 and c.y = m.y + 1)
    and c.value ~ '[0-9]'
where c.value ~ '[0-9]';


-- Select one cell left from already picked cells and add it to the picked cells if it has a number in it
-- --->
-- <---
do $$
    declare
        i int;
    begin
    for i in 1..5 loop -- Assuming integers have a maximum length of 5 digits
        insert into multiplier_numbers (x, y, value, multiplier_x, multiplier_y, source_x, source_y)
        select
            unpicked.x,
            unpicked.y,
            unpicked.value,
            picked.multiplier_x,
            picked.multiplier_y,
            picked.source_x,
            picked.source_y
        from multiplier_numbers as picked
        inner join cells as unpicked
            on (unpicked.x = picked.x - 1 and unpicked.y = picked.y)
            or (unpicked.x = picked.x + 1 and unpicked.y = picked.y)
        where
            unpicked.value ~ '[0-9]'
            and (select count(*) from multiplier_numbers where x = unpicked.x and y = unpicked.y and source_x = picked.source_x and source_y = picked.source_y) = 0;
    end loop;
end $$;

create table multiplier_numbers_2 (x int, y int, value text, multiplier_x int, multiplier_y int, source_x int, source_y int);

-- Remove duplicate numbers
insert into multiplier_numbers_2 (x, y, value, multiplier_x, multiplier_y, source_x, source_y)
select
    x, y, value, multiplier_x, multiplier_y, source_x, source_y
from (
    select
        *,
        row_number() over (partition by x, y order by source_x, source_y) as multiplier_number_index
    from multiplier_numbers
    order by y, x, source_x, source_y
) as a
where a.multiplier_number_index = 1;


create table multiplier_integers (value int, multiplier_x int, multiplier_y int);

-- Join numbers into integers
insert into multiplier_integers (value, multiplier_x, multiplier_y)
select
    cast(string_agg(value, '') as int),
    multiplier_x,
    multiplier_y
from multiplier_numbers_2
group by multiplier_y, multiplier_x, source_y, source_x
order by multiplier_x, multiplier_y;

create aggregate multiply(bigint) ( SFUNC = int8mul, STYPE=bigint );

select sum(product) from (
    select
        multiply(value) as product,
        multiplier_y,
        multiplier_x
    from (
        select
            m.multiplier_x,
            m.multiplier_y,
            m.value
        from multiplier_integers as m
        inner join (
            select multiplier_x, multiplier_y from (
                select count(*) as c, multiplier_x, multiplier_y
                from multiplier_integers
                group by multiplier_x, multiplier_y
                order by multiplier_y, multiplier_x
                ) as a
            where c > 1 -- Remove single multipliers
        ) as b
        on
            m.multiplier_x = b.multiplier_x
            and m.multiplier_y = b.multiplier_y
    ) as c
    group by multiplier_y, multiplier_x -- Multiply together values which have the same multiplier character
) as d;
