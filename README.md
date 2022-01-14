# Import Hacker News Dataset and Create Database

numbers in square brackets refer to resources


## Get Data

* get [osfclient](https://github.com/osfclient/osfclient) (command line tool for open science framework): `pipenv install`
* add OSF_TOKEN environment variable
* `pipenv run osf init` (you're going to be asked for your username and the project name)
* `./run.sh` should fetch the data from osf and create the database in the `./data/` directory


## Connect to Database with R

* see `R/r-db-connection.Rmd`


## Next Steps

* agent logic: voting = sorting task? ("How does the frontpage currently look like and how SHOULD the frontpage look like?" -> voting = submit "proposition" for better sorting) [3]
* find out number of votes by unique users + distributions [1, 2]

    * How many unique users? 
    * How many votes total (per unit time)?
    * 90-9-1 rule applies? Zipf's law?


## Problems

* missing values are ambiguous for some of the ranks (first period: missing -> not sampled; from second period on: missing -> not ranked)


## Resources

[1] https://news.ycombinator.com/item?id=9219581  
[2] https://www.kaggle.com/felixdietze/notebook9816d54b59  
[3] https://github.com/fdietze/downvote-scoring 


## Prerequisites

* osfclient
* sqlite3
* R:
    * DBI (for sqlite connection)
    * dplyr
    * ggplot2
