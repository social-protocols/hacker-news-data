.bail on
.output /dev/null
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = 10000;
PRAGMA mmap_size = 30000000000;
.output


CREATE TABLE dataset (
    id integer not null,
    score integer,
    descendants integer not null,
    submissionTime integer not null,
    sampleTime integer not null,
    tick integer not null,
    topRank integer,
    newRank integer,
    bestRank integer,
    askRank integer,
    showRank integer,
    jobRank integer
);


.mode ascii
.separator "\t" "\n"
.import --skip 1 /dev/stdin dataset



.headers off


select "Deleting jobs...";
-- jobs never appear on the new-page and never receive any votes, but may appear on the frontpage
delete from dataset where id in (select distinct id from dataset where jobrank != "\N");


select "Converting NULL values...";
update dataset set topRank = null where topRank = "\N";
update dataset set newRank = null where newRank = "\N";
update dataset set bestRank = null where bestRank = "\N";
update dataset set askRank = null where askRank = "\N";
update dataset set showRank = null where showRank = "\N";
update dataset set jobRank = null where jobRank = "\N";
update dataset set score = null where score = "\N";
update dataset set descendants = 0 where descendants = "\N";


select "Creating indices...";
create index id_age_idx on dataset(id,sampleTime-submissionTime);
create unique index id_sampleTime_idx on dataset(id, sampleTime);
create index id_idx on dataset(id);


select "Calculating fully tracked stories...";
create table fullstories as
select id
  from dataset
  where submissionTime < (select max(sampleTime) - (3600 * 24 * 2) from dataset) -- keep submissions which were possible to track for at least 48h
  group by id
  having
        min(sampleTime - submissionTime) < 180 -- have samples close to submission time
    and max(newRank) > 85 -- story made it through whole new-site
    and count(*) > 50; -- story has at least 50 data points;
create unique index fullstories_id_idx on fullstories(id);


select "Calculating gain (score difference to previous sample point)...";
alter table dataset add column gain integer;
update dataset as d set gain = (
  select (case when gain is null then null when gain >= 0 then gain else 0 end)
  from (select id, sampleTime, (score-lag(score) over (partition by id order by sampleTime)) as gain from dataset)
  where id = d.id and sampleTime = d.sampleTime
);
-- first sample (first tick) is undefined because we don't know the gain
delete from dataset where gain is null;


SELECT "Calculating expected upvotes (predicted gain)...";
-- we convert nulls to -1, to have a faster join. joins usually ignore null and need special treatment.
create table expectedUpvotes as
    select
        /* ifnull(pow(2, floor(log2(d.topRank))), -1) as topRankBin, */
        ifnull(d.topRank, -1) as topRankBin,
        /* ifnull(pow(2, floor(log2(d.newRank))), -1) as newRankBin, */
        /* ifnull(pow(2, floor(log2(d.bestRank))), -1) as bestRankBin, */
        /* ifnull(pow(2, floor(log2(d.askRank))), -1) as askRankBin, */
        /* ifnull(pow(2, floor(log2(d.showRank))), -1) as showRankBin, */
        /* ifnull(pow(2, floor(log2(d.jobRank))), -1) as jobRankBin, */
        /* ifnull(pow(2, floor(log2(d.score))), -1) as scoreBin, */
        /* ifnull(pow(2, floor(log2(d.descendants))), -1) as descendantsBin, */
        cast(strftime('%H', sampleTime, 'unixepoch') as int) as timeofdayBin,
        cast(strftime('%w', sampleTime, 'unixepoch') as int) as dayofweekBin,
        avg(gain) as avgGain,
        min(gain) as minGain,
        max(gain) as maxGain,
        count(*) as samples
    from fullstories f
    join dataset d on d.id = f.id
    where gain is not null
    group by
        topRankBin,
        /* newRankBin, */
        /* bestRankBin, */
        /* askRankBin, */
        /* showRankBin, */
        /* jobRankBin, */
        /* scoreBin, */
        /* descendantsBin, */
        timeofdayBin,
        dayofweekBin;
create unique index expectedUpvotes_idx on expectedUpvotes(
        topRankBin,
        /* newRankBin, */
        /* bestRankBin, */
        /* askRankBin, */
        /* showRankBin, */
        /* jobRankBin, */
        /* scoreBin, */
        /* descendantsBin, */
        timeofdayBin,
        dayofweekBin
);

