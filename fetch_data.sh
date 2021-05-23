#!/usr/bin/env bash

osf init 
osf fetch /data/processed/hacker-news-dataset.7z ./hacker-news-dataset.7z
7z x ./hacker-news-dataset.7z
rm hacker-news-dataset.7z

