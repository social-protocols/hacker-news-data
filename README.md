# Import Hacker News Dataset and Create Database

* get osfclient (command line tool for open science framework)
* add OSF_TOKEN environment variable
* osf init (you're going to be asked for your username and the project name)
* osf fetch /data/processed/hacker-news-dataset.7z ./data/hacker-news-dataset.7z 
* 7z x ./data/hacker-news-dataset.7z
* ./create_db.sh
