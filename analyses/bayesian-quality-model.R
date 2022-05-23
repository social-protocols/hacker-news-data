library(DBI)
library(rethinking)
library(glue)
library(rstan)


# Connect to the sqlite database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# A library accompanying the Richard McElreath's "Statistical Rethinking",
# with a bunch of utility methods, wrappers around STAN.

# Sample size THere needs to be a corresponding random sample table. (e.g. if n=1000, random_sample_1000_stories)
n <- 100

# Grab actual/expected upvotes from a random sample of stories. We are
# defining quality as the ratio of actual/expected upvotes (at that
# rank/time). But of course if there is a small amount of upvotes, the actual
# ratio might not represent the 'true' quality, or long-term average ratio for
# that story. A hierarchical model can help us make better estimates of true
# quality and differentiate the effect of quality from random noise.

createExpectedUpvotesByIdAndRank = glue("
create table expectedUpvotesByIdAndRank as
with total as (
    select sum(upvoteRate) as upvoteRate from homepageUpvoteRateByRank 
)
    SELECT 
      sid, 
      topRank rank,
      count(dataset.tick) as ticks,
      count(dataset.tick)*60 as timeAtRank,
      sum(gain) as upvotes,
      sum(upvotesByTick.upvotes) sitewideUpvotes,
      homepageUpvoteRateByRank.upvoteRate as upvoteRateAtRank,
      total.upvoteRate as totalUpvoteRate,
      cast(homepageUpvoteRateByRank.upvoteRate as float)/total.upvoteRate as upvoteShareAtRank,
      sum(upvotesByTick.upvotes)*cast(homepageUpvoteRateByRank.upvoteRate as float)/total.upvoteRate as expectedUpvotes
    FROM 
      dataset
      JOIN 
      random_sample_{n}_stories using (id)
      JOIN homepageUpvoteRateByRank on (rank = topRank)
      JOIN upvotesByTick using (tick)
      JOIN total
    WHERE 
      topRank IS NOT NULL
    GROUP BY sid, rank
    ORDER BY sid, rank
;
")
dbExecute(con, createExpectedUpvotesByIdAndRank)

query = "
    select sid, rank, timeAtRank, upvotes, expectedUpvotes
    from expectedUpvotesByIdAndRank
"

stories <- dbGetQuery(con, query)


model <- stan(
  file = "bayesian-quality-model.stan",  # Stan program
  data = list(rank=stories$rank, expectedUpvotes=stories$expectedUpvotes, upvotes=stories$upvotes, sid=stories$sid),    # named list of data
  chains = 2,             # number of Markov chains
  warmup = 500,           # number of warmup iterations per chain
  iter = 1000,            # total number of iterations per chain
  cores = 2,              # number of cores (could use one per chain)
  refresh = 0             # no progress shown
)

precis(model, depth=2)





