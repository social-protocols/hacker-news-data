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
  WHERE topRank <= 10;
  "
) %>% 
  mutate(sampleTime = as_datetime(sampleTime)) %>% 
  mutate(sampleTimeRounded = round_date(sampleTime, unit = "hour")) %>% 
  # filter(hour(sampleTimeRounded) %in% seq(8, 12, 1), wday(sampleTimeRounded) == 4) %>%   # REMOVE AFTER EXPERIMENTING WITH IT
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
    `7` = "Rank 7",
    `8` = "Rank 8",
    `9` = "Rank 9",
    `10` = "Rank 10",
    .ordered = TRUE
  )

# Calculate means to plot vlines
mean_gains <- data %>% 
  group_by(topRank) %>% 
  summarize(meanGain = mean(gain)) %>% 
  ungroup()

# Plot
p <- data %>% 
  ggplot(aes(x = gain)) +
  geom_histogram(binwidth = 5, fill = "black", alpha = 0.8)

for (tr in levels(data$topRank)) {
  p <- p +
    geom_vline(
      data = filter(mean_gains, topRank == tr), 
      aes(xintercept = meanGain),
      linetype = "dashed",
      size = 1,
      color = "#ff6600"
    )
}

p <- p +
  scale_x_continuous(limits = c(0, 200)) +
  labs(
    x = "Upvotes per Hour",
    caption = "Histograms of upvote arrivals for ranks 1-10. Dashed orange lines indicate the mean."
  ) +
  facet_grid(rows = vars(topRank)) +
  theme(
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    axis.title.x = element_text(margin = margin(t = 10, b = 10)),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.line = element_line(color = "black"),
    text = element_text(family = "Courier"),
  )

# Save plot
ggsave(plot = p, "plots/vote-arrivals-per-rank.png", width = 7, height = 9)
ggsave(plot = p, "plots/vote-arrivals-per-rank.svg", width = 7, height = 9)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)