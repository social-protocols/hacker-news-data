.bail on
.output /dev/null
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size=10000;
PRAGMA mmap_size = 30000000000;
.output

select "Daily votes arrival";
select avg(daygain) from (select date(sampleTime, 'unixepoch'), min(gain), max(gain), sum(gain) as daygain, count(distinct tick) from dataset where samplingWindow >= 3 group by date(sampleTime, 'unixepoch') having count(distinct tick) > 1400);
