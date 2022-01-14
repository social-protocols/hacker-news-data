.bail on

drop table if exists predictedGain;
drop table if exists quality;
drop view if exists qualityDetails;



SELECT "predicted gain...";
-- we convert nulls to -1, to have a faster join. joins usually ignore null and need special treatment.
create table predictedGain as
    select
        ifnull(pow(2, floor(log2(d.topRank))), -1) as topRankBin,
        /* ifnull(pow(2, floor(log2(d.newRank))), -1) as newRankBin, */
        /* ifnull(pow(2, floor(log2(d.bestRank))), -1) as bestRankBin, */
        /* ifnull(pow(2, floor(log2(d.askRank))), -1) as askRankBin, */
        /* ifnull(pow(2, floor(log2(d.showRank))), -1) as showRankBin, */
        /* ifnull(pow(2, floor(log2(d.jobRank))), -1) as jobRankBin, */
        /* ifnull(pow(2, floor(log2(d.score))), -1) as scoreBin, */
        /* ifnull(pow(2, floor(log2(d.descendants))), -1) as descendantsBin, */
        cast(strftime('%H', sampleTime, 'unixepoch') as int)/4*4 as timeofdayBin,
        cast(strftime('%w', sampleTime, 'unixepoch') as int) as dayofweekBin,
        avg(gain) as avgGain,
        min(gain) as minGain,
        max(gain) as maxGain,
        count(*) as samples
    from dataset d 
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
create unique index predictedGain_idx on predictedGain(
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

SELECT "quality...";
create table quality as
    select d.id,
        -- todo: what if sum(prediction) = 0 ? -> division by 0
        cast(sum(gain) as real) / sum(mg.avgGain) as cumulativeQuality,
        /* cast(sum(gain) as real) - sum(mg.avgGain) as qualityDifference, */
        /* (cast(sum(gain) as real) - sum(mg.avgGain)) / sum(gain) as qualityDifferenceNormalized, */
        /* (cast(sum(gain) as real) - sum(mg.avgGain)) / sum(mg.avgGain) as qualityDifferenceNormalized2, */
	-- quality formulas
        avg((gain / mg.avgGain)) as localQuality,
        /* avg((gain - mg.avgGain) / (mg.maxGain - mg.minGain)) as localQuality2, */
        /* avg((gain - mg.minGain) / (mg.maxGain - mg.minGain)) as localQuality3, */
        /* avg((gain - mg.minGain) / cast(1 + mg.maxGain - mg.minGain as real)) as localQuality4, -- (gain - mingain) shift into full amplitude */
        /* (sum(gain) - sum(mg.minGain)) / cast(1 + sum(mg.maxGain) - sum(mg.minGain) as real) as localQuality5, */
        max(d.score) as score,
        min(d.topRank) as bestTopRank,
        sum(d.topRank) as sumTopRank,
        avg(d.topRank) as avgTopRank,
        count(*) as samples,
        sum(mg.samples) as predictionSamples,
        max(d.score) / sum(1.0/d.topRank) as quality6,
        sum(cast(d.gain as real) / d.topRank) as quality7
    from fullstories f
    join dataset d on d.id = f.id
    join predictedGain mg on
            mg.topRankBin = ifnull(pow(2, floor(log2(d.topRank))), -1)
        /* and mg.newRankBin = ifnull(pow(2, floor(log2(d.newRank))), -1) */
        /* and mg.bestRankBin = ifnull(pow(2, floor(log2(d.bestRank))), -1) */
        /* and mg.askRankBin = ifnull(pow(2, floor(log2(d.askRank))), -1) */
        /* and mg.showRankBin = ifnull(pow(2, floor(log2(d.showRank))), -1) */
        /* and mg.jobRankBin = ifnull(pow(2, floor(log2(d.jobRank))), -1) */
        /* and mg.scoreBin = ifnull(pow(2, floor(log2(d.score))), -1) */
        /* and mg.descendantsBin = ifnull(pow(2, floor(log2(d.descendants))), -1) */
        and mg.timeofdayBin = cast(strftime('%H', sampleTime, 'unixepoch') as int)/4*4
        and mg.dayofweekBin = cast(strftime('%w', sampleTime, 'unixepoch') as int)
    where
        d.topRank is not null
        and mg.samples >= 4
    group by f.id
    ;
create unique index quality_id_idx on quality(id);
create index quality_cumqualityq_idx on quality(cumulativeQuality);
create index quality_locqualityq_idx on quality(localQuality);
create index quality_qualityd_idx on quality(qualityDifference);
create index quality_qualitydn_idx on quality(qualityDifferenceNormalized);

-- to debug quality calculation:
create view qualitydetails as select d.*, avgGain, minGain, maxGain, samples, 
        (gain / mg.avgGain) as localQuality
-- select d.*, sum(gain), sum(avgGain), samples
-- select d.*, sum(gain), sum(avgGain), min(samples), cast(sum(gain) as real) / sum(mg.avgGain), count(*) as samples
from fullstories f
join dataset d on d.id = f.id
join predictedgain mg on
            mg.topRankBin = ifnull(pow(2, floor(log2(d.topRank))), -1)
        /* and mg.newRankBin = ifnull(pow(2, floor(log2(d.newRank))), -1) */
        /* and mg.bestRankBin = ifnull(pow(2, floor(log2(d.bestRank))), -1) */
        /* and mg.askRankBin = ifnull(pow(2, floor(log2(d.askRank))), -1) */
        /* and mg.showRankBin = ifnull(pow(2, floor(log2(d.showRank))), -1) */
        /* and mg.jobRankBin = ifnull(pow(2, floor(log2(d.jobRank))), -1) */
        /* and mg.scoreBin = ifnull(pow(2, floor(log2(d.score))), -1) */
        /* and mg.descendantsBin = ifnull(pow(2, floor(log2(d.descendants))), -1) */
        and mg.timeofdayBin = cast(strftime('%H', sampleTime, 'unixepoch') as int)/4*4
        and mg.dayofweekBin = cast(strftime('%w', sampleTime, 'unixepoch') as int)
where d.topRank is not null
;
