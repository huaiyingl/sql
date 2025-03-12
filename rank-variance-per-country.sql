/*
https://www.youtube.com/watch?v=PlpUo6bHsBQ
Which countries have risen in the rankings based on the number of comments between Dec 2019 vs Jan 2020? Hint: Avoid gaps between ranks when ranking countries.


country -> users
number of comments -> comments
date -> users

join users and comments on user_id, left join

approach:
*/

-- join users and comments on user_id (left)
-- filter for given time range 
-- exclude rows where country is empty
-- sum the number of comments per country
-- create subqueries/CTEs for dec and jan
-- use a left join jan on dec, since we only care about the rise
-- rank 2019 comment counts and 2020 comment counts
-- apply final filter to fetch only counties with ranking decline


with dec_comments as (
    select 
        country,
        sum(number_of_comments) as number_comments_dec,
        dense_rank() over(order by sum(number_of_comments) desc) as country_rank
    from fb_active_users as a
    left join fb_comments_count as b
    on a.user_id = b.user_id
    where created_at <= '2019-12-31' and created_at >= '2019-12-01' and country is not null
    group by country
),
jan_comments as (
    select 
        country,
        sum(number_of_comments) as number_comments_jan,
        dense_rank() over(order by sum(number_of_comments) desc) as country_rank
    from fb_active_users as a
    left join fb_comments_count as b
    on a.user_id = b.user_id
    where created_at <= '2020-01-31' and created_at >= '2020-01-01' and country is not null
    group by country
)

select j.country 
from jan_comments j
left join dec_comments d
on j.country = d.country
where j.country_rank < d.country_rank or d.country is null;








