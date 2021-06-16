#!/usr/bin/env bash

osf fetch https://osf.io/bnysw/ ./hacker-news-processed.7z
7z x ./hacker-news-processed.7z
rm hacker-news-processed.7z
