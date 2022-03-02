# Every Minute of Hacker News

Every minute for a couple of month, we collected a snapshot of the 1500 newest stories of Hacker News with [this scraper](https://github.com/social-protocols/hn-scraper).
A current version of the dataset can be accessed via the [open science framework (osf)](https://osf.io/bnysw/).

You can fetch the data and create the database with:

```
> ./run.sh
```

The database along with the raw data should be in the `/data/` folder.


## Prerequisites

* [osfclient](https://github.com/osfclient/osfclient)
* [sqlite3](https://www.sqlite.org/index.html)
* [pip](https://pypi.org/project/pip/)
* [pipenv](https://pipenv.pypa.io/en/latest/)
* [pv](https://linux.die.net/man/1/pv)


## For Reference

[1] [Hacker News Scraper](https://github.com/social-protocols/hn-scraper)  
[2] [Exploratory Data Analysis](https://www.kaggle.com/felixdietze/notebook9816d54b59)  
[3] [Improving the Hacker News Ranking Algorithm](https://felx.me/2021/08/29/improving-the-hacker-news-ranking-algorithm.html)  
[4] [Simulation to Test New Ranking Formulas](https://github.com/fdietze/downvote-scoring)  
