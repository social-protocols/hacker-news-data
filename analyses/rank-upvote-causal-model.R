Okay, here are my notes for calculating upvoteRate(do(rank))

That is, the baseline upvote rate as a function of rank, if we took away the effect of the
HN ranking algorithm on rank.


## Upvotes by ID and Rank

This is data set is the base for our calculation of the upvote rate for each rank: the 
number of upvotes a story received at each rank, and its time at that rank.


drop table if exists homepageUpvotesByIDAndRank;
CREATE TABLE homepageUpvotesByIDAndRank AS
SELECT id, topRank rank, COUNT(tick)*60 AS timeAtRank, max(sampleTime) - min(sampleTime) as elapsedTime, SUM(gain) AS upvotes
FROM dataset
WHERE topRank IS NOT NULL
GROUP BY id, rank
ORDER BY id, rank;
create index homepageUpvotesByIDAndRank_idx on homepageUpvotesByIDAndRank(id, rank);



drop table if exists newpageUpvotesByIDAndRank;
CREATE TABLE newpageUpvotesByIDAndRank AS
SELECT id, newRank rank, COUNT(tick)*60 AS timeAtRank, max(sampleTime) - min(sampleTime) as elapsedTime, SUM(gain) AS upvotes
FROM dataset
WHERE newRank IS NOT NULL
AND topRank is null
GROUP BY id, rank
ORDER BY id, rank;
create index newpageUpvotesByIDAndRank_idx on newpageUpvotesByIDAndRank(id, rank);


## Upvote Ratio Matrix

Now create the matrix of upvote ratios. For each combination of row/column, i.e. each
pair of ranks, I want to find the stories that were displayed at both ranks,
and then I want to calculate the upvote ratio.

This needs to be a geometric average.

createUpvoteRatioMatrixTable = "
create table upvoteRatioMatrix as
select
    row.rank as rowNum
    , column.rank as colNum
    , sum(row.upvotes) as rowUpvotes
    , sum(row.timeAtRank) as rowTimeAtRank
    , sum(column.upvotes) as rowUpvotes
    , sum(column.timeAtRank) as rowTimeAtRank
    , avg(cast(row.upvotes as real)/row.timeAtRank) as upvoteRateRow
    , avg(cast(column.upvotes as real)/column.timeAtRank) as upvoteRateColumn
    , exp(avg(
        case 
            when row.rank = column.rank then 0
            when row.upvotes = 0 or column.upvotes = 0 then null 
            else 
                log(
                    ( cast(column.upvotes as real)/column.timeAtRank ) / 
                    ( cast(row.upvotes as real)/row.timeAtRank )
                ) 
        end
    ))
    as upvoteRateRatio
FROM
    homepageUpvotesByIDAndRank row
    JOIN homepageUpvotesByIDAndRank column USING (id)
group by rowNum, colNum
order by rowNum, colNum;
"
dbExecute(con, createUpvoteRatioMatrixTable)


### Upvote Ratio Vector

Any single row of this matrix gives us the the "shape" of the causal effect of rank on upvote.
That is we could scale each row by a constant factor and it should be nearly identical
to row 1. This is because upvoteRatio(1,N) = upvoteRatio(1,M) * upvoteRatio(M,N)

So we want to create a single vector that gives us this shape, relative to row 1.colNum

We do this by averaging over all rows. E.g. the average:

    1/n ∑ M[,i] ∙ M[i,1]

create table upvoteRatioVector as
    with row1 as (select * from upvoteRatioMatrix where rowNum = 1)
    select row.colNum as rank, avg(row.upvoteRateRatio*row1.upvoteRateRatio) as upvoteRatio
    from upvoteRatioMatrix row join row1 on row1.colNum = row.rowNum
    group by row.colNum
;

we can also do the same with an Eigenvector


query = "
    select 
        upvoteRateRatio
    from upvoteRatioMatrix
    order by rowNum, colNum
    ;
"

upvoteRatioTable <- dbGetQuery(con, query)

n <- sqrt(length(upvoteRatioTable$upvoteRateRatio))[1]
M <- matrix(upvoteRatioTable$upvoteRateRatio, nrow=n, ncol=n, byrow=FALSE)
ev = eigen(M)

head(ev$vectors[1,])

v = M %*%  ev$vectors[,1] / ev$values[1]
v1 = Re(v[,1] / v[1,1])

The results are super close.

> head(v1)
[1] 1.0000000 0.6967923 0.5643414 0.4833383 0.4263944 0.3908772


## Upvote Rate by Rank

Okay, now we can calculate upvoteRate(do(rank)) at all ranks.

We do this by calculating upvoteRate(do(Rank=1)), then multiply this by the upvoteRatioVector.

This is the forula in the writeup

        =  upvoteRatio(rank,1) 1/nStories ∑_story 
            1/nRanks(story)  
            ∑_{m in ranks(story)} upvoteRate(m,story) * upvoteRatio(1,m)

-- Yeeeh hah. This gives us our upvote rate per second at all ranks
CREATE TABLE homepageUpvoteRateByRank as
WITH rank1UpvoteRateByStory as (
    SELECT
        id,
        min(rank) as maxRank,
        sum(cast(rank as float) * elapsedTime)/sum(elapsedTime) as avgRank,
        sum(upvotes) as totalUpvotes,
        sum(elapsedTime) as totalTime,
        cast(sum(homepageUpvotesByIDAndRank.upvotes) as float)/sum(elapsedTime) as avgUpvoteRate,
        avg(
            cast(homepageUpvotesByIDAndRank.upvotes as float)/homepageUpvotesByIDAndRank.elapsedTime
            / upvoteRatio
        ) as upvoteRate

    FROM homepageUpvotesByIDAndRank 
    JOIN upvoteRatioVector using (rank) 
    GROUP BY id
)
SELECT 
    rank, avg(upvoteRate) * upvoteRatio as upvoteRate
    FROM rank1UpvoteRateByStory
    JOIN upvoteRatioVector
    GROUP BY rank
    order by rank
;
create index homepageUpvoteRateByRank_idx on homepageUpvoteRateByRank(rank);





