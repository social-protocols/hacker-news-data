# Import Hacker News Dataset and Create Database

numbers in square brackets refer to resources


## Fetch Data from OSF

* get osfclient (command line tool for open science framework)
* add OSF_TOKEN environment variable
* osf init (you're going to be asked for your username and the project name)
* `./fetch_data.sh` (you're going to be asked for your username and the project name)
* `./create_db.sh`

(later on, osf repo will be public, by which point we can delete `fetch_data.sh` and replace it with `fetch_data_public.sh`)


## Connect to Database with R

* see `r-db-connection.Rmd`


## Next Steps

* agent logic: voting = sorting task? ("How does the frontpage currently look like and how SHOULD the frontpage look like?" -> voting = submit "proposition" for better sorting) [3]
* find out number of votes by unique users + distributions [1, 2]

    * How many unique users? 
    * How many votes total (per unit time)?
    * 90-9-1 rule applies? Zipf's law?  


## Resources

[1] https://news.ycombinator.com/item?id=9219581\
[2] https://www.kaggle.com/felixdietze/notebook9816d54b59\
[3] https://github.com/fdietze/downvote-scoring
