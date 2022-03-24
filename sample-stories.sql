drop table if exists random_sample_100_stories;
create table random_sample_100_stories as 
select id,
row_number() over (order by id) as sid,
sum(gain) as total_upvotes
from dataset join (select id from fullstories order by random() limit 1000) using (id)
where topRank is not null
group by id
-- having total_upvotes > 0 is necessary because, even though all stories start out with a score of 1 (the submission itself is an upvote?),
-- it could be that a story gets no votes while on the top page.
having total_upvotes > 0
limit 100;


drop table if exists random_sample_1000_stories;
create table random_sample_1000_stories as 
select id,
row_number() over (order by id) as sid,
sum(gain) as total_upvotes
from dataset join (select id from fullstories order by random() limit 10000) using (id)
where topRank is not null
group by id
having total_upvotes > 0
limit 1000;
