#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/#:~:text=set%20%2Du,is%20often%20highly%20desirable%20behavior.

SQLITEDB="hacker-news-dataset.sqlite"

main() {
	queries
}

queries() {
	echo "" | sqlite3 "$SQLITEDB" --init queries.sql
}

main "$@"
exit
