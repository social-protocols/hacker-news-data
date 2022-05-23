


# devtools::install_github("thomasp85/transformr")
install.packages("transformr")


install.packages("gganimate")
install.packages("gifski")
library(gganimate)




storiesOverTimeRatio = storiesOverTime[ storiesOverTime$elapsedMinutes < 200, ]

storiesOverTimeBayesianAveraged<-data.frame(storiesOverTimeRatio)

storiesOverTimeRatio$logQuality = storiesOverTimeRatio$logQualityRatio
storiesOverTimeRatio$qualityType = "Simple Ratio"

storiesOverTimeBayesianAveraged$logQuality = storiesOverTimeBayesianAveraged$bayesianAverageLogQuality
storiesOverTimeBayesianAveraged$qualityType = "Bayesian Average"


storiesOverTimeCombined = rbind(storiesOverTimeRatio, storiesOverTimeBayesianAveraged)



myPlot <- ggplot(
    storiesOverTimeCombined, 
    aes(
        x = elapsedMinutes,
        y = logQuality,
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
ylim(ymin, ymax) +
transition_states(qualityType) +
ggtitle('Story Quality History: {closest_state}')



a <- animate(myPlot, duration = 4, fps = 20, renderer = gifski_renderer(loop=TRUE), width=1300, height=700)
anim_save("plots/quality-animated.gif", a)


