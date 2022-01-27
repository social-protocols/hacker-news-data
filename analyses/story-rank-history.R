# Dependencies
library(dplyr)
library(tidyr)
library(DBI)
library(ggplot2)
library(magrittr)
library(lubridate)
library(glue)
library(httr)

# Set locale
Sys.setlocale("LC_ALL","en_US.UTF-8")

# Connect to database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")

# # For reference: Table of stories scoring higher than or equals 100
# highest_scoring_stories <- dbGetQuery(
#   con,
#   "
#   SELECT d.id, max(score) AS maxScore
#   FROM dataset d
#   JOIN fullstories f
#   ON d.id = f.id
#   GROUP BY d.id
#   HAVING maxScore > 100
#   ORDER BY maxScore DESC;
#   "
# )

# Get story from API
selected_id <- 29621574
url <- glue("https://hacker-news.firebaseio.com/v0/item/{selected_id}.json")
story <- content(GET(url[1]))

# Get rank history for representative story
data <- dbGetQuery(
  con,
  "
  SELECT 
    id, 
    score, 
    sampleTime,
    CAST(sampleTime - submissionTime AS FLOAT) / (60 * 60) AS ageHours, 
    topRank, 
    gain
  FROM dataset
  WHERE id={selected_id};
  " %>% glue()
) %>% 
  mutate(sampleTime = as_datetime(sampleTime)) %>% 
  mutate(
    timeofdayBin = hour(sampleTime),
    dayofweekBin = as.integer(wday(sampleTime))
  ) %>% 
  mutate(topRankBin = log2(topRank) + 1) %>% 
  replace_na(list(topRankBin = -1)) %>% 
  mutate(topRankBin = as.integer(topRankBin))
  

expected_votes <- dbGetQuery(
  con,
  "
  SELECT *
  FROM expectedUpvotes
  " %>% glue()
) %>% 
  mutate(topRankBin = as.integer(topRankBin))


data %<>% 
  left_join(expected_votes, by = c("topRankBin", "timeofdayBin", "dayofweekBin"))


# Wrangle data into plottable format
data %>%
  mutate(ageHoursFloor = floor(ageHours)) %>% 
  group_by(ageHoursFloor) %>% 
  mutate(
    actual = sum(gain, na.rm = TRUE),
    expected = sum(avgGain, na.rm = TRUE)
  ) %>% 
  ungroup() %>% 
  mutate(topRank = -topRank) %>% 
  filter(ageHours <= 24) -> line_data

bar_data <- line_data %>% 
  select(ageHoursFloor, actual, expected) %>% 
  distinct() %>% 
  pivot_longer(cols = c(actual, expected), names_to = "metric", values_to = "value") %>% 
  mutate(metric = factor(metric))


# Plot
ggplot(line_data) +
  geom_line(aes(x = ageHours, y = topRank + 90), color = "#ff6600") +
  # only upvotes in hour
  # geom_bar(
  #   data = plot_data %>% select(ageHoursFloor, sumGainInHour) %>% distinct(),
  #   aes(x = ageHoursFloor, y = sumGainInHour), stat = "identity", fill = "black"
  # ) +
  # upvotes and expected upvotes
  geom_bar(
    data = bar_data,
    aes(x = ageHoursFloor, y = value, fill = metric),
    stat = "identity",
    position = "dodge",
    width = 1
  ) +
  scale_fill_manual(values = c("actual" = "black", "expected" = "gold3")) +
  scale_x_continuous(breaks = seq(0, 24, 4)) +
  scale_y_continuous(
    breaks = seq(0, 85, 5),
    labels = function(x) abs(x - 90),
    sec.axis = sec_axis(~ ., name = "Upvote Gain")
  ) +
  labs(
    x = "Age [Hours]",
    y = "Top Rank",
    caption = paste0(
      glue("ID: {story$id}\n\n"),
      glue("Title: {story$title}\n\n"),
      glue("URL: {story$url}\n\n"),
      glue("Posted: {as_datetime(story$time)} UTC\n\n\n"),
      paste0("Orange line indicates the rank history, black bars the gained votes per hour.")
    )
  ) +
  theme(
    plot.caption = element_text(hjust = 0),
    legend.title = element_blank(),
    # no legend if not expected upvotes
    # legend.position = "None",
    # otherwise
    legend.position = c(0.9, 0.9),
    legend.box.background = element_rect(fill = "white", color = "black"),
    text = element_text(family = "Courier"),
    axis.title.x = element_text(margin = margin(t = 10, b = 20)),
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black")
  ) +
  NULL

# Save plot
ggsave("plots/story-rank-history.png", width = 8, height = 6)
ggsave("plots/story-rank-history.svg", width = 8, height = 6)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)