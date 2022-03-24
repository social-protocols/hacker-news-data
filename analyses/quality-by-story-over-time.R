library(ggplot2)
library(DBI)
library(glue)


# Define a reverse-log scale
# Thanks to Brian Diggs: https://stackoverflow.com/questions/11053899/how-to-get-a-reversed-log10-scale-in-ggplot2

library("scales")
reverselog_trans <- function(base = exp(1)) {
    trans <- function(x) -log(x, base)
    inv <- function(x) base^(-x)
    trans_new(paste0("reverselog-", format(base)), trans, inv, 
              log_breaks(base = base), 
              domain = c(1e-100, Inf))
}


# Create chart showing the quality of a random selection of stories over time.
# Compare two different ways of calculating quality: 1) the simple ratio of
# upvotes/expectedUpvotes, and 2) the Bayesian Averaging formula
# developed in bayesian-average-quality.R. 
#
# There are two takeaways. 
#
# 1) Quality of a story seems fairly stable over time. The graph for each
# story levels out after enough data has been gathered, and different stories
# clearly level out at different levels of quality.
#
# 2) The Bayesian average moves closer to a stable value more quickly. Comparing the two charts
# the big differences are on the left storyNumbere of the graph, when a story is new and the number of upvotes are small.
# Bayesian averaging brings these values in towards the average of zero -- which is closer to the "true" value that
# they stabilize at over time.

# Connect to the sqlite database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# For sample stories, compute cumulativeUpvotes and cumulativeExpectedUpvotes by minute, starting with the time
# the story first appears in the data.
query = "
    with cumulatives as (
        SELECT
            id
            , sid as storyNumber
            , tick
            , sampleTime
            , (sampleTime - min(sampleTime) OVER (PARTITION BY id))/60 AS elapsedMinutes
            , strftime('%Y-%m-%d %H:%m:00', max(sampleTime), 'unixepoch') AS minute
            , sum(gain) AS upvotes
            , topRank AS rank
            , sum(gain) OVER (PARTITION BY id ORDER BY tick ASC ROWS UNBOUNDED PRECEDING) AS cumulativeUpvotes
            , sum(expectedUpvotesByTick.upvotes * upvoteShare) AS expectedUpvotes
            , SUM(expectedUpvotesByTick.upvotes * upvoteShare) OVER (PARTITION BY id ORDER BY tick ROWS UNBOUNDED PRECEDING) cumulativeExpectedUpvotes
        FROM 
            (SELECT * FROM random_sample_100_stories LIMIT 15   )
            JOIN dataset USING (id)
            JOIN expectedUpvotesByTick USING (tick)
            JOIN expectedUpvotesByRank ON rank = topRank
        GROUP BY id, tick, sampleTime
        ORDER BY id, tick, sampleTime
    )
    SELECT 
        storyNumber
        , elapsedMinutes
        , max(rank) AS rank
        , max(cumulativeUpvotes) AS cumulativeUpvotes
        , max(cumulativeExpectedUpvotes) AS cumulativeExpectedUpvotes
    FROM cumulatives
    GROUP BY id, elapsedMinutes
    ORDER BY id, elapsedMinutes
";


storiesOverTime <- dbGetQuery(con, query)

# Constant found in bayesian-average-quality.R
constant = 9

# Bayesian average log quality.
# Important note: add 1 to cumulative expected upvotes, because every story starts with a score of 1.
storiesOverTime$bayesianAverageLogQuality = log((storiesOverTime$cumulativeUpvotes)/(storiesOverTime$cumulativeExpectedUpvotes+1))*storiesOverTime$cumulativeUpvotes/(storiesOverTime$cumulativeUpvotes+constant)

storiesOverTime$logQualityRatio = log((storiesOverTime$cumulativeUpvotes)/(storiesOverTime$cumulativeExpectedUpvotes+1))

ymax = max(storiesOverTime$logQualityRatio)
ymin = min(storiesOverTime$logQualityRatio)

ggplot(
    storiesOverTime[ storiesOverTime$elapsedMinutes < 200, ], 
    aes(
        x = elapsedMinutes,
        y = bayesianAverageLogQuality,
        group=storyNumber, 
        color=factor(storyNumber), 
        alpha=cumulativeUpvotes
    )
) + 
scale_alpha_continuous(range = c(.1, .7), trans="log10") +  
geom_line() + 
geom_point(
    aes(
        alpha=cumulativeUpvotes, 
        size=rank
    )
) +
scale_size(
  trans = reverselog_trans(2),
  range = c(1,4)
) +
ylim(ymin, ymax)


ggsave(file = glue("plots/bayesian-average-quality-over-time (contant={constant}).png"), width=13, height=7)


ggplot(
    storiesOverTime[ storiesOverTime$elapsedMinutes < 200, ], 
    aes(
        x = elapsedMinutes,
        y = logQualityRatio,
        group=storyNumber, 
        color=factor(storyNumber), 
        alpha=cumulativeUpvotes
    )
) + 
scale_alpha_continuous(range = c(.1, .7), trans="log10") +  
geom_line() + 
geom_point(
    aes(
        alpha=cumulativeUpvotes, 
        size=rank
    )
) +
scale_size(
  trans = reverselog_trans(2),
  range = c(1,4)
) +
ylim(ymin, ymax)


ggsave(file = "plots/quality-ratio-over-time.png", width=13, height=7)




