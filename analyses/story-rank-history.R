# Dependencies
library(dplyr)
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

# Get rank history for representative story
selected_id <- 29621574
data <- dbGetQuery(
  con,
  "
  SELECT 
    id, 
    score, 
    CAST(sampleTime - submissionTime AS FLOAT) / (60 * 60) AS ageHours, 
    topRank, 
    gain
  FROM dataset
  WHERE id={selected_id};
  " %>% glue()
)

# Get story from API
url <- glue("https://hacker-news.firebaseio.com/v0/item/{selected_id}.json")
story <- content(GET(url[1]))

# Wrangle data into plottable format
data %>%
  mutate(ageHoursFloor = floor(ageHours)) %>% 
  group_by(ageHoursFloor) %>% 
  mutate(sumGainInHour = sum(gain)) %>% 
  ungroup() %>% 
  mutate(topRank = -topRank) %>% 
  filter(ageHours <= 24) -> plot_data

# Plot
ggplot(plot_data) +
  geom_line(aes(x = ageHours, y = topRank + 90), color = "#ff6600") +
  geom_bar(
    data = plot_data %>% select(ageHoursFloor, sumGainInHour) %>% distinct(),
    aes(x = ageHoursFloor, y = sumGainInHour), stat = "identity", fill = "black") +
  scale_x_continuous(breaks = seq(0, 24, 4)) +
  scale_y_continuous(
    breaks = seq(0, 90, 5),
    labels = function(x) abs(x - 90)
  ) +
  labs(
    x = "Age [Hours]",
    y = "Top Rank",
    caption = glue(
      "ID: {story$id}\n Title: {story$title}\n URL: {story$url}\n Posted: {as_datetime(story$time)} UTC"
    )
  ) +
  theme(
    plot.caption = element_text(hjust = 0),
    legend.position = "None",
    text = element_text(family = "Courier"),
    axis.title.x = element_text(margin = margin(t = 10, b = 20)),
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black")
  ) +
  NULL

# Save plot
# ggsave("plots/story-rank-history.png", width = 8, height = 6)
# ggsave("plots/story-rank-history.svg", width = 8, height = 6)

# Disconnect from database
RSQLite::dbDisconnect(conn = con)