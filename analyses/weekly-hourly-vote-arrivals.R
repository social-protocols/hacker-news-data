# Dependencies
library(dplyr)
library(DBI)
library(ggplot2)
library(lubridate)
library(viridis)

# Set locale
Sys.setlocale("LC_ALL","en_US.UTF-8")

# Connect to database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# Query
dbGetQuery(con, "
  SELECT sampleTime, topRank, gain
  FROM dataset
") %>% 
  as_tibble() %>%
  mutate(sampleTimeDateTime = lubridate::as_datetime(sampleTime)) %>% 
  mutate(sampleTimeDate = lubridate::date(sampleTimeDateTime),
         sampleTimeWeekday = lubridate::wday(sampleTimeDateTime, label = TRUE, week_start = 1),
         sampleTimeHour = lubridate::hour(sampleTimeDateTime),
         sampleTimeMinute = lubridate::minute(sampleTimeDateTime)) %>%  
  group_by(sampleTimeDate, sampleTimeWeekday, sampleTimeHour, sampleTimeMinute) %>% 
  summarize(sumGainInMinute = sum(gain)) %>% 
  ungroup() %>% 
  group_by(sampleTimeDate, sampleTimeWeekday, sampleTimeHour) %>% 
  summarize(meanPerMinuteGainInHour = mean(sumGainInMinute)) %>% 
  ungroup() -> data

# Plot
data %>% 
  filter(meanPerMinuteGainInHour < 40, meanPerMinuteGainInHour > 0) %>%
  mutate(meanPerHourGainInHour = meanPerMinuteGainInHour * 60) %>% 
  ggplot(aes(x = sampleTimeHour, y = meanPerHourGainInHour)) +
  geom_point(alpha = 0.4, aes(color = factor(sampleTimeWeekday))) +
  geom_line(stat = "smooth", size = 1, alpha = 0.7, color = "grey40") +
  scale_color_viridis(discrete = TRUE) +
  scale_x_continuous(breaks = c(0, 6, 12, 18)) +
  scale_y_continuous(breaks = seq(0, 1400, by = 300), limits = c(0, 1500)) +
  labs(
    x = "Time of Day",
    y = "Average Upvote Arrival Rate per Hour",
    caption = "collected between 2021-11-23 and 2021-01-14" 
  ) +
  facet_grid(cols = vars(sampleTimeWeekday)) +
  theme(
    legend.position = "None",
    text = element_text(family = "Courier"),
    axis.title.x = element_text(margin = margin(t = 10, b = 10)), 
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black")
  ) +
  NULL

# Save plot 
ggsave("plots/weekly-hourly-vote-arrivals.png", width = 8, height = 5)
ggsave("plots/weekly-hourly-vote-arrivals.svg", width = 8, height = 5)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)