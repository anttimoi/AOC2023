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
    assignment_2a;


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

select * from game_set_colors;


create table invalid_games (game_id int);

-- Get invalid game moves and capture their game ids
insert into invalid_games (game_id)
select
    distinct game_id
from game_set_colors
where
    (color = 'red' and value > 12)
    or (color = 'green' and value > 13)
    or (color = 'blue' and value > 14);

select
    sum(distinct game_id)
from game_set_colors
where
    game_id not in (select game_id from invalid_games);
