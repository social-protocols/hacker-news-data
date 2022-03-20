.bail on

drop table if exists quality;
drop view if exists qualityDebug;


select "Estimating quality...";
drop table if exists quality;
create table quality as
    select d.id,
        sum(gain) as upvotes,
        sum(mg.avgGain) as expectedUpvotes,
        cast(sum(gain) as real) / sum(mg.avgGain) as cumulativeQuality,
        avg(cast(gain as real) / mg.avgGain) as qualitySpeed,
        max(d.score) as score,
        min(d.topRank) as bestTopRank,
        count(*) as samples,
        sum(mg.samples) as predictionSamples
    from fullstories f
    join dataset d on d.id = f.id
    join expectedUpvotes mg on
            /* mg.topRankBin = ifnull(pow(2, floor(log2(d.topRank))), -1) */
            mg.topRankBin = ifnull(d.topRank, -1)
        /* and mg.newRankBin = ifnull(pow(2, floor(log2(d.newRank))), -1) */
        /* and mg.bestRankBin = ifnull(pow(2, floor(log2(d.bestRank))), -1) */
        /* and mg.askRankBin = ifnull(pow(2, floor(log2(d.askRank))), -1) */
        /* and mg.showRankBin = ifnull(pow(2, floor(log2(d.showRank))), -1) */
        /* and mg.jobRankBin = ifnull(pow(2, floor(log2(d.jobRank))), -1) */
        /* and mg.scoreBin = ifnull(pow(2, floor(log2(d.score))), -1) */
        /* and mg.descendantsBin = ifnull(pow(2, floor(log2(d.descendants))), -1) */
        and mg.timeofdayBin = cast(strftime('%H', sampleTime, 'unixepoch') as int)
        and mg.dayofweekBin = cast(strftime('%w', sampleTime, 'unixepoch') as int)
    where
        gain is not null
        and d.topRank is not null
        and mg.samples >= 4 -- arbitrary number
    group by f.id
    ;
create unique index quality_id_idx on quality(id);
create index quality_quality_cq_idx on quality(cumulativeQuality);
create index quality_quality_qs_idx on quality(qualitySpeed);


-- to debug quality calculation:
create view qualityDebug as select d.*, avgGain, minGain, maxGain, samples, 
        (gain / mg.avgGain) as localQuality
from fullstories f
join dataset d on d.id = f.id
join expectedUpvotes mg on
            /* mg.topRankBin = ifnull(pow(2, floor(log2(d.topRank))), -1) */
            mg.topRankBin = ifnull(d.topRank, -1)
        /* and mg.newRankBin = ifnull(pow(2, floor(log2(d.newRank))), -1) */
        /* and mg.bestRankBin = ifnull(pow(2, floor(log2(d.bestRank))), -1) */
        /* and mg.askRankBin = ifnull(pow(2, floor(log2(d.askRank))), -1) */
        /* and mg.showRankBin = ifnull(pow(2, floor(log2(d.showRank))), -1) */
        /* and mg.jobRankBin = ifnull(pow(2, floor(log2(d.jobRank))), -1) */
        /* and mg.scoreBin = ifnull(pow(2, floor(log2(d.score))), -1) */
        /* and mg.descendantsBin = ifnull(pow(2, floor(log2(d.descendants))), -1) */
        and mg.timeofdayBin = cast(strftime('%H', sampleTime, 'unixepoch') as int)
        and mg.dayofweekBin = cast(strftime('%w', sampleTime, 'unixepoch') as int);


