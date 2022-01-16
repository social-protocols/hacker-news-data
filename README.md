# Get Hacker News Dataset

Note: You need an account at the [open science framework](https://osf.io/)

---

Install dependencies from `Pipfile`:

`pipenv install`

---

Create file `.osfcli.config` with the following content:

```
[osf]
username = <YOUR-USER-EMAIL>
project = bnjsw
```

---

ALTERNATIVELY:

Run `pipenv run osf init` and input your username (= email used for login at osf) and the project `bnjsw`.

---

Fetch the data and create the database with:

`./run.sh`

---

Now, there should be a database `hacker-new.sqlite` in the `data/` folder.

---

# Prereqesites

[osfclient](https://github.com/osfclient/osfclient)
[sqlite3](https://www.sqlite.org/index.html)
[pip](https://pypi.org/project/pip/)
[pipenv](https://pipenv.pypa.io/en/latest/)

---

# For Reference

[1] https://news.ycombinator.com/item?id=9219581  
[2] https://www.kaggle.com/felixdietze/notebook9816d54b59  
[3] https://github.com/fdietze/downvote-scoring 
