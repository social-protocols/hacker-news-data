library(ggplot2)
library(DBI)

# Create chart showing the quality of a random selection of stories over time.
# One chart calculates quality using a simple ratio of
# upvotes/expectedUpvotes, another uses the Bayesian Averaging formula
# developed in bayesian-average-quality.R. Outputs two charts with the same
# random stories.
#
# There are two takeaways. 
#
# 1) Quality of a story seems fairly stable over time. The graph for each
# story levels out after enough data has been gathered, and different stories
# clearly level out at different levels of quality.
#
# 2) The Bayesian average moves closer to a stable value more quickly. Comparing the two charts
# the big differences are on the left side of the graph, when a story is new and the number of upvotes are small.
# Bayesian averaging brings these values in towards the average of zero -- which is closer to the "true" value that
# they stabilize at over time.

# Connect to the sqlite database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# 
query = "
    with cumulatives as (
        SELECT
            id
            , tick
            , sampleTime
            , sampleTime - min(sampleTime) OVER (PARTITION BY id) AS elapsedSeconds
            , strftime('%Y-%m-%d %H:%m:00', max(sampleTime), 'unixepoch') AS hour
            , sum(gain) AS upvotes
            , topRank AS rank
            , sum(gain) OVER (PARTITION BY id ORDER BY tick ASC ROWS UNBOUNDED PRECEDING) AS cumulativeUpvotes
            , sum(expectedUpvotesByTick.upvotes * upvoteShare) AS expectedUpvotes
            , SUM(expectedUpvotesByTick.upvotes * upvoteShare) OVER (PARTITION BY id ORDER BY tick ROWS UNBOUNDED PRECEDING) cumulativeExpectedUpvotes
        FROM 
            (SELECT * FROM random_sample_100_stories LIMIT 50)
            JOIN dataset USING (id)
            JOIN expectedUpvotesByTick USING (tick)
            JOIN expectedUpvotesByRank ON rank = topRank
        GROUP BY id, tick, sampleTime
        ORDER BY id, tick, sampleTime
    )
    SELECT 
        id
        , hour
        , max(elapsedSeconds) AS elapsedSeconds
        , max(rank) AS maxRank
        , max(cumulativeUpvotes) AS cumulativeUpvotes
        , max(cumulativeExpectedUpvotes) AS cumulativeExpectedUpvotes
    FROM cumulatives
    GROUP BY id, hour
    ORDER BY id, hour
";

samples <- dbGetQuery(con, query)


# Weight by cumulative upvotes
samples$bayesianAverageLogQuality = log(samples$cumulativeUpvotes/samples$cumulativeExpectedUpvotes)*samples$cumulativeUpvotes/(samples$cumulativeUpvotes+3)


# Weight by cumulative expected upvotes
samples$bayesianAverageLogQuality = log(samples$cumulativeUpvotes/samples$cumulativeExpectedUpvotes)*samples$cumulativeExpectedUpvotes/(samples$cumulativeExpectedUpvotes+3)

samples$logQualityRatio = log(samples$cumulativeUpvotes/samples$cumulativeExpectedUpvotes)


samples = samples [ samples$logQualityRatio > -Inf, ]

ymax = max(samples$logQualityRatio)
ymin = min(samples$logQualityRatio)



ggplot(samples, aes(x = elapsedSeconds, y = bayesianAverageLogQuality, group=id, color=factor(id))) +  geom_line() + geom_point(aes(color = factor(id))) + ylim(ymin, ymax)
ggsave(file = "plots/bayesian-average-quality-over-time.png", height = 5, width = 10)



ggplot(samples, aes(x = elapsedSeconds, y = logQualityRatio, group=id, color=factor(id))) +  geom_line() + geom_point(aes(color = factor(id))) + ylim(ymin, ymax)
ggsave(file = "plots/quality-ratio-over-time.png", height = 5, width = 10)

