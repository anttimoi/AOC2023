create table game_raw (id int, info text);

-- Input
-- 'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green'
-- Output
-- (1, '3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green')
insert into game_raw (id, info)
select
    cast(replace(split_part(value, ' ', 2), ':', '') as int),
    split_part(value, ': ', 2)
from
    assignment_2b;


create table game_sets (game_id int, set_id int, info text);

-- Input
-- (1, '3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green')
-- Output
-- (1, 1, '3 blue, 4 red')
-- (1, 2, ' 1 red, 2 green, 6 blue')
-- (1, 3, ' 2 green')
insert into game_sets (game_id, set_id, info)
select
    g.id,
    row_number() over (order by g.id),
    s.token
from
    game_raw as g
cross join lateral unnest(string_to_array(info, ';')) as s(token);


create table game_set_colors (game_id int, set_id int, color text, value int);

-- Input
-- (1, 1, '3 blue, 4 red')
-- Output
-- (1, 1, '3 blue', -1)
-- (1, 1, '4 red', -1)
insert into game_set_colors (game_id, set_id, color, value)
select
    g.game_id,
    g.set_id,
    s.color,
    -1
from
    game_sets as g
cross join lateral unnest(string_to_array(g.info, ',')) as s(color);

-- Input
-- (1, 1, '3 blue', -1)
-- Output
-- (1, 1, 'blue', 3)
update game_set_colors
set
    value = cast(split_part(ltrim(color), ' ', 1) as int),
    color = split_part(ltrim(color), ' ', 2);

create table game_set_colors_min (game_id int, color text, min_required_count int);

insert into game_set_colors_min (game_id, color, min_required_count)
select
    game_id,
    color,
    max(value)
from game_set_colors
group by game_id, color
order by game_id, color;

create aggregate multiply(bigint) ( SFUNC = int8mul, STYPE=bigint );


create table game_power (game_id int, power bigint);

insert into game_power (game_id, power)
select game_id, multiply(min_required_count) from game_set_colors_min group by game_id order by game_id;

select sum(power) from game_power;
