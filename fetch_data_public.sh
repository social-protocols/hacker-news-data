#!/usr/bin/env bash

osf fetch https://osf.io/bnysw/ ./hacker-news-dataset.7z
7z x ./hacker-news-dataset.7z
rm hacker-news-dataset.7z
