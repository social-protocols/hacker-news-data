#!/usr/bin/env bash

osf init 
osf fetch /data/processed/hacker-news-processed.7z ./hacker-news-processed.7z
7z x ./hacker-news-processed.7z
rm hacker-news-processed.7z

