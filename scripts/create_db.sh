#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

echo "Creating database..."

OUT="out"
DATASET="$1"
SQLITEDB="data/hacker-news.sqlite"

main() {
    rm -f "$SQLITEDB"
    import-dataset
    ls -lh "$SQLITEDB"
    echo "Now you can run ./queries.sh"
}

import-dataset() {
	pv "$DATASET" | sqlite3 "$SQLITEDB" --init import-dataset.sql
	echo "" | sqlite3 "$SQLITEDB" --init quality.sql
	echo "" | sqlite3 "$SQLITEDB" --init optimize.sql
	echo "" | sqlite3 "$SQLITEDB" --init queries.sql
}

main "$@"
exit
