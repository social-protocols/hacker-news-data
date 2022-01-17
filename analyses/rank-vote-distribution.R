# Dependencies
library(dplyr)
library(DBI)
library(ggplot2)
library(lubridate)

# Connect to database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# Query and plot
dbGetQuery(
  con,
  "
  SELECT sampleTime, topRank, gain
  FROM dataset
  WHERE topRank IS NOT NULL;
  "
) %>% 
  mutate(sampleTime = round_date(as_datetime(sampleTime), unit = "hour")) %>% 
  filter(sampleTime > min(sampleTime)) %>%  # don't distort hourly mean 
  group_by(sampleTime, topRank) %>% 
  summarize(gainPerHour = sum(gain)) %>% 
  ungroup() %>% 
  group_by(topRank) %>% 
  summarize(meanGainPerHour = mean(gainPerHour)) %>% 
  ungroup() %>% 
  ggplot(aes(x = topRank, y = meanGainPerHour)) +
  geom_bar(stat = "identity", fill = "black") +
  labs(
    x = "Top Rank",
    y = "Average Upvotes per Hour"
  ) +
  geom_vline(xintercept = 30, linetype = "dashed") + 
  geom_vline(xintercept = 60, linetype = "dashed") + 
  annotate(geom = "text", x = 5, y = 60, label = "page 1") +
  annotate(geom = "text", x = 35, y = 60, label = "page 2") +
  annotate(geom = "text", x = 65, y = 60, label = "page 3") +
  scale_x_continuous(trans = "reverse", breaks = seq(5, 90, 5)) +
  coord_flip() +
  theme(
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    axis.line = element_line(color = "black"),
    text = element_text(family = "Courier"),
  ) + 
  NULL
  
# Save plot
ggsave("plots/rank-vote-distribution.png", width = 7, height = 7)
ggsave("plots/rank-vote-distribution.svg", width = 7, height = 7)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)