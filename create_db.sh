#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/#:~:text=set%20%2Du,is%20often%20highly%20desirable%20behavior.

OUT="out"
DATASET="hacker-news-dataset.csv"
SQLITEDB="hacker-news-dataset.sqlite"

main() {
	rm -f "$SQLITEDB"
	import-dataset
	ls -lh "$SQLITEDB"
}

import-dataset() {
	pv "$DATASET" | tail -n +2 | sqlite3 "$SQLITEDB" --init import-dataset.sql
	# pv "$OUT/title.ratings.tsv.gz" | gzip -d | sqlite3 "$SQLITEDB" --init import-imdb-ratings.sql
    # cat import-movielens-tags.sql | sqlite3 "$SQLITEDB" -init <(echo)
	# cat process-data.sql |
	# 	sed "s#:TMDB_DATA_DB_FILE#$TMDB_DATA_DB_FILE#" |
	# 	sed "s#:TMDB_ID_DB_FILE#$TMDB_ID_DB_FILE#" |
	# 	sed "s#:IMDB_KEYWORD_DB_FILE#$IMDB_KEYWORD_DB_FILE#" |
	# 	sed "s#:MIN_MOVIE_VOTES#$MIN_MOVIE_VOTES#" |
	# 	sed "s#:MIN_TVSHOW_VOTES#$MIN_TVSHOW_VOTES#" |
	# 	sqlite3 "$SQLITEDB" -init <(echo)
	echo "" | sqlite3 "$SQLITEDB" --init optimize.sql
}

main "$@"
exit
