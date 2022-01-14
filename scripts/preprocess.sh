#!/usr/bin/env bash
echo "Preprocessing dataset..."
DATASET="data/newstories_2021-11-23_22-09-04.tsv"
head -1 "$DATASET" | sed s/_time/Time/g > data/hacker-news.tsv
tail -n +2 "$DATASET" >> data/hacker-news.tsv
cat data/hacker-news.tsv | sed 's/\t/,/g' > data/hacker-news.csv
rm data/hacker-news.tsv
rm "$DATASET"
