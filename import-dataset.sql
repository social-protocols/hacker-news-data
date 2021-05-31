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
    topRank integer,
    descendants integer not null,
    submissionTime integer not null,
    sampleTime integer not null,
    samplingWindow integer not null,
    tick integer not null,
    newRank integer,
    bestRank integer,
    askRank integer,
    showRank integer,
    jobRank integer
);





.mode csv
.import /dev/stdin dataset

.headers off



-- TODO: id = -1
-- update dataset set topRank = null where topRank = -1;

SELECT "Creating indices...";
create index tick_id_idx on dataset(tick, id);
create index id_tick_idx on dataset(id, tick);
create index id_age_idx on dataset(id,sampleTime-submissionTime);
create index date_idx on dataset(date(sampleTime, 'unixepoch'));

delete from dataset where id = -1;

SELECT "Calculating fullstories...";
create table fullstories as select distinct id from dataset where (sampleTime-submissionTime) < 180;

SELECT "Calculating gain...";
alter table dataset add column gain integer;
update dataset as d set gain = (select gain from (select id, sampleTime, (score-lag(score) over (partition by id order by tick)) as gain from dataset) where id = d.id and sampleTime = d.sampleTime);

