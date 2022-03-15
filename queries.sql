.bail on
.output /dev/null
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = 10000;
PRAGMA mmap_size = 30000000000;
.output

select "Daily votes arrival";
-- only take fully sampled days (1 sample / min): count(distinct tick) > 1400
select avg(daygain) from (select date(sampleTime, 'unixepoch'), min(gain), max(gain), sum(gain) as daygain, count(distinct tick) from dataset group by date(sampleTime, 'unixepoch') having count(distinct tick) > 1400);





.mode column
.headers on
.nullvalue (NULL)
SELECT "best stories:";
select id, qualitySpeed, score, bestTopRank, samples, predictionSamples, 'https://news.ycombinator.com/item?id=' || id from quality where samples >= 20 order by qualitySpeed desc limit 30;

SELECT "worst stories:";
select id, qualitySpeed, score, bestTopRank, samples, predictionSamples, 'https://news.ycombinator.com/item?id=' || id from quality where samples >= 20 order by qualitySpeed asc  limit 30;


select "Quality Distribution";
.headers on
.mode column
select qualitySpeed, count(*), avg(score), min(bestTopRank), avg(bestTopRank), 'https://news.ycombinator.com/item?id=' || id as example_story from quality where samples >= 20 group by floor(qualitySpeed*10) limit 100;
