create table games (id int, winning_numbers text, card_numbers text);

insert into games (id, winning_numbers, card_numbers)
select
    id,
    regexp_replace(winning_numbers, '\s+', ' ', 'g') as winning_numbers,
    regexp_replace(card_numbers, '\s+', ' ', 'g') as card_numbers
from (
    select
        cast(substr(value, 5, position(':' in value) - 5) as int) as id,
        btrim(substr(value, position(':' in value) + 1, position('|' in value) - position(':' in value) - 1)) as winning_numbers,
        btrim(substr(value, position('|' in value) + 1, length(value))) as card_numbers
    from assignment_4a
) as a;

create table game_winning_number (id int, number int);
create table game_card_number (id int, number int);

insert into game_winning_number (id, number)
select
    id,
    unnest(string_to_array(winning_numbers, ' '))::int as number
from games;

insert into game_card_number (id, number)
select
    id,
    unnest(string_to_array(card_numbers, ' '))::int as number
from games;

select
    sum(points) as total_points
from (
    select
        cast(pow(2, count(*) - 1) as int) as points
    from (
        select
            game.id, win.number
        from game_card_number as game
        inner join game_winning_number as win
        on game.id = win.id
            and game.number = win.number
    ) as a
    group by id
) as b;
