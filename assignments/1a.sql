select
    sum(
        cast(
            concat(
                substring(a.value, 1, 1),
                substring(a.value, length(a.value), 1)
            )
            as int
        )
    )
from (
    select
        regexp_replace(value, '[a-z]', '', 'g') as value
    from assignment_1a
) as a
