#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

echo "Fetching data from osf..."

mkdir -p data
wget --no-verbose --show-progress https://osf.io/h9sjy/download -O data/hacker-news.7z
7z x data/hacker-news.7z -aoa -odata
rm data/hacker-news.7z
