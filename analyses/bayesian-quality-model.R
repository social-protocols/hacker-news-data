library(DBI)
library(rethinking)
library(glue)


# Connect to the sqlite database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# A library accompanying the Richard McElreath's "Statistical Rethinking",
# with a bunch of utility methods, wrappers around STAN.

# Sample size THere needs to be a corresponding random sample table. (e.g. if n=1000, random_sample_1000_stories)
n <- 1000

# Grab actual/expected upvotes from a random sample of stories. We are
# defining quality as the ratio of actual/expected upvotes (at that
# rank/time). But of course if there is a small amount of upvotes, the actual
# ratio might not represent the 'true' quality, or long-term average ratio for
# that story. A hierarchical model can help us make better estimates of true
# quality and differentiate the effect of quality from random noise.

query = glue("
    SELECT
        id,
        sid,
        upvotes,
        row_number() over () as sampleNumber,
        max(total_upvotes) as totalUpvotesForStory,
        expectedUpvotes,
        cumulativeQuality as qualityRatio
    FROM 
        random_sample_{n}_stories
        JOIN quality USING (id)
        GROUP BY id, sid
")

samples <- dbGetQuery(con, query)


# Pretty simple Bayesian hierarchical model.
model <- ulam(
    alist(
        upvotes ~ dpois(lambda),

        # The rate that votes arrive is equal to the expected upvotes (at this time/rank)
        # times quality. The formula below is quality*avg_quality*expectedUpvotes. We include
        # both a story-specific quality (indexed by sid) and an overall average quality across
        # all stories, which should be very close to 1 by definition (so log quality should be 
        # close to zero).
        lambda <- exp(log_quality[sid] + avg_log_quality)*expectedUpvotes,

        # Key to the model. Each story (indexed by sid) has a log quality
        # drawn from a normal distribution. This means for example that a
        # story getting 2x as many votes as expected is as common as one
        # getting 1/2x as many (ln 2 = - ln 1/2 = .693).
        log_quality[sid] ~ dnorm(0, sigma_quality),

        # Super weak prior on the standard deviation of quality.
        sigma_quality ~ dunif(0, 5),

        # Average quality should be close to zero, but make this a parameter
        # not a constant to see if the data fits the model as expected.        
        avg_log_quality ~ dnorm(0, 5)
    ), data=samples
)
precis(model, depth=2)

