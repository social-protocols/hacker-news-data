# Okay the idea here is that the estimates for quality that we got using MCMC in bayesian-quality-model.R can be
# Estimated using a very simple "Bayesian Averaging" formula. S

# First, run the Bayesian quality model
source("bayesian-quality-model.R")

# Pull the average posterior estimate for log_quality for all n stories
# And add to the data frame
samples$posteriorLogQuality = coef(model)[1:n]


# Now chart. This chart shows that there is a strong linear relationship
# between the log of the quality ratio and the bayesian estiate of quality
# when there are a lot of upvotes (a lot of evidence). That is, a simple
# ratio of upvotes/expectedUpvotes is a good estimate of quality when there
# is lots of evidence. But when there are fewer upvotes a simple ratio
# greatly over-estimates quality.
ggplot(samples, aes(x = posteriorLogQuality, y = log(qualityRatio))) + geom_point(aes(size = upvotes))
ggsave(file = "plots/quality ratio vs MCMC log scale.png"
, height = 5, width = 5)


# Same chart, but using linear instead of logarithmic scale.
# ggplot(samples, aes(x = exp(posteriorLogQuality), y = qualityRatio)) + geom_point(aes(size = upvotes))

# constant = rep(10, times=n)
# samples$bayesianAverageQuality = (samples$qualityRatio*samples$upvotes + constant) / (samples$upvotes + constant)
# ggplot(samples, aes(x = exp(posteriorLogQuality), y = bayesianAverageQuality)) + geom_point(aes(size = upvotes))

# linearMod <- lm(exp(posteriorLogQuality) ~ bayesianAverageQuality, data=samples)
# summary(linearMod)

# 8: .8376
# 10: .8714
# 12: .89
# 14: .8995
# 15: 0.9019,
# 17: 0.9037
# 18: 0.9036
# 20:  0.9013
# 25: .8903


## Bayesian Average of Log Quality
constant = rep(3, times=n)
samples$bayesianAverageLogQuality = (log(samples$qualityRatio)*samples$upvotes) / (samples$upvotes + constant)
ggplot(samples, aes(x = posteriorLogQuality, y = bayesianAverageLogQuality)) + geom_point(aes(size = upvotes))
ggsave(file = "plots/bayesian average vs MCMC log scale (constant=3).png", height = 5, width = 5)


linearMod <- lm(posteriorLogQuality ~ bayesianAverageLogQuality, data=samples)
summary(linearMod)

# 4: .9902
# 3.5: .992
# 3.25: .9925
# 3.125: 9925
# 3: .9927
# 2.875: .9925
# 2.75: 9923
# 2: .9869