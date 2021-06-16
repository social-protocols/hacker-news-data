#!/usr/bin/env bash
set -Eeuo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/#:~:text=set%20%2Du,is%20often%20highly%20desirable%20behavior.

osf -p bnysw fetch -f /data/processed/hacker-news-processed.7z ./hacker-news-processed.7z
7z x ./hacker-news-processed.7z -aoa
rm hacker-news-processed.7z
