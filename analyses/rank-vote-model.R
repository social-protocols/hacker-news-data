# Dependencies
library(DBI)

con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# So my hypothesis is that the number of upvotes at each rank is some fraction
# of the upvotes at rank 1. Based on what I remember working in Search,
# clicks were generally proportional to 1/rank. What I found is that what
# actually fits is that upvotes are proportional to rank^-0.7. I found the
# coefficient -0.7 just by eyeballing. But a regression model shows this to be
# a very good fit.

# First, summarize total upvotes by rank
upvotesByRank <- dbGetQuery(con,"
    SELECT 
        ifnull(topRank, -1) AS rank, 
        sum(gain) AS upvotes, 
        count(distinct tick) AS ticks, 
        cast(sum(gain) AS real)/count(distinct tick) AS upvoteRate
    FROM dataset
    where topRank is not null
    ORDER BY topRank;
")

# Start by looking at just page 1
page1upvotesByRank = head(upvotesByRank, 30)

# The get the number of upvotes at rank 1.
rank1Upvotes = page1upvotesByRank[ page1upvotesByRank$rank == 1,  ]$upvotes

# This coefficient I found just by experimentation.
coeff = 0.7

# Now plot expected upvotes by rank given this model, and actual
scatter.smooth(x = rank1Upvotes / ( page1upvotesByRank$rank ^ coeff ), y=page1upvotesByRank$upvotes, xlab=paste("rank1Upvotes / rank ^",coeff), ylab="upvotes" )


# Repeat same analysis for page 2. Note that the first three few ranks
# (top right -- highest number of clicks) don't fit on the line. Conversation on Slack on this subject.

# Jonathan Warden:
# Rank 31 and 32 (the first/second items on page 1) get more clicks than predicted by the formula. Could this be because in reality, our crawl data shows the rank of a story at the time of the crawl, but during one “tick” the page could have been at higher/lower ranks. So stories shown at rank 31 (page 2) actually on average spent some time on page 1? Otherwise, page1 and page2 look the same except for the slope of the line.

# Felix Dietze:
# Yes, your interpretation of the first two ranks on the second page sounds correct. We sample every minute, so that's the timeframe where things can happen

page2upvotesByRank = tail(head(upvotesByRank, 60),30) 

scatter.smooth(x = rank1Upvotes / ( page2upvotesByRank$rank ^ coeff ), y=page2upvotesByRank$upvotes, xlab=paste("rank1Upvotes / rank ^",coeff),
ylab="upvotes" )


# Do a linear model to see how closely this fits. It fits well. R-squared is .9984
page1upvotesByRank$expectedUpvotes = rank1Upvotes/(page1upvotesByRank$rank ^ coeff)
linearMod <- lm(upvotes ~ expectedUpvotes, data=page1upvotesByRank)
summary(linearMod)

# Do the same for page 2, but leave out top 2 ranks on page 1
page2upvotesByRank = tail(head(upvotesByRank, 62),30)
page2upvotesByRank$expectedUpvotes = rank1Upvotes/(page2upvotesByRank$rank ^ coeff)
linearMod <- lm(upvotes ~ expectedUpvotes, data=page2upvotesByRank)
summary(linearMod)
# R-squared is .98

# Disconnect from database
RSQLite::dbDisconnect(conn = con)