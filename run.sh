#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

./scripts/fetch_data.sh
./scripts/create_db.sh data/newstories_2021-11-23_22-09-04.tsv
