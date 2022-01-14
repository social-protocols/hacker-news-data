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
select avg(daygain) from (select date(sampleTime, 'unixepoch'), min(gain), max(gain), sum(gain) as daygain, count(distinct tick) from dataset where samplingWindow >= 3 group by date(sampleTime, 'unixepoch') having count(distinct tick) > 1400);

-- quality distribution:
select localQuality4, count(*), avg(score), min(bestTopRank), avg(bestTopRank), id from quality group by floor(localQuality4*100) limit 100;



.mode column
.headers on
.nullvalue (NULL)
SELECT "best stories:";
select id, localQuality4, score, bestTopRank, avgTopRank, samples, predictionSamples, 'https://news.ycombinator.com/item?id=' || id from quality order by localQuality4 desc limit 30;
select id, (localQuality4+localQuality5)/2, score, bestTopRank, avgTopRank, samples, predictionSamples, 'https://news.ycombinator.com/item?id=' || id from quality order by (localQuality4+localQuality5)/2 desc limit 30;
SELECT "worst stories:";
select id, localQuality5, score, bestTopRank, avgTopRank, samples, predictionSamples, 'https://news.ycombinator.com/item?id=' || id from quality order by localQuality5 asc  limit 30;

