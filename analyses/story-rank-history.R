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


# ID of sample story
selected_id <- 29621574


# Include expected upvotes?
INCLUDE_EXPECTED <- TRUE


# For other stories
# selected_id <- 29622063


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
url <- glue("https://hacker-news.firebaseio.com/v0/item/{selected_id}.json")
story <- content(GET(url[1]))


# Get rank history for representative story
data <- dbGetQuery(
  con,
  "
  select id, topRank, sampleTime, cast(sampleTime - submissiontime as Float)/(60*60) as ageHours, 
  gain, avgGain 
  from qualityDebug
  WHERE id={selected_id};
  " %>% glue()
) %>% 
  mutate(sampleTime = as_datetime(sampleTime))


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
  filter(ageHours <= 24) -> rank_history


# Gain data for plot
gain_data <- rank_history %>% 
  select(ageHoursFloor, actual, expected) %>% 
  distinct() %>% 
  pivot_longer(cols = c(actual, expected), names_to = "metric", values_to = "value") %>% 
  mutate(metric = factor(metric))


# Plot
p <- ggplot(rank_history) +
  geom_line(aes(x = ageHours, y = topRank + 90), color = "#ff6600") +
  scale_x_continuous(breaks = seq(0, 24, 4)) +
  scale_y_continuous(
    breaks = c(89, seq(0, 85, 5)),
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
      paste0("Line (left y-axis) indicates the rank.\n"),
      paste0("Bars (right y-axis) indicate actual and expected gained votes per hour.")
    )
  ) +
  theme(
    plot.caption = element_text(hjust = 0),
    legend.title = element_blank(),
    text = element_text(family = "Courier"),
    axis.title.x = element_text(margin = margin(t = 10, b = 20)),
    panel.background = element_rect(fill = "#f6f6ef"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black")
  )


# Plot with or without expected upvotes
if (INCLUDE_EXPECTED) {
  
  p <- p +
    geom_bar(
      data = gain_data,
      aes(x = ageHoursFloor, y = value, fill = metric),
      stat = "identity",
      position = "dodge",
      width = 0.6
    ) +
    scale_fill_manual(values = c("actual" = "black", "expected" = "gold3")) +
    theme(
      legend.position = c(0.9, 0.9),
      legend.box.background = element_rect(fill = "white", color = "black")
    )
  
} else {
  
  p <- p +
    geom_bar(
      data = rank_history %>% select(ageHoursFloor, actual) %>% distinct(),
      aes(x = ageHoursFloor, y = actual), stat = "identity", fill = "black"
    ) +
    theme(legend.position = "None")
  
}


# Save plot
ggsave(plot = p, "plots/story-rank-history.png", width = 8, height = 6)
ggsave(plot = p, "plots/story-rank-history.svg", width = 8, height = 6)


# Disconnect from database
RSQLite::dbDisconnect(conn = con)