.bail on
.output /dev/null
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size=10000;
PRAGMA mmap_size = 30000000000;
.output

CREATE TABLE dataset (
    id integer not null,
    score integer,
    descendants integer not null,
    submissionTime integer not null,
    sampleTime integer not null,
    tick integer not null,
    samplingWindow integer not null,
    topRank integer,
    newRank integer,
    bestRank integer,
    askRank integer,
    showRank integer,
    jobRank integer
);





.mode csv
.import /dev/stdin dataset



.headers off


-- TODO: remove from dataset itself instead of deleting here
select "deleting old sampling windows";
delete from dataset where samplingWindow < 3;

select "topRank convert NULL";
update dataset set topRank = null where topRank = "NULL";
select "newRank convert NULL";
update dataset set newRank = null where newRank = "NULL";
select "bestRank convert NULL";
update dataset set bestRank = null where bestRank = "NULL";
select "askRank convert NULL";
update dataset set askRank = null where askRank = "NULL";
select "showRank convert NULL";
update dataset set showRank = null where showRank = "NULL";
select "jobRank convert NULL";
update dataset set jobRank = null where jobRank = "NULL";
select "score convert NULL";
update dataset set score = null where score = "NULL";
select "descendants convert NULL";
update dataset set descendants = 0 where descendants = "NULL";




SELECT "Creating indices...";
create index id_age_idx on dataset(id,sampleTime-submissionTime);
create index id_sampleTime_idx on dataset(id, sampleTime); -- TODO: should be a unique index, but there are many entries with duplicate sampleTime but different tick



SELECT "Calculating fullstories...";
create table fullstories as select distinct id from dataset where (sampleTime-submissionTime) < 180;
create unique index fullstories_id_idx on fullstories(id);


SELECT "Calculating gain...";
alter table dataset add column gain integer;
update dataset as d set gain = (select (case when gain is null then null when gain >= 0 then gain else 0 end) from (select id, sampleTime, (score-lag(score) over (partition by id order by sampleTime)) as gain from dataset) where id = d.id and sampleTime = d.sampleTime);
-- when score is still 1, no upvotes can have happened before that
update dataset set gain = 0 where gain is null and score = 1;


SELECT "predicted gain...";
-- TODO: time of day: cast(strftime('%H', sampleTime, 'unixepoch') as int)
-- we convert nulls to -1, to have a faster join. joins usually ignore null and need special treatment.
create table predictedGain as
    select
        ifnull(topRank, -1) as topRank,
        ifnull(newRank, -1) as newRank,
        ifnull(bestRank, -1) as bestRank,
        ifnull(askRank, -1) as askRank,
        ifnull(showRank, -1) as showRank,
        ifnull(jobRank, -1) as jobRank,
        ifnull(score, -1) as score,
        cast(strftime('%H', sampleTime, 'unixepoch') as int) as timeofday,
        --TODO: day of week
        --TODO: descendants
        --TODO: age
        avg(gain) as avgGain,
        min(gain) as minGain,
        max(gain) as maxGain,
        count(*) as samples
    from fullstories f
    join dataset d on d.id = f.id
    where gain is not null
    group by topRank, newRank, bestRank, askRank, showRank, jobRank, score, timeofday
    order by topRank, newRank, bestRank, askRank, showRank, jobRank, score, timeofday;
create unique index predictedGain_idx on predictedGain(toprank, newrank, bestRank, askRank, showRank, jobRank, score, timeofday);

SELECT "quality...";
create table quality as
    select d.id,
        -- todo: what if sum(prediction) = 0 ? -> division by 0
        cast(sum(gain) as real) / sum(mg.avgGain) as qualityQuotient,
        cast(sum(gain) as real) - sum(mg.avgGain) as qualityDifference,
        (cast(sum(gain) as real) - sum(mg.avgGain)) / sum(gain) as qualityDifferenceNormalized,
        (cast(sum(gain) as real) - sum(mg.avgGain)) / sum(mg.avgGain) as qualityDifferenceNormalized2,
        avg((gain - mg.avgGain) / d.score) as localQuality,
        avg((gain - mg.avgGain) / (mg.maxGain - mg.minGain)) as localQuality2,
        avg((gain - mg.minGain) / (mg.maxGain - mg.minGain)) as localQuality3,
        avg((gain - mg.minGain) / cast(1 + mg.maxGain - mg.minGain as real)) as localQuality4,
        max(d.score) as score,
        min(d.topRank) as bestTopRank,
        count(*) as samples,
        sum(mg.samples) as predictionSamples
    from fullstories f
    join dataset d on d.id = f.id
    join predictedGain mg on
            mg.topRank  = ifnull(d.topRank, -1)
        and mg.newRank  = ifnull(d.newRank, -1)
        and mg.bestRank = ifnull(d.bestRank, -1)
        and mg.askRank  = ifnull(d.askRank, -1)
        and mg.showRank = ifnull(d.showRank, -1)
        and mg.jobRank  = ifnull(d.jobRank, -1)
        and mg.score    = ifnull(d.score, -1)
        and mg.timeofday = cast(strftime('%H', sampleTime, 'unixepoch') as int)
    where
        gain is not null
        and mg.samples >= 10
    group by f.id
    ;
create unique index qality_id_idx on quality(id);
create index quality_qualityq_idx on quality(qualityQuotient);
create index quality_qualityd_idx on quality(qualityDifference);
create index quality_qualitydn_idx on quality(qualityDifferenceNormalized);

-- to debug quality calculation:

select *, 'https://news.ycombinator.com/item?id=' || id from quality where score >= 5 order by qualityDifferenceNormalized desc limit 10;
select *, 'https://news.ycombinator.com/item?id=' || id from quality where score >= 5 order by qualityDifferenceNormalized asc limit 10;
-- select *, 'https://news.ycombinator.com/item?id=' || id from quality order by qualityDifference desc limit 10;
-- select *, 'https://news.ycombinator.com/item?id=' || id from quality order by qualityDifference asc limit 10;

create view qualitydetails as select d.*, avgGain, minGain, maxGain, samples
-- select d.*, sum(gain), sum(avgGain), samples
-- select d.*, sum(gain), sum(avgGain), min(samples), cast(sum(gain) as real) / sum(mg.avgGain), count(*) as samples
from fullstories f
join dataset d on d.id = f.id
join predictedgain mg on
            mg.topRank  = ifnull(d.topRank, -1)
        and mg.newRank  = ifnull(d.newRank, -1)
        and mg.bestRank = ifnull(d.bestRank, -1)
        and mg.askRank  = ifnull(d.askRank, -1)
        and mg.showRank = ifnull(d.showRank, -1)
        and mg.jobRank  = ifnull(d.jobRank, -1)
        and mg.score    = ifnull(d.score, -1)
        and mg.timeofday = cast(strftime('%H', sampleTime, 'unixepoch') as int);
