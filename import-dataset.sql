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
create index sampleTime_id_idx on dataset(sampleTime, id);
create index id_sampleTime_idx on dataset(id, sampleTime);
create index id_age_idx on dataset(id,sampleTime-submissionTime);
create index date_idx on dataset(date(sampleTime, 'unixepoch'));
create index topRank_idx on dataset(topRank);

# delete from dataset where id = -1;


SELECT "Calculating fullstories...";
create table fullstories as select distinct id from dataset where (sampleTime-submissionTime) < 180;
create unique index fullstories_id_idx on fullstories(id);


SELECT "Calculating gain...";
alter table dataset add column gain integer;
update dataset as d set gain = (select gain from (select id, sampleTime, (score-lag(score) over (partition by id order by sampleTime)) as gain from dataset) where id = d.id and sampleTime = d.sampleTime);

SELECT "toprank gain...";
create table topRankGain as select topRank, avg(gain) as sumGain from dataset where topRank is not null group by topRank order by topRank;
create unique index toprankgain_toprank_idx on toprankgain(toprank);

alter table dataset add column usualTopRankGain integer;
update dataset as d set usualTopRankGain = (select sumGain from topRankGain trg where d.topRank = trg.topRank);


SELECT "quality...";
create table quality as
    select d.id,
        avg(cast(gain as real) / usualTopRankGain) as quality,
        max(score) as score,
        min(topRank) as bestTopRank,
        count(*) as samples
    from dataset d join fullstories f on d.id = f.id
    where
        samplingWindow >= 3
        and gain is not null
        and usualTopRankGain is not null
    group by d.id;
create unique index qality_id_idx on quality(id);
create index quality_quality_idx on quality(quality);
