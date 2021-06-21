import sqlite3
import pandas as pd
from sklearn.linear_model import LinearRegression

conn = sqlite3.connect("hacker-news-dataset.sqlite")
cur = conn.cursor()

query = "select * from dataset limit 1000000"

df = pd.read_sql_query(sql=query, con=conn)
df.dropna(subset=['gain'], inplace=True)

df.score.fillna(0, inplace=True)
df.descendants.fillna(0, inplace=True)
df.topRank.fillna(301, inplace=True)
df.newRank.fillna(301, inplace=True)
df.bestRank.fillna(301, inplace=True)
df.askRank.fillna(301, inplace=True)
df.showRank.fillna(301, inplace=True)
df.jobRank.fillna(301, inplace=True)

train = df.head(900000)
test = df.tail(100000)

train_X = train.iloc[:, [7, 8]]
train_y = train.iloc[:, [13]]

test_X = test.iloc[:, [7, 8]]
test_y = test.iloc[:, [13]]

print(train_X.head())
print(train_y.head())
print(test_X.head())
print(test_y.head())

lm = LinearRegression()
lm.fit(train_X, train_y)
score = lm.score(test_X, test_y)


print(score)
conn.close()
