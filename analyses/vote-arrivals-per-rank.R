# Dependencies
library(dplyr)
library(magrittr)
library(DBI)
library(ggplot2)
library(lubridate)

# Connect to database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")


dbGetQuery(
  con,
  "
  SELECT topRank, gain, sampleTime
  FROM dataset
  WHERE topRank in (1, 2, 3, 4, 5, 6);
  "
) %>% 
  mutate(sampleTime = as_datetime(sampleTime)) %>% 
  mutate(sampleTimeRounded = round_date(sampleTime, unit = "hour")) %>% 
  group_by(sampleTimeRounded, topRank) %>% 
  summarize(gain = sum(gain)) %>% 
  ungroup() -> data


data$topRank %<>% 
  factor() %>% 
  recode_factor(
    `1` = "Rank 1",
    `2` = "Rank 2",
    `3` = "Rank 3",
    `4` = "Rank 4",
    `5` = "Rank 5",
    `6` = "Rank 6",
    .ordered = TRUE
  )

mean_gains <- data %>% 
  group_by(topRank) %>% 
  summarize(meanGain = mean(gain)) %>% 
  ungroup()

p <- data %>% 
  ggplot(aes(x = gain)) +
  geom_histogram(binwidth = 10, fill = "black", alpha = 0.8)

for (tr in levels(data$topRank)) {
  p <- p +
    geom_vline(
      data = filter(mean_gains, topRank == tr), 
      aes(xintercept = meanGain),
      linetype = "dashed",
      color = "#ff6600"
    )
}

p <- p +
  labs(
    x = "Gain per Hour",
    y = "Count",
    caption = "dashed orange lines indicate the mean"
  ) +
  scale_y_continuous(breaks = seq(0, 500, 200)) +
  facet_grid(rows = vars(topRank)) +
  theme(
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    axis.line = element_line(color = "black"),
    text = element_text(family = "Courier"),
  )

p


# Save plot
ggsave("plots/vote-arrivals-per-rank.png", width = 7, height = 7)
ggsave("plots/vote-arrivals-per-rank.svg", width = 7, height = 7)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)