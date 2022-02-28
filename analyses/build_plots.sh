#!/usr/bin/env bash
Rscript rank-vote-distribution.R --no-save
Rscript story-rank-history.R --no-save
Rscript vote-arrivals-per-rank.R --no-save
Rscript weekly-hourly-vote-arrivals.R --no-save
