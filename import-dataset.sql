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

SELECT "Creating indices...";
create unique index id_sampleTime_idx on dataset(id, sampleTime);
create unique index sampleTime_id_idx on dataset(sampleTime, id);
create index id_samplingwindow on dataset(id, samplingWindow);
create index samplingwindow_id on dataset(samplingWindow, id);
create index id_age_idx on dataset(id,sampleTime-submissionTime);
create index date_idx on dataset(date(sampleTime, 'unixepoch'));
create index topRank_idx on dataset(topRank);
create index topnewbestRankscore_idx on dataset(topRank, newRank, bestRank, score);
create index newRank_idx on dataset(newRank);

# delete from dataset where id = -1;


SELECT "Calculating fullstories...";
create table fullstories as select distinct id from dataset where (sampleTime-submissionTime) < 180 and samplingWindow >= 3;
create unique index fullstories_id_idx on fullstories(id);


SELECT "Calculating gain...";
alter table dataset add column gain integer;
update dataset as d set gain = (select (case when gain is null then null when gain >= 0 then gain else 0 end) from (select id, sampleTime, (score-lag(score) over (partition by id order by sampleTime)) as gain from dataset) where id = d.id and sampleTime = d.sampleTime);
-- when score is still 1, no upvotes can have happened before that
update dataset set gain = 0 where gain is null and score = 1;

SELECT "toprank gain...";
create table topRankGain as select topRank, avg(gain) as avgGain from dataset d join fullstories f on d.id = f.id where topRank is not null and samplingWindow >= 3 group by topRank order by topRank;
create unique index toprankgain_toprank_idx on toprankgain(toprank);

-- SELECT "newrank gain...";
-- create table newRankGain as select newRank, avg(gain) as avgGain from dataset d join fullstories f on d.id = f.id where newRank is not null and samplingWindow >= 3 group by newRank order by newRank;
-- create unique index newrankgain_newrank_idx on newrankgain(newrank);

-- create table rankGain as select topRank, newRank, avg(gain) as avgGain, count(*) as samples from dataset d join fullstories f on d.id = f.id where samplingWindow >= 3 group by topRank, newRank order by topRank, newRank;
-- create unique index rankgain_idx on rankgain(topRank, newRank);

SELECT "predicted gain...";
-- TODO: time of day: cast(strftime('%H', sampleTime, 'unixepoch') as int)
-- we convert nulls to -1, to have a faster join. joins usually ignore null and need special treatment.
create table predictedGain as
    select
        ifnull(topRank, -1) as topRank,
        ifnull(newRank, -1) as newRank,
        ifnull(bestRank, -1) as bestRank,
        ifnull(score, -1) as score,
        avg(gain) as avgGain,
        count(*) as samples
    from fullstories f
    join dataset d on d.id = f.id
    where gain is not null
    group by topRank, newRank, bestRank, score
    order by topRank, newRank, bestRank, score;
create unique index predictedGain_idx on predictedGain(toprank, newrank, bestRank, score);

SELECT "quality...";
create table quality as
    select d.id,
        -- todo: what if sum(prediction) = 0 ? -> division by 0
        cast(sum(gain) as real) / sum(mg.avgGain) as qualityQuotient,
        cast(sum(gain) as real) - sum(mg.avgGain) as qualityDifference,
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
        and mg.score    = ifnull(d.score, -1)
    where
        gain is not null
    group by f.id
    ;
create unique index qality_id_idx on quality(id);
create index quality_quality_idx on quality(quality);

-- to debug quality calculation:

-- select *, 'https://news.ycombinator.com/item?id=' || id from quality where score >= 10 order by qualityQuotient desc limit 10;
-- select *, 'https://news.ycombinator.com/item?id=' || id from quality where score >= 10 order by qualityQuotient asc limit 10;
-- select *, 'https://news.ycombinator.com/item?id=' || id from quality order by qualityDifference desc limit 10;
-- select *, 'https://news.ycombinator.com/item?id=' || id from quality order by qualityDifference asc limit 10;

-- select d.*, gain, avgGain, samples
-- -- select d.*, sum(gain), sum(avgGain), samples
-- -- select d.*, sum(gain), sum(avgGain), min(samples), cast(sum(gain) as real) / sum(mg.avgGain), count(*) as samples
-- from fullstories f
-- join dataset d on d.id = f.id
-- join predictedgain mg on
--         mg.topRank  = ifnull(d.topRank, -1)
--     and mg.newRank  = ifnull(d.newRank, -1)
--     and mg.bestRank = ifnull(d.bestRank, -1)
--     and mg.score    = ifnull(d.score, -1)

-- where
--     -- gain is not null 
--     f.id = 26917289;
