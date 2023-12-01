create table digit_indexes (value text, digit int, reversed boolean, indexof int);

insert into digit_indexes (value, digit, reversed, indexof)
select value, 1, false, position('one' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 1, false, position('1' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 1, true, position('eno' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 1, true, position('1' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 2, false, position('two' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 2, false, position('2' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 2, true, position('owt' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 2, true, position('2' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 3, false, position('three' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 3, false, position('3' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 3, true, position('eerht' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 3, true, position('3' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 4, false, position('four' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 4, false, position('4' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 4, true, position('ruof' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 4, true, position('4' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 5, false, position('five' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 5, false, position('5' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 5, true, position('evif' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 5, true, position('5' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 6, false, position('six' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 6, false, position('6' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 6, true, position('xis' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 6, true, position('6' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 7, false, position('seven' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 7, false, position('7' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 7, true, position('neves' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 7, true, position('7' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 8, false, position('eight' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 8, false, position('8' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 8, true, position('thgie' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 8, true, position('8' in reverse(value)) from assignment_1b;

insert into digit_indexes (value, digit, reversed, indexof)
select value, 9, false, position('nine' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 9, false, position('9' in value) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 9, true, position('enin' in reverse(value)) from assignment_1b;
insert into digit_indexes (value, digit, reversed, indexof)
select value, 9, true, position('9' in reverse(value)) from assignment_1b;

delete from digit_indexes where indexof = 0; -- Remove digits that are not found in input values

create table digits (value text, digit_1 int, digit_2 int);

insert into digits (value, digit_1, digit_2)
select
    a.value,
    (
        select digit
        from digit_indexes as b
        where
            b.value = a.value
            and b.reversed = false
        order by indexof asc
        limit 1
    ) as digit_1,
    (
        select digit
        from digit_indexes as b
        where
            b.value = a.value
            and b.reversed = true
        order by indexof asc
        limit 1
    ) as digit_2
from assignment_1b as a;

select sum(cast(concat(digit_1, digit_2) as int)) from digits;
