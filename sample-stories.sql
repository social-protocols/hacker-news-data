drop table if exists random_sample_100_stories;
create table random_sample_100_stories as 
select id,
row_number() over (order by id) as sid,
sum(gain) as total_upvotes
from dataset join (select id from fullstories order by random() limit 1000) using (id)
where topRank is not null
group by id
limit 100;


drop table if exists random_sample_1000_stories;
create table random_sample_1000_stories as 
select id,
row_number() over (order by id) as sid,
sum(gain) as total_upvotes
from dataset join (select id from fullstories order by random() limit 10000) using (id)
where topRank is not null
group by id
limit 1000;
