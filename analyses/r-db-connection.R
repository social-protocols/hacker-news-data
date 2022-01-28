library(DBI)
library(dplyr)
library(ggplot2)

# Connect to Database
con <- RSQLite::dbConnect(RSQLite::SQLite(), "../data/hacker-news.sqlite")


# Work with Database

# - Load a table:
tbl(con, "dataset") %>% 
  head(20)

# - Make a plot:
tbl(con, "dataset") %>% 
  select(score) %>% 
  ggplot(aes(x = score)) +
  geom_histogram()


# Disconnect from Database
RSQLite::dbDisconnect(conn = con)