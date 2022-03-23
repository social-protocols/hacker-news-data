library(ggplot2)


# Okay the idea here is that the estimates for quality that we got using a
# Bayesian model and MCMC in bayesian-quality-model.R can be approximated
# using a very simple "Bayesian Averaging" formula.


# First, run the Bayesian quality model.
source("bayesian-quality-model.R")

# Pull the average posterior estimate for log_quality for all n stories,
# and add to the data frame.
samples$posteriorLogQuality = coef(model)[1:n]


# Now chart. This chart shows that there is a strong linear relationship
# between the log of the quality ratio and the Bayesian estimate of quality
# when there are a lot of upvotes (a lot of evidence). That is, a simple
# ratio of upvotes/expectedUpvotes is a good estimate of quality when there
# is lots of evidence, but when there are fewer upvotes a simple ratio
# greatly over-estimates quality.
ggplot(samples, aes(x = posteriorLogQuality, y = log(qualityRatio))) + geom_point(aes(size = upvotes))
ggsave(file = "plots/quality ratio vs MCMC log scale.png"
, height = 5, width = 5)


## Bayesian Average of Log Quality. This is a weighted average between the log
## quality ratio and zero (the prior expectation of the average log quality
## ratio). The weights are the number of upvotes and some constant value,
## respectively. The constant is chosen based on whatever works
## (whatever makes the bayesian-average estimate closest to the MCMC
## estimate), but it can be interpreted as representing the strength of the prior.
# I found the value of 3 by manually running a linear regression with various other values.


constant = rep(3, times=n)
samples$bayesianAverageLogQuality = (log(samples$qualityRatio)*samples$upvotes) / (samples$upvotes + constant)
ggplot(samples, aes(x = posteriorLogQuality, y = bayesianAverageLogQuality)) + geom_point(aes(size = upvotes))
ggsave(file = "plots/bayesian average vs MCMC log scale (constant=3).png", height = 5, width = 5)


linearMod <- lm(posteriorLogQuality ~ bayesianAverageLogQuality, data=samples)
summary(linearMod)

