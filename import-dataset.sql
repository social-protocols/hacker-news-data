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


-- update dataset set topRank = null where topRank = -1;
create index tick_id_idx on dataset(tick, id);
create index id_tick_idx on dataset(id, tick);

create view gain as select id, score, tick, score-(lag(score) over (partition by id order by tick)) as gain from dataset;

.mode csv
.import /dev/stdin dataset

.headers off


