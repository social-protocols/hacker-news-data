#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/#:~:text=set%20%2Du,is%20often%20highly%20desirable%20behavior.

OUT="out"
DATASET="hacker-news-dataset.csv"
SQLITEDB="hacker-news-dataset.sqlite"

main() {
	rm -f "$SQLITEDB"
	import-dataset
	ls -lh "$SQLITEDB"
    echo "now you can run ./queries.sh"
}

import-dataset() {
	pv "$DATASET" | tail -n +2 | sqlite3 "$SQLITEDB" --init import-dataset.sql
	echo "" | sqlite3 "$SQLITEDB" --init optimize.sql
}

main "$@"
exit
